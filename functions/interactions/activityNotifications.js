const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { transitionDelta } = require('./_util');

// Writes a targeted notifications/{...} doc for `recipientId`. Skips when
// there's no recipient to notify, or when the actor would be notifying
// themselves (e.g. liking/commenting on their own post). sendPushNotification
// (functions/index.js) picks this doc up and delivers the push to the
// recipient's stored FCM tokens — this function only records the activity.
async function notifyRecipient({ recipientId, actorId, title, body, type, postId }) {
  if (!recipientId || recipientId === actorId) return;
  await getFirestore().collection('notifications').add({
    recipientId,
    title,
    body,
    notify: true,
    type,
    postId,
    createdAt: FieldValue.serverTimestamp(),
  });
}

const notifyPostComment = onDocumentWritten('posts/{postId}/comments/{commentId}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const actorId = event.data.after.data().userId;

  const postSnap = await getFirestore().collection('posts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  // Admin-curated /posts docs have no author field today (they're not
  // authored by an app user) — nothing to notify until/unless that changes.
  const authorId = postSnap.data().authorId;
  if (!authorId) return;

  await notifyRecipient({
    recipientId: authorId,
    actorId,
    title: 'Maoni mapya',
    body: 'Mtu ameweka maoni kwenye chapisho lako',
    type: 'comment',
    postId: event.params.postId,
  });
});

const notifyPostLike = onDocumentWritten('posts/{postId}/likes/{uid}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const actorId = event.params.uid;

  const postSnap = await getFirestore().collection('posts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  const authorId = postSnap.data().authorId;
  if (!authorId) return;

  await notifyRecipient({
    recipientId: authorId,
    actorId,
    title: 'Kupenda chapisho',
    body: 'Mtu amependa chapisho lako',
    type: 'like',
    postId: event.params.postId,
  });
});

const notifyThreadReply = onDocumentWritten('threadPosts/{postId}/replies/{replyId}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const actorId = event.data.after.data().authorId;

  const postSnap = await getFirestore().collection('threadPosts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  const authorId = postSnap.data().authorId;
  if (!authorId) return;

  await notifyRecipient({
    recipientId: authorId,
    actorId,
    title: 'Jibu jipya',
    body: 'Mtu amejibu chapisho lako kwenye Ukuta wa Jumuiya',
    type: 'reply',
    postId: event.params.postId,
  });
});

const notifyThreadLike = onDocumentWritten('threadPosts/{postId}/likes/{uid}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const actorId = event.params.uid;

  const postSnap = await getFirestore().collection('threadPosts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  const authorId = postSnap.data().authorId;
  if (!authorId) return;

  await notifyRecipient({
    recipientId: authorId,
    actorId,
    title: 'Kupenda chapisho',
    body: 'Mtu amependa chapisho lako kwenye Ukuta wa Jumuiya',
    type: 'threadLike',
    postId: event.params.postId,
  });
});

module.exports = {
  notifyPostComment,
  notifyPostLike,
  notifyThreadReply,
  notifyThreadLike,
};
