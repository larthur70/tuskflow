const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentWritten, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const messages = require("./notification_messages.json");
const moment = require("moment-timezone");

const TIMEZONE = "America/Sao_Paulo";
const DEFAULT_HABIT_HOUR = 20;
const MILESTONE_DAYS = [0, 1, 3, 5];
const URGENCY_ORDER = { desespero: 0, panico: 1, preocupado: 2, calmo: 3 };
const BACKFILL_PAGE_SIZE = 500;

const HABIT_HOUR_BACKFILL_SECRET = defineSecret("HABIT_HOUR_BACKFILL_SECRET");

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

function daysUntilDue(dueDateTs, todayStart) {
  const dueDay = moment(dueDateTs.toDate()).tz(TIMEZONE).startOf("day");
  return dueDay.diff(todayStart, "days");
}

function tierForDaysUntil(daysUntil) {
  switch (daysUntil) {
    case 5:
      return "calmo";
    case 3:
      return "preocupado";
    case 1:
      return "panico";
    case 0:
      return "desespero";
    default:
      return null;
  }
}

/**
 * Formats 2–3 task titles for aggregated notifications.
 * 2 tasks: "A e B"
 * 3 tasks: "A, B e C"
 */
function formatTaskList(titles) {
  if (titles.length <= 1) {
    return titles[0] ?? "";
  }
  if (titles.length === 2) {
    return `${titles[0]} e ${titles[1]}`;
  }
  return `${titles.slice(0, -1).join(", ")} e ${titles[titles.length - 1]}`;
}

function getMessageForTasks(taskEntries, tier) {
  const tierMessages = messages[tier];
  const count = taskEntries.length;

  if (count === 1) {
    const template = tierMessages.single;
    return {
      title: template.title,
      body: template.body.replace("{task}", taskEntries[0].title),
    };
  }

  if (count <= 3) {
    const taskList = formatTaskList(taskEntries.map((entry) => entry.title));
    const template = tierMessages["2_3_tasks"];
    return {
      title: template.title,
      body: template.body.replace("{taskList}", taskList),
    };
  }

  const template = tierMessages["4_plus_tasks"];
  return {
    title: template.title,
    body: template.body.replace("{count}", String(count)),
  };
}

/**
 * Collects every task at a notification milestone today and picks the most
 * urgent tier (0 > 1 > 3 > 5 days). All qualifying tasks are included in the
 * aggregated message; tone follows the closest deadline.
 * @returns {{ tier: string, tasks: Array<{ doc: FirebaseFirestore.QueryDocumentSnapshot, title: string }>, primaryTaskDoc: FirebaseFirestore.QueryDocumentSnapshot } | null}
 */
function collectTasksForNotification(taskDocs, todayStart) {
  const qualifying = [];

  for (const doc of taskDocs) {
    const task = doc.data();
    const dueDate = task.dueDate;
    if (!dueDate) continue;

    const daysUntil = daysUntilDue(dueDate, todayStart);
    if (!MILESTONE_DAYS.includes(daysUntil)) continue;

    const tier = tierForDaysUntil(daysUntil);
    if (!tier) continue;

    qualifying.push({ doc, tier, title: task.title, dueDate });
  }

  if (qualifying.length === 0) return null;

  qualifying.sort((a, b) => {
    const urgencyDiff = URGENCY_ORDER[a.tier] - URGENCY_ORDER[b.tier];
    if (urgencyDiff !== 0) return urgencyDiff;
    return a.dueDate.toMillis() - b.dueDate.toMillis();
  });

  return {
    tier: qualifying[0].tier,
    tasks: qualifying,
    primaryTaskDoc: qualifying[0].doc,
  };
}

function buildPushPayload(message, taskDocId) {
  return {
    notification: {
      title: message.title,
      body: message.body,
    },

    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
        defaultVibrateTimings: true,
        defaultLightSettings: true,
        visibility: "public",
      },
    },

    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
          contentAvailable: false,
          alert: {
            title: message.title,
            body: message.body,
          },
        },
      },
    },

    data: {
      taskId: taskDocId,
    },
  };
}

/**
 * Collects FCM tokens from users/{uid}/fcmTokens and falls back to legacy fcmToken field.
 * @returns {Promise<Array<{token: string, docRef: FirebaseFirestore.DocumentReference|null, legacy: boolean}>>}
 */
