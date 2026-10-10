const { onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

// Firestore doesn't cascade-delete subcollections on its own. A single batch
// is enough for a community feed's reply/like counts — chunk into multiple
// batches if a thread ever realistically approaches 500 replies or likes.
async function deleteSubcollection(ref) {
  const snap = await ref.get();
  if (snap.empty) return;
  const batch = getFirestore().batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

const cleanupThreadPost = onDocumentDeleted('threadPosts/{postId}', async (event) => {
  const postRef = getFirestore().collection('threadPosts').doc(event.params.postId);

  await Promise.all([
    deleteSubcollection(postRef.collection('replies')),
    deleteSubcollection(postRef.collection('likes')),
  ]);

  // Every upload for a post (legacy single image.jpg, or the attachments
  // list) lives under threadPosts/{postId}/, so delete the whole folder.
  const prefix = `threadPosts/${event.params.postId}/`;
  await getStorage().bucket().deleteFiles({ prefix, force: true })
      .catch((err) => console.error(`cleanupThreadPost: failed to delete ${prefix}`, err));
});

module.exports = { cleanupThreadPost };
