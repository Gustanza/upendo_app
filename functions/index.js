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
const {
  notifyPostComment,
  notifyPostLike,
  notifyThreadReply,
  notifyThreadLike,
}                                         = require('./interactions/activityNotifications');
const { notifyConversationMessage }      = require('./interactions/messageNotifications');

exports.subscribe                      = subscribe;
exports.resolvePayment                 = resolvePayment;
exports.deactivateExpiredSubscriptions = deactivateExpiredSubscriptions;
exports.searchPosts                    = searchPosts;
exports.updateCommentCount             = updateCommentCount;
exports.updateLikeCount                = updateLikeCount;
exports.updateThreadReplyCount         = updateThreadReplyCount;
exports.updateThreadLikeCount          = updateThreadLikeCount;
exports.cleanupThreadPost              = cleanupThreadPost;
exports.notifyPostComment              = notifyPostComment;
exports.notifyPostLike                 = notifyPostLike;
exports.notifyThreadReply              = notifyThreadReply;
exports.notifyThreadLike               = notifyThreadLike;
exports.notifyConversationMessage      = notifyConversationMessage;

exports.registerFcmToken = onCall(async (request) => {
  const token = request.data.token;
  if (!token || typeof token !== 'string') {
    throw new HttpsError('invalid-argument', 'token is required');
  }
  // Topic subscription (for broadcasts) and storing the token against the
  // signed-in user (for targeted pushes — e.g. "someone commented on your
  // post") are independent concerns. Each is best-effort on its own: a
  // failure in one must not prevent the other from being attempted, so a
  // transient hiccup in one doesn't silently break the other for this user
  // until their token happens to refresh again. The client doesn't
  // differentiate/retry on error today, so neither failure is worth a hard
  // throw — log and still report success.
  try {
    await getMessaging().subscribeToTopic([token], 'upendo_all');
  } catch (err) {
    console.error('registerFcmToken: subscribe failed', err);
  }

  // If the caller isn't signed in yet (can happen at cold start, before
  // login), there's just no uid to key the token storage on.
  const uid = request.auth?.uid;
  if (uid) {
    try {
      await getFirestore().collection('users').doc(uid).set(
        { fcmTokens: FieldValue.arrayUnion(token) },
        { merge: true },
      );
    } catch (err) {
      console.error('registerFcmToken: token storage failed', err);
    }
  }

  return { success: true };
});

exports.sendPushNotification = onDocumentWritten('notifications/{notifId}', async (event) => {
  const after = event.data.after;

  if (!after || !after.exists) return;

  const data = after.data();

  if (data.notify !== true) return;
  if (data.sentAt != null) return;

  const { title, body, recipientId } = data;

  if (!title || !body) {
    console.warn(`sendPushNotification: missing title or body on notifications/${event.params.notifId} — skipping`);
    return;
  }

  const notifRef = getFirestore().collection('notifications').doc(event.params.notifId);

  // A recipientId means this is a targeted per-user notification (e.g. a
  // comment/like on the recipient's post) — deliver it only to that user's
  // devices. No recipientId means the existing global broadcast behavior
  // (used by the admin dashboard's "Publish & Notify"), unchanged below.
  if (recipientId) {
    const userSnap = await getFirestore().collection('users').doc(recipientId).get();
    const tokens = userSnap.exists && Array.isArray(userSnap.data().fcmTokens)
      ? userSnap.data().fcmTokens
      : [];

    if (tokens.length === 0) {
      // Nothing to send to — not an error, just mark it handled.
      await notifRef.update({ sentAt: FieldValue.serverTimestamp() });
      return;
    }

    let response;
    try {
      response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (err) {
      console.error('sendPushNotification: multicast send failed', err);
      return;
    }

    const staleTokens = [];
    response.responses.forEach((res, i) => {
      if (res.success) return;
      const code = res.error?.code;
      if (code === 'messaging/invalid-registration-token'
          || code === 'messaging/registration-token-not-registered') {
        staleTokens.push(tokens[i]);
      } else {
        console.error(`sendPushNotification: send failed for a token of ${recipientId}`, res.error);
      }
    });

    if (staleTokens.length > 0) {
      await getFirestore().collection('users').doc(recipientId)
        .update({ fcmTokens: FieldValue.arrayRemove(...staleTokens) })
        .catch((err) => console.error('sendPushNotification: failed to prune stale tokens', err));
    }

    await notifRef.update({ sentAt: FieldValue.serverTimestamp() });
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

  await notifRef.update({ sentAt: FieldValue.serverTimestamp() });
});
