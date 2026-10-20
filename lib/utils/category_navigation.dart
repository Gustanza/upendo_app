import 'package:flutter/material.dart';
import '../models/category_group_model.dart';
import '../models/category_model.dart';
import '../services/unread_badge_service.dart';
import '../views/category_posts_screen.dart';
import '../views/subcategories_screen.dart';
import '../views/subcategory_hub_screen.dart';
import '../widgets/category_password_dialog.dart';

// Shared by explore_fragment.dart / home (top-level), CategoryGroupScreen
// (mains of a group) and SubcategoriesScreen (children), so the
// password-check-then-navigate behavior isn't duplicated:
//  * a main category with children → SubcategoriesScreen,
//  * a subcategory → SubcategoryHubScreen (admin topics + community feed,
//    chat room and user groups),
//  * a main category without children → CategoryPostsScreen, exactly like
//    today's leaf-category behavior.
// Only a bool is needed for children: SubcategoriesScreen subscribes to the
// live category stream itself rather than being handed a static list, so
// admin changes still show up while it's open.
Future<void> openCategory(
  BuildContext context,
  Category category, {
  required bool hasChildren,
}) async {
  if (category.isProtected) {
    final unlocked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryPasswordDialog(category: category),
    );
    if (unlocked != true) return;
  }
  if (!context.mounted) return;
  UnreadBadgeService.instance.markCategorySeen(category.id);

  final Widget screen;
  if (hasChildren) {
    screen = SubcategoriesScreen(parent: category);
  } else if (!category.isMain) {
    screen = SubcategoryHubScreen(category: category);
  } else {
    screen = CategoryPostsScreen(category: category);
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

/// Opens a category group's list of main categories. Groups have no
/// password of their own — protected main categories inside still ask.
void openCategoryGroup(BuildContext context, CategoryGroup group) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CategoryGroupScreen(group: group)),
  );
}
