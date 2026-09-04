const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Shared by the interaction triggers in this directory (counters.js,
// activityNotifications.js, messageNotifications.js) — detects
// create-vs-delete on an onDocumentWritten event so each trigger only
// reacts to the transition it cares about.
function transitionDelta(event) {
  const existedBefore = event.data.before.exists;
  const existsAfter = event.data.after.exists;
  if (!existedBefore && existsAfter) return 1;
  if (existedBefore && !existsAfter) return -1;
  return 0;
}

// Writes a targeted notifications/{...} doc for `recipientId`. Skips when
// there's no recipient to notify, or when the actor would be notifying
// themselves (e.g. liking/commenting on their own post, or the sender/
// recipient somehow matching on a conversation message). sendPushNotification
// (functions/index.js) picks this doc up and delivers the push to the
// recipient's stored FCM tokens — this function only records the activity.
// `extra` carries trigger-specific context (e.g. `type` + `postId`, or
// `type` + `conversationId`).
async function notifyRecipient({ recipientId, actorId, title, body, ...extra }) {
  if (!recipientId || recipientId === actorId) return;
  await getFirestore().collection('notifications').add({
    recipientId,
    title,
    body,
    notify: true,
    createdAt: FieldValue.serverTimestamp(),
    ...extra,
  });
}

module.exports = { transitionDelta, notifyRecipient };
