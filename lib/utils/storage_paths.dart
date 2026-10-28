/// Firebase Storage folders the app uploads to.
///
/// These MUST match storage.rules, which authorise every upload from the
/// path and the signed-in uid alone — no cross-service Firestore lookups,
/// because production denies those unless the Storage service agent has
/// the "Firebase Rules Firestore Service Agent" IAM role (the emulator
/// doesn't enforce that, so emulator tests can't catch it). firestore.rules
/// then checks that a post/message only references files in its own folder.
class StoragePaths {
  StoragePaths._();

  /// conversations/{uidA_uidB}/{messageId} — the conversation id encodes
  /// both participants, so storage.rules checks membership from the path.
  static String conversationMessage(String conversationId, String messageId) =>
      'conversations/$conversationId/$messageId';

  /// userGroups/{groupId}/{posts|messages}/{itemId}/{uploaderUid}
  static String groupItem(String groupId, String kind, String itemId, String uploaderUid) =>
      'userGroups/$groupId/$kind/$itemId/$uploaderUid';

  /// userGroups/{groupId}/photo/{uploaderUid}/{fileName} — uploaded BEFORE
  /// the group doc is written, then referenced by photoPath (owner only).
  static String groupPhoto(String groupId, String uploaderUid, String fileName) =>
      'userGroups/$groupId/photo/$uploaderUid/$fileName';
}
