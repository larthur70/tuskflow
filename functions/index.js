const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const messages = require('./notification_messages.json');
const moment = require("moment-timezone");

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

function getRandomMessage(taskTitle) {
  const random = messages[Math.floor(Math.random() * messages.length)];

  return {
    title: random.title,
    body: random.body.replace("{task}", taskTitle)
  }
}

function buildPushPayload(randomMessage, taskDocId) {
  return {
    notification: {
      title: randomMessage.title,
      body: randomMessage.body,
    },

    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
        defaultVibrateTimings: true,
        defaultLightSettings: true,
        visibility: "public",
      }
    },

    apns: {
      headers: {
        "apns-priority": "10"
      },
      payload: {
        aps: {
          sound: "default",
          contentAvailable: false,
          alert: {
            title: randomMessage.title,
            body: randomMessage.body
          }
        }
      }
    },

    data: {
      taskId: taskDocId,
    }
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
  return error?.code === "messaging/registration-token-not-registered" ||
    error?.code === "messaging/invalid-registration-token";
}

exports.tuskDailyReminder = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: "America/Sao_Paulo",
  },
  async (event) => {
    const db = admin.firestore();

    
    const nowJS = moment().tz("America/Sao_Paulo");
    const currentHour = nowJS.hour();
    logger.log("NOW", nowJS.toString());
    logger.log("HOUR", currentHour.toString());

    // 23h atrás (margem de segurança pro scheduler)
    const threshold = new Date(
      nowJS.valueOf() - (24 * 60 * 60 * 1000)
    );

    const thresholdTS =
      admin.firestore.Timestamp.fromDate(threshold);

    const todayStart = nowJS.clone().startOf("day");

    const todayStartTS = admin.firestore.Timestamp.fromDate(todayStart.toDate());
    
    try {
      const userSnap = await db
        .collection("users")
        .where("lastTimerAt", "<=", thresholdTS)
        .where('habitHour','==',currentHour)
        .where("lastNotificationSentAt", "<",todayStartTS)
        .get();

      for (const userDoc of userSnap.docs) {
        const userData = userDoc.data();

        const tokenEntries = await getFcmTokenEntries(userDoc.ref, userData);

        if (tokenEntries.length === 0) continue;

        // pega tarefa pendente mais próxima
        const tasksSnap = await userDoc.ref
          .collection("tasks")
          .where("finished", "==", false)
          .orderBy("dueDate", "asc")
          .limit(1)
          .get();

        if (tasksSnap.empty) continue;

        const taskDoc = tasksSnap.docs[0];
        const task = taskDoc.data();

        const randomMessage = getRandomMessage(task.title);
        const basePayload = buildPushPayload(randomMessage, taskDoc.id);

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

          // trava envio até amanhã
          await userDoc.ref.update({
            lastNotificationSentAt: admin.firestore.Timestamp.now(),
          });

          logger.log(
            `Notificação enviada para ${userDoc.id} (${tokenEntries.length} dispositivo(s)) sobre a tarefa: ${task.title}`
          );
        } catch (e) {
          logger.error(
            `Erro ao enviar push para ${userDoc.id}`,
            e
          );
        }
      }
    } catch (err) {
      logger.error("Erro geral na execução:", err);
    }
  }
);
