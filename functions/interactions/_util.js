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

// Writes a public-broadcast notifications/{...} doc — no recipientId (sent
// as null), which sendPushNotification (functions/index.js) reads as "send
// to the upendo_all topic" rather than one user's stored FCM tokens. Use
// this — not notifyRecipient — when there's deliberately no single person
// to notify (e.g. activity on admin-curated /posts content, which has no
// author field): notifyRecipient's falsy-recipientId check exists to skip
// when there's truly nobody to notify, not to mean "notify everyone".
async function notifyBroadcast({ title, body, ...extra }) {
  await getFirestore().collection('notifications').add({
    recipientId: null,
    title,
    body,
    notify: true,
    createdAt: FieldValue.serverTimestamp(),
    ...extra,
  });
}

// Push previews are short — a long comment/message shouldn't produce an
// unwieldy notification body.
const PREVIEW_LENGTH = 80;

function truncate(text) {
  // String.prototype.slice cuts by UTF-16 code unit, which can split a
  // surrogate pair (e.g. an emoji) in half and produce a broken glyph in
  // the push body. Array.from iterates by Unicode code point instead, so
  // truncation always lands on a whole-character boundary.
  const codePoints = Array.from(text);
  return codePoints.length > PREVIEW_LENGTH
    ? `${codePoints.slice(0, PREVIEW_LENGTH - 1).join('')}…`
    : text;
}

module.exports = { transitionDelta, notifyRecipient, notifyBroadcast, truncate };
