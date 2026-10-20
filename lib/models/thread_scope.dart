import 'media_limits.dart';

/// Which feed a thread post lives in. The community wall, every
/// subcategory's discussion feed and every user group's feed share the
/// same post/reply/like/poll shape (ThreadPostModel) — only the collection
/// path, attachment rules and moderation differ.
class ThreadScope {
  /// Firestore collection holding the post docs (replies/likes/
  /// pollResponses are subcollections of each post). Attachments are
  /// uploaded under the same path in Storage.
  final String postsPath;
  final MediaLimits limits;

  /// Group posts may carry external links shown with a preview card.
  final bool allowLinks;

  /// May delete anyone's post or reply in this feed (a group's owner).
  final String? moderatorId;

  const ThreadScope({
    required this.postsPath,
    this.limits = MediaLimits.community,
    this.allowLinks = false,
    this.moderatorId,
  });

  static const maxTextLength = 1000;
  static const maxLinks = 3;

  /// The original community wall ("Ukuta wa Jumuiya").
  static const wall = ThreadScope(postsPath: 'threadPosts', limits: MediaLimits.wall);

  factory ThreadScope.subcategory(String categoryId) =>
      ThreadScope(postsPath: 'subcategoryFeeds/$categoryId/posts');

  factory ThreadScope.group(String groupId, {required String ownerId}) => ThreadScope(
        postsPath: 'userGroups/$groupId/posts',
        allowLinks: true,
        moderatorId: ownerId,
      );

  bool get isWall => postsPath == wall.postsPath;

  bool canDelete({required String authorId, required String? myUid}) =>
      myUid != null && (authorId == myUid || moderatorId == myUid);
}
