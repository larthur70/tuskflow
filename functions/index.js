const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const messages = require('./notification_messages.json');

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

exports.tuskDailyReminder = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: "America/Sao_Paulo",
  },
  async (event) => {
    const db = admin.firestore();

    const now = admin.firestore.Timestamp.now();
    const nowJS = now.toDate();

    // 23h atrás (margem de segurança pro scheduler)
    const threshold = new Date(
      nowJS.getTime() - (23 * 60 * 60 * 1000)
    );

    const thresholdTS =
      admin.firestore.Timestamp.fromDate(threshold);

    console.log("GOOGLE_APPLICATION_CREDENTIALS:", process.env.GOOGLE_APPLICATION_CREDENTIALS);
    try {
      const userSnap = await db
        .collection("users")
        .where("lastTimerAt", "<=", thresholdTS)
        .get();

      for (const userDoc of userSnap.docs) {
        const userData = userDoc.data();

        const fcmToken = userData.fcmToken;

        if (!fcmToken) continue;

        // evita spam no mesmo dia
        const lastSent =
          userData.lastNotificationSentAt?.toDate();

        const HOURS_24 = 24 * 60 * 60 * 1000;

        if (
          lastSent &&
          nowJS.getTime() - lastSent.getTime() < HOURS_24
        ) {
          continue;
          }

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

        const randomMessage = getRandomMessage(task.title)

        const message = {
          token: fcmToken,

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
            taskId: taskDoc.id,
          }
        };

        try {
          await admin.messaging().send(message);

          // trava envio até amanhã
          await userDoc.ref.update({
            lastNotificationSentAt: now,
          });

          logger.log(
            `Notificação enviada para ${userDoc.id} sobre a tarefa: ${task.title}`
          );
        } catch (e) {
          logger.error(
            `Erro ao enviar push para ${userDoc.id}`,
            e
          );

          // limpa token inválido
          if (
            e.code ===
            "messaging/registration-token-not-registered"
          ) {
            await userDoc.ref.update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });

            logger.log(
              `Token removido para ${userDoc.id}`
            );
          }
        }
      }
    } catch (err) {
      logger.error("Erro geral na execução:", err);
    }
  }
);