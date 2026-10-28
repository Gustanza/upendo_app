import '../models/category_model.dart';
import '../models/post_model.dart';

/// Which admin posts (posts.category_id) a category's Topics list shows.
///
/// The admin dashboard lets a post be assigned to any category, main or
/// sub. A main category that HAS subcategories never shows its own post
/// list in the app (tapping it opens the subcategory list), so posts the
/// admin put on the main category were invisible and every subcategory's
/// Topics tab said "No topics yet". A subcategory therefore shows its own
/// posts first, then the posts of its main category.
List<String> topicCategoryIds(Category category) {
  final parentId = category.parentId;
  return [
    category.id,
    if (parentId != null && parentId.isNotEmpty && parentId != category.id) parentId,
  ];
}

/// The category's own posts first, then the parent's; newest first within
/// each (posts without created_at last, in their original order).
List<PostModel> orderTopics(List<PostModel> posts, Category category) {
  int rank(PostModel p) => p.categoryId == category.id ? 0 : 1;
  final indexed = posts.asMap().entries.toList()
    ..sort((a, b) {
      final byRank = rank(a.value).compareTo(rank(b.value));
      if (byRank != 0) return byRank;
      final at = a.value.createdAt;
      final bt = b.value.createdAt;
      if (at != null && bt != null && at != bt) return bt.compareTo(at);
      if (at != null && bt == null) return -1;
      if (at == null && bt != null) return 1;
      return a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList();
}
