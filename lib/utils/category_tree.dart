import '../models/category_group_model.dart';
import '../models/category_model.dart';

/// The 3-level category hierarchy (group → main → sub) computed from the
/// flat `categories` and `categoryGroups` collections. Pure, so Explore,
/// Home and the group screen agree on it and it's unit-tested
/// (test/category_tree_test.dart).
///
/// Backward compatible: main categories without a groupId — or whose
/// groupId points at a group that no longer exists — are "ungrouped" and
/// shown directly, exactly like before groups existed. Groups with no main
/// categories are hidden so a tap never leads to an empty screen.
class CategoryTree {
  final List<Category> all;
  final List<CategoryGroup> groups;
  final Map<String, List<Category>> mainsByGroup;
  final List<Category> ungroupedMains;
  final Set<String> parentIdsWithChildren;

  CategoryTree._({
    required this.all,
    required this.groups,
    required this.mainsByGroup,
    required this.ungroupedMains,
    required this.parentIdsWithChildren,
  });

  factory CategoryTree.build(List<Category> categories, List<CategoryGroup> groups) {
    final groupIds = groups.map((g) => g.id).toSet();
    final mainsByGroup = <String, List<Category>>{};
    final ungrouped = <Category>[];
    for (final c in categories) {
      if (!c.isMain) continue;
      final groupId = c.groupId;
      if (groupId != null && groupIds.contains(groupId)) {
        (mainsByGroup[groupId] ??= []).add(c);
      } else {
        ungrouped.add(c);
      }
    }
    final visibleGroups = groups.where((g) => mainsByGroup.containsKey(g.id)).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return CategoryTree._(
      all: categories,
      groups: visibleGroups,
      mainsByGroup: mainsByGroup,
      ungroupedMains: ungrouped,
      parentIdsWithChildren:
          categories.map((c) => c.parentId).whereType<String>().toSet(),
    );
  }

  List<Category> mainsIn(String groupId) => mainsByGroup[groupId] ?? const [];

  bool hasChildren(Category c) => parentIdsWithChildren.contains(c.id);

  bool get hasGroups => groups.isNotEmpty;
}
