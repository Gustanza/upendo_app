const { initializeApp }          = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging }             = require('firebase-admin/messaging');
const { setGlobalOptions }         = require('firebase-functions');
const { onDocumentWritten }        = require('firebase-functions/v2/firestore');
const { onCall, HttpsError }       = require('firebase-functions/v2/https');

initializeApp();
setGlobalOptions({ maxInstances: 10 });

const { subscribe }                      = require('./payments/index');
const { resolvePayment }                 = require('./payments/ipnresolver');
const { deactivateExpiredSubscriptions } = require('./subscriptions/deactivate');
const { searchPosts }                    = require('./search/searchPosts');
const {
  updateCommentCount,
  updateLikeCount,
  updateThreadReplyCount,
  updateThreadLikeCount,
}                                         = require('./interactions/counters');
const { cleanupThreadPost }              = require('./interactions/cleanupThreadPost');

exports.subscribe                      = subscribe;
exports.resolvePayment                 = resolvePayment;
exports.deactivateExpiredSubscriptions = deactivateExpiredSubscriptions;
exports.searchPosts                    = searchPosts;
exports.updateCommentCount             = updateCommentCount;
exports.updateLikeCount                = updateLikeCount;
exports.updateThreadReplyCount         = updateThreadReplyCount;
exports.updateThreadLikeCount          = updateThreadLikeCount;
exports.cleanupThreadPost              = cleanupThreadPost;

exports.registerFcmToken = onCall(async (request) => {
  const token = request.data.token;
  if (!token || typeof token !== 'string') {
    throw new HttpsError('invalid-argument', 'token is required');
  }
  try {
    await getMessaging().subscribeToTopic([token], 'upendo_all');
  } catch (err) {
    console.error('registerFcmToken: subscribe failed', err);
    throw new HttpsError('internal', 'topic subscription failed');
  }
  return { success: true };
});

exports.sendPushNotification = onDocumentWritten('notifications/{notifId}', async (event) => {
  const after = event.data.after;

  if (!after || !after.exists) return;

  const data = after.data();

  if (data.notify !== true) return;
  if (data.sentAt != null) return;

  const { title, body } = data;

  if (!title || !body) {
    console.warn(`sendPushNotification: missing title or body on notifications/${event.params.notifId} — skipping`);
    return;
  }

  try {
    await getMessaging().send({
      topic: 'upendo_all',
      notification: { title, body },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.error('sendPushNotification: FCM send failed', err);
    return;
  }

  await getFirestore()
    .collection('notifications')
    .doc(event.params.notifId)
    .update({ sentAt: FieldValue.serverTimestamp() });
});
