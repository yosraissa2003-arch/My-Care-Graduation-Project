const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.sendSOSNotification = onDocumentCreated(
    "sosAlerts/{alertId}",
    async (event) => {
      const data = event.data.data();

      const caregiverId = data.caregiverId;

      if (!caregiverId) {
        return null;
      }

      const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(caregiverId)
          .get();

      const userData = userDoc.data();

      if (!userData || !userData.fcmToken) {
        return null;
      }

      const message = {
        token: userData.fcmToken,
        notification: {
          title: "🚨 حالة طوارئ",
          body: data.message || "يوجد حالة خطيرة تحتاج مساعدة",
        },
      };

      return admin.messaging().send(message);
    },
);