async function getFcmTokenEntries(userDocRef, userData) {
  const entries = [];
  const seen = new Set();
  const duplicateRefsToDelete = [];

  const tokenSnap = await userDocRef.collection("fcmTokens").get();
  for (const doc of tokenSnap.docs) {
    const token = doc.data().token;
    if (!token) continue;

    if (seen.has(token)) {
      duplicateRefsToDelete.push(doc.ref);
      continue;
    }

    seen.add(token);
    entries.push({ token, docRef: doc.ref, legacy: doc.id === "_legacy" });
  }

  if (duplicateRefsToDelete.length > 0) {
    await Promise.all(duplicateRefsToDelete.map((ref) => ref.delete()));
    logger.log(
      `Removidos ${duplicateRefsToDelete.length} doc(s) duplicado(s) de FCM para ${userDocRef.id}`
    );
  }

  const legacyToken = userData.fcmToken;
  if (legacyToken && !seen.has(legacyToken)) {
    entries.push({ token: legacyToken, docRef: null, legacy: true });
  }

  return entries;
}

function isInvalidFcmTokenError(error) {
  return (
    error?.code === "messaging/registration-token-not-registered" ||
    error?.code === "messaging/invalid-registration-token"
  );
}

function hasHabitHour(data) {
  return (
    data != null &&
    typeof data.habitHour === "number" &&
    data.habitHour >= 0 &&
    data.habitHour <= 23
  );
}

/** Default notification hour for users who skipped onboarding or never started the timer. */
function resolveDefaultHabitHour(userData) {
  const createdAt = userData?.createdAt;
  if (createdAt && typeof createdAt.toDate === "function") {
    const hour = moment(createdAt.toDate()).tz(TIMEZONE).hour();
    if (hour >= 0 && hour <= 23) {
      return hour;
    }
  }
  return DEFAULT_HABIT_HOUR;
}

async function backfillMissingHabitHour(db) {
  let lastDoc = null;
  let scanned = 0;
  let updated = 0;

  while (true) {
    let query = db
      .collection("users")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BACKFILL_PAGE_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snap = await query.get();
    if (snap.empty) break;

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snap.docs) {
      scanned++;
      if (hasHabitHour(doc.data())) continue;

      batch.update(doc.ref, {
        habitHour: resolveDefaultHabitHour(doc.data()),
      });
      batchCount++;
      updated++;
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    lastDoc = snap.docs[snap.docs.length - 1];
  }

  return { scanned, updated };
}

function isBackfillAuthorized(req) {
  const configuredSecret = HABIT_HOUR_BACKFILL_SECRET.value();
  if (!configuredSecret) {
    logger.warn("backfillHabitHour: HABIT_HOUR_BACKFILL_SECRET is not configured");
    return false;
  }

  const providedSecret =
    req.get("x-backfill-secret") ||
    req.query.secret ||
    req.body?.secret;

  return providedSecret === configuredSecret;
}

/**
 * Ensures habitHour exists when the app creates a minimal user profile
 * (onboarding skip, social login recovery, etc.).
 */
exports.ensureHabitHourOnUserWrite = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap?.exists) return;

    const data = afterSnap.data();
    if (hasHabitHour(data)) return;

    const habitHour = resolveDefaultHabitHour(data);
    await afterSnap.ref.update({ habitHour });
    logger.log(`habitHour=${habitHour} set for user ${event.params.userId}`);
  }
);

/**
 * Safety net: users who already have tasks but still lack habitHour become
 * eligible for the hourly reminder query.
 */
exports.ensureHabitHourOnTaskCreate = onDocumentCreated(
  "users/{userId}/tasks/{taskId}",
  async (event) => {
    const userRef = admin.firestore().doc(`users/${event.params.userId}`);
    const userSnap = await userRef.get();
    if (!userSnap.exists) return;

    const data = userSnap.data();
    if (hasHabitHour(data)) return;

    const habitHour = resolveDefaultHabitHour(data);
    await userRef.update({ habitHour });
    logger.log(
      `habitHour=${habitHour} set for user ${event.params.userId} on task create`
    );
  }
);

/**
 * One-time (or repeatable) backfill for existing users missing habitHour.
 * Deploy, then call once with the configured secret:
 *   curl -X POST "https://<region>-<project>.cloudfunctions.net/backfillHabitHour" \
 *     -H "X-Backfill-Secret: <secret>"
 *
 * Set secret before deploy:
 *   firebase functions:secrets:set HABIT_HOUR_BACKFILL_SECRET
 */
