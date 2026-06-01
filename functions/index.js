const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

async function getUserTokens(userId) {
  if (!userId) return [];

  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  if (!userDoc.exists) return [];

  const user = userDoc.data() || {};
  const tokens = [];

  if (typeof user.fcmToken === 'string' && user.fcmToken.length > 0) {
    tokens.push(user.fcmToken);
  }

  if (Array.isArray(user.fcmTokens)) {
    for (const token of user.fcmTokens) {
      if (typeof token === 'string' && token.length > 0) tokens.push(token);
    }
  }

  return [...new Set(tokens)];
}

async function sendToCaregiver(data, titleFallback, bodyFallback) {
  const caregiverId = data.caregiverId || data.recipientId;
  const tokens = await getUserTokens(caregiverId);

  if (tokens.length === 0) {
    console.log('No caregiver token found for:', caregiverId);
    return null;
  }

  const title = data.title || titleFallback || 'تنبيه MyCare';
  const body = data.message || bodyFallback || 'يوجد تنبيه جديد';

  const message = {
    tokens,
    notification: { title, body },
    data: {
      type: String(data.type || 'general'),
      patientId: String(data.patientId || data.userId || ''),
      caregiverId: String(caregiverId || ''),
      title: String(title),
      message: String(body),
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'mycare_urgent_channel',
        sound: 'default',
        priority: 'max',
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  console.log('FCM sent:', response.successCount, 'failed:', response.failureCount);
  return response;
}

exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    if (!data.caregiverId && !data.recipientId) return null;
    return sendToCaregiver(data, 'تنبيه MyCare', data.message);
  });

exports.sendSosOnCreate = functions.firestore
  .document('sosAlerts/{sosId}')
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    if (!data.caregiverId) return null;

    return sendToCaregiver(
      {
        ...data,
        type: 'sos',
        title: '🚨 تنبيه طوارئ SOS',
        message: data.message || 'المريض يحتاج مساعدة فورية',
      },
      '🚨 تنبيه طوارئ SOS',
      data.message || 'المريض يحتاج مساعدة فورية'
    );
  });