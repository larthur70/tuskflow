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

function getMessageForTask(taskTitle, tier) {
  const template = messages[tier];
  return {
    title: template.title,
    body: template.body.replace("{task}", taskTitle),
  };
}

/**
 * Picks the most urgent task at a notification milestone (0 > 1 > 3 > 5 days).
 * @returns {{ doc: FirebaseFirestore.QueryDocumentSnapshot, tier: string } | null}
 */
function pickTaskForNotification(taskDocs, todayStart) {
  let best = null;

  for (const doc of taskDocs) {
    const task = doc.data();
    const dueDate = task.dueDate;
    if (!dueDate) continue;

    const daysUntil = daysUntilDue(dueDate, todayStart);
    if (!MILESTONE_DAYS.includes(daysUntil)) continue;

    const tier = tierForDaysUntil(daysUntil);
    if (!tier) continue;

    if (
      !best ||
      URGENCY_ORDER[tier] < URGENCY_ORDER[best.tier] ||
      (URGENCY_ORDER[tier] === URGENCY_ORDER[best.tier] &&
        dueDate.toMillis() < best.doc.data().dueDate.toMillis())
    ) {
      best = { doc, tier };
    }
  }

  return best;
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

  const tokenSnap = await userDocRef.collection("fcmTokens").get();
  for (const doc of tokenSnap.docs) {
    const token = doc.data().token;
    if (!token || seen.has(token)) continue;
    seen.add(token);
    entries.push({ token, docRef: doc.ref, legacy: false });
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

        const picked = pickTaskForNotification(tasksSnap.docs, todayStart);
        if (!picked) continue;

        const taskDoc = picked.doc;
        const task = taskDoc.data();
        const pushMessage = getMessageForTask(task.title, picked.tier);
        const basePayload = buildPushPayload(pushMessage, taskDoc.id);

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

            if (sendResponse.success) {
              anySuccess = true;
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

          logger.log(
            `Notificação [${picked.tier}] enviada para ${userDoc.id} (${tokenEntries.length} dispositivo(s)) sobre a tarefa: ${task.title}`
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
