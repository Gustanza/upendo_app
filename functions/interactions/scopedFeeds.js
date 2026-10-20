const { onDocumentWritten, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { transitionDelta } = require('./_util');

// Server-side upkeep for the feeds added alongside the community wall:
//  * subcategoryFeeds/{categoryId}/posts|messages — every subcategory's
//    open discussion feed and chat room,
//  * userGroups/{groupId}/posts|messages|members — user groups.
// Same jobs counters.js/cleanupThreadPost.js do for /threadPosts:
// likeCount/commentCount/memberCount are server-only fields, and deleting
// a post/message/group removes its subcollections and Storage files.
// No push notifications here on purpose — broadcasting every subcategory
// or group post to all users (like the wall does) would be far too noisy.

// The doc that owns the subcollection a trigger fired in
// (…/posts/{postId}/replies/{id} → …/posts/{postId}).
function parentDocRef(event) {
  const snap = event.data.after.exists ? event.data.after : event.data.before;
  return snap.ref.parent.parent;
}

// The parent may already be gone (e.g. its replies being deleted by the
// cleanup below) — update() then fails with NOT_FOUND, which is expected
// and must not recreate the doc (so no set/merge here).
async function bump(ref, field, delta) {
  try {
    await ref.update({ [field]: FieldValue.increment(delta) });
  } catch (err) {
    if (err && err.code === 5) return; // NOT_FOUND
    throw err;
  }
}

function counter(path, field) {
  return onDocumentWritten(path, async (event) => {
    const delta = transitionDelta(event);
    if (delta === 0) return;
    await bump(parentDocRef(event), field, delta);
  });
}

const updateSubcategoryReplyCount = counter('subcategoryFeeds/{categoryId}/posts/{postId}/replies/{replyId}', 'commentCount');
const updateSubcategoryLikeCount = counter('subcategoryFeeds/{categoryId}/posts/{postId}/likes/{uid}', 'likeCount');
const updateGroupReplyCount = counter('userGroups/{groupId}/posts/{postId}/replies/{replyId}', 'commentCount');
const updateGroupLikeCount = counter('userGroups/{groupId}/posts/{postId}/likes/{uid}', 'likeCount');
const updateGroupMemberCount = counter('userGroups/{groupId}/members/{uid}', 'memberCount');

async function deleteStorageFolder(prefix) {
  await getStorage().bucket().deleteFiles({ prefix, force: true })
    .catch((err) => console.error(`scopedFeeds: failed to delete ${prefix}`, err));
}

// recursiveDelete on an already-deleted doc removes whatever
// subcollections (replies/likes/pollResponses) it left behind, in batches.
function cleanupOnDelete(path) {
  return onDocumentDeleted(path, async (event) => {
    const ref = event.data.ref;
    await getFirestore().recursiveDelete(ref);
    await deleteStorageFolder(`${ref.path}/`);
  });
}

const cleanupSubcategoryPost = cleanupOnDelete('subcategoryFeeds/{categoryId}/posts/{postId}');
const cleanupGroupPost = cleanupOnDelete('userGroups/{groupId}/posts/{postId}');
const cleanupSubcategoryMessage = cleanupOnDelete('subcategoryFeeds/{categoryId}/messages/{messageId}');
const cleanupGroupMessage = cleanupOnDelete('userGroups/{groupId}/messages/{messageId}');

// Deleting a group (by its owner in the app, or an admin from the
// dashboard) removes its members, bans, posts (with replies/likes/polls),
// chat and every uploaded file, including the profile picture.
const cleanupUserGroup = cleanupOnDelete('userGroups/{groupId}');

module.exports = {
  updateSubcategoryReplyCount,
  updateSubcategoryLikeCount,
  updateGroupReplyCount,
  updateGroupLikeCount,
  updateGroupMemberCount,
  cleanupSubcategoryPost,
  cleanupGroupPost,
  cleanupSubcategoryMessage,
  cleanupGroupMessage,
  cleanupUserGroup,
};
