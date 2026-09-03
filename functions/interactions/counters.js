const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

function transitionDelta(event) {
  const existedBefore = event.data.before.exists;
  const existsAfter = event.data.after.exists;
  if (!existedBefore && existsAfter) return 1;
  if (existedBefore && !existsAfter) return -1;
  return 0;
}

const updateCommentCount = onDocumentWritten('posts/{postId}/comments/{commentId}', async (event) => {
  const delta = transitionDelta(event);
  if (delta === 0) return;
  await getFirestore().collection('posts').doc(event.params.postId)
      .update({ commentCount: FieldValue.increment(delta) });
});

const updateLikeCount = onDocumentWritten('posts/{postId}/likes/{uid}', async (event) => {
  const delta = transitionDelta(event);
  if (delta === 0) return;
  await getFirestore().collection('posts').doc(event.params.postId)
      .update({ likeCount: FieldValue.increment(delta) });
});

const updateThreadReplyCount = onDocumentWritten('threadPosts/{postId}/replies/{replyId}', async (event) => {
  const delta = transitionDelta(event);
  if (delta === 0) return;
  await getFirestore().collection('threadPosts').doc(event.params.postId)
      .update({ commentCount: FieldValue.increment(delta) });
});

const updateThreadLikeCount = onDocumentWritten('threadPosts/{postId}/likes/{uid}', async (event) => {
  const delta = transitionDelta(event);
  if (delta === 0) return;
  await getFirestore().collection('threadPosts').doc(event.params.postId)
      .update({ likeCount: FieldValue.increment(delta) });
});

module.exports = {
  updateCommentCount,
  updateLikeCount,
  updateThreadReplyCount,
  updateThreadLikeCount,
};
