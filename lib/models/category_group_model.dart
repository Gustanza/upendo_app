import 'package:flutter/material.dart';

import 'category_model.dart';

/// Top level of the category hierarchy: group → main categories →
/// subcategories. Lives in its own `categoryGroups` collection (managed
/// from the Vue admin); main categories point at it via Category.groupId.
class CategoryGroup {
  final String id;
  final String name;
  final int iconCode;
  final int colorHex;
  // Display order on Explore/Home (ascending), then by name.
  final int order;

  CategoryGroup({
    required this.id,
    required this.name,
    this.iconCode = 0xe574, // category
    this.colorHex = 0xFF8B2942,
    this.order = 0,
  });

  factory CategoryGroup.fromFirestore(String id, Map<String, dynamic> data) {
    return CategoryGroup(
      id: id,
      name: data['name'] as String? ?? 'Unknown',
      iconCode: (data['iconCode'] as num?)?.toInt() ?? 0xe574,
      colorHex: (data['colorHex'] as num?)?.toInt() ?? 0xFF8B2942,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  IconData get icon => Category.iconFor(iconCode);
  Color get color => Color(colorHex);
}
