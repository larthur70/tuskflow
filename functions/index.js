const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const messages = require("./notification_messages.json");
const moment = require("moment-timezone");

const TIMEZONE = "America/Sao_Paulo";
const MILESTONE_DAYS = [0, 1, 3, 5];
const URGENCY_ORDER = { desespero: 0, panico: 1, preocupado: 2, calmo: 3 };

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
