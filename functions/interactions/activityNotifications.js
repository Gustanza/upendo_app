const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');
const { transitionDelta, notifyRecipient, notifyBroadcast, truncate } = require('./_util');

// /posts is admin-curated content (video/article, e.g. the "AKWI" example)
// with no author field — there's no single person to notify about activity
// on it, so comments/likes here are broadcast to everyone instead, unlike
// notifyThreadReply/notifyThreadLike below which target the real post
// author on the user-generated /threadPosts collection.
const notifyPostComment = onDocumentWritten('posts/{postId}/comments/{commentId}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const comment = event.data.after.data();
  const commenterName = comment.userName || 'Mtumiaji';
  const text = comment.text || '';

  const postSnap = await getFirestore().collection('posts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  const postTitle = postSnap.data().title || 'Chapisho';

  // A topic-based broadcast can't exclude the commenter's own device from
  // the push itself (that would need per-user multicast instead of topics —
  // not worth it here), but recording actorId lets the in-app notifications
  // list (notification_service.dart) filter out "your own action" so at
  // least the list doesn't show it back to you.
  await notifyBroadcast({
    title: `Maoni mapya kwenye "${postTitle}"`,
    body: `${commenterName}: ${truncate(text)}`,
    type: 'comment',
    postId: event.params.postId,
    actorId: comment.userId,
  });
});

const notifyPostLike = onDocumentWritten('posts/{postId}/likes/{uid}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const likerUid = event.params.uid;

  const postSnap = await getFirestore().collection('posts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  const postTitle = postSnap.data().title || 'Chapisho';

  // The like doc itself has no name field (just createdAt) — one extra
  // read for the liker's display name, same pattern used elsewhere in this
  // codebase for turning a uid into a fullName (e.g. addComment/addReply
  // client-side, or registerFcmToken's users/{uid} lookup server-side).
  const userSnap = await getFirestore().collection('users').doc(likerUid).get();
  const likerName = userSnap.data()?.fullName || 'Mtumiaji';

  // See notifyPostComment above re: actorId and why it's recorded even
  // though a broadcast push can't itself exclude the liker.
  await notifyBroadcast({
    title: `Kupenda kipya kwenye "${postTitle}"`,
    body: `${likerName} amependa "${postTitle}"`,
    type: 'like',
    postId: event.params.postId,
    actorId: likerUid,
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