exports.backfillHabitHour = onRequest(
  {
    secrets: [HABIT_HOUR_BACKFILL_SECRET],
    invoker: "public",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    if (!isBackfillAuthorized(req)) {
      res.status(403).send("Forbidden");
      return;
    }

    try {
      const result = await backfillMissingHabitHour(admin.firestore());
      logger.log(
        `backfillHabitHour complete: scanned=${result.scanned}, updated=${result.updated}`
      );
      res.status(200).json({
        ok: true,
        scanned: result.scanned,
        updated: result.updated,
      });
    } catch (err) {
      logger.error("backfillHabitHour failed", err);
      res.status(500).json({ ok: false, error: String(err) });
    }
  }
);

exports.tuskDailyReminder = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: TIMEZONE,
  },
  async (event) => {
    const db = admin.firestore();

    const nowJS = moment().tz(TIMEZONE);
    const currentHour = nowJS.hour();
    logger.log("NOW", nowJS.toString());
    logger.log("HOUR", currentHour.toString());

    const todayStart = nowJS.clone().startOf("day");
    const todayStartTS = admin.firestore.Timestamp.fromDate(todayStart.toDate());

    const windowEnd = todayStart.clone().add(5, "days").endOf("day");
    const windowEndTS = admin.firestore.Timestamp.fromDate(windowEnd.toDate());

    try {
      const userSnap = await db
        .collection("users")
        .where("habitHour", "==", currentHour)
        .where("lastNotificationSentAt", "<", todayStartTS)
        .get();

      for (const userDoc of userSnap.docs) {
        const userData = userDoc.data();

        const tokenEntries = await getFcmTokenEntries(userDoc.ref, userData);
        if (tokenEntries.length === 0) continue;

        const tasksSnap = await userDoc.ref
          .collection("tasks")
          .where("finished", "==", false)
          .where("dueDate", ">=", todayStartTS)
          .where("dueDate", "<=", windowEndTS)
          .orderBy("dueDate", "asc")
          .get();

        if (tasksSnap.empty) continue;

        const picked = collectTasksForNotification(tasksSnap.docs, todayStart);
        if (!picked) continue;

        const pushMessage = getMessageForTasks(picked.tasks, picked.tier);
        const basePayload = buildPushPayload(
          pushMessage,
          picked.primaryTaskDoc.id
        );

        const messagesToSend = tokenEntries.map((entry) => ({
          ...basePayload,
          token: entry.token,
        }));

        try {
          const response = await admin.messaging().sendEach(messagesToSend);

          let anySuccess = false;

          for (let i = 0; i < response.responses.length; i++) {
            const sendResponse = response.responses[i];
            const entry = tokenEntries[i];
            const tokenSuffix = entry.token.slice(-8);

            if (sendResponse.success) {
              anySuccess = true;
              logger.log(
                `Push aceito pelo FCM para ${userDoc.id} (token ...${tokenSuffix}, messageId: ${sendResponse.messageId ?? "n/a"})`
              );
              continue;
            }

            const err = sendResponse.error;
            logger.error(
              `Erro ao enviar push para ${userDoc.id} (token index ${i})`,
              err
            );

            if (!isInvalidFcmTokenError(err)) continue;

            if (entry.docRef) {
              await entry.docRef.delete();
              logger.log(
                `Token removido da subcoleção para ${userDoc.id} (${entry.docRef.id})`
              );
            } else if (entry.legacy) {
              await userDoc.ref.update({
                fcmToken: admin.firestore.FieldValue.delete(),
              });
              logger.log(`Token legado removido para ${userDoc.id}`);
            }
          }

          if (!anySuccess) continue;

          await userDoc.ref.update({
            lastNotificationSentAt: admin.firestore.Timestamp.now(),
          });

          const taskSummary =
            picked.tasks.length === 1
              ? picked.tasks[0].title
              : `${picked.tasks.length} tarefas (${picked.tasks.map((t) => t.title).join(", ")})`;
          logger.log(
            `Notificação [${picked.tier}] enviada para ${userDoc.id} (${tokenEntries.length} dispositivo(s)) sobre: ${taskSummary}`
          );
        } catch (e) {
          logger.error(`Erro ao enviar push para ${userDoc.id}`, e);
        }
      }
    } catch (err) {
      logger.error("Erro geral na execução:", err);
    }
  }
);
