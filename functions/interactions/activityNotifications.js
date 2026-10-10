const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');
const { transitionDelta, notifyBroadcast, truncate } = require('./_util');

// /posts is admin-curated content (video/article, e.g. the "AKWI" example)
// with no author field — there's no single person to notify about activity
// on it, so comments/likes here are broadcast to everyone. The
// /threadPosts (community wall) triggers below broadcast too, as a
// deliberate product decision for engagement — see the comment above
// notifyThreadPostCreated.
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

// Deliberate product decision: broadcast ALL activity on the community wall
// to everyone (new posts, replies, likes) — an aggressive engagement push,
// not a targeted "the author gets notified" flow like /posts used to be
// implemented as. No throttling/opt-out by design.
const notifyThreadPostCreated = onDocumentWritten('threadPosts/{postId}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const post = event.data.after.data();
  const authorName = post.authorName || 'Mtumiaji';
  const text = post.text || '';

  await notifyBroadcast({
    title: 'Chapisho jipya kwenye Ukuta wa Jumuiya',
    body: `${authorName}: ${truncate(text)}`,
    type: 'threadPost',
    postId: event.params.postId,
    actorId: post.authorId,
  });
});

const notifyThreadReply = onDocumentWritten('threadPosts/{postId}/replies/{replyId}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const reply = event.data.after.data();
  const replierName = reply.authorName || 'Mtumiaji';
  const text = reply.text || '';

  // Unlike the old targeted version, this doesn't need to fetch the parent
  // post at all — the reply doc already has everything the broadcast body
  // needs (authorName/text), and there's no single "recipient" left to look
  // up an authorId for.
  await notifyBroadcast({
    title: 'Jibu jipya kwenye Ukuta wa Jumuiya',
    body: `${replierName}: ${truncate(text)}`,
    type: 'reply',
    postId: event.params.postId,
    actorId: reply.authorId,
  });
});

const notifyThreadLike = onDocumentWritten('threadPosts/{postId}/likes/{uid}', async (event) => {
  if (transitionDelta(event) !== 1) return;
  const likerUid = event.params.uid;

  // threadPosts have no title field (unlike /posts) to identify which post
  // was liked, so fetch its text for a short preview instead.
  const postSnap = await getFirestore().collection('threadPosts').doc(event.params.postId).get();
  if (!postSnap.exists) return;
  const postText = postSnap.data().text || '';

  // The like doc itself has no name field (just createdAt) — same
  // liker-name lookup pattern as notifyPostLike above.
  const userSnap = await getFirestore().collection('users').doc(likerUid).get();
  const likerName = userSnap.data()?.fullName || 'Mtumiaji';

  await notifyBroadcast({
    title: 'Kupenda kipya kwenye Ukuta wa Jumuiya',
    body: `${likerName} amependa: "${truncate(postText)}"`,
    type: 'threadLike',
    postId: event.params.postId,
    actorId: likerUid,
  });
});

module.exports = {
  notifyPostComment,
  notifyPostLike,
  notifyThreadPostCreated,
  notifyThreadReply,
  notifyThreadLike,
};
