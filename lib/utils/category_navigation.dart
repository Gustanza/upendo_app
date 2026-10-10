import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/unread_badge_service.dart';
import '../views/category_posts_screen.dart';
import '../views/subcategories_screen.dart';
import '../widgets/category_password_dialog.dart';

// Shared by explore_fragment.dart (top-level grid) and subcategories_screen.dart
// (child grid), so the password-check-then-navigate behavior isn't duplicated.
// A child category can never have children of its own (one level of nesting
// only), so calling this with hasChildren: false — as subcategories_screen.dart
// always does — takes the CategoryPostsScreen branch below, exactly like
// today's leaf-category behavior. Only a bool is needed here: SubcategoriesScreen
// subscribes to the live category stream itself rather than being handed a
// static list, so admin changes still show up while it's open.
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

  if (!hasChildren) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPostsScreen(category: category),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubcategoriesScreen(parent: category),
      ),
    );
  }
}
