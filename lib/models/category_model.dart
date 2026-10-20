import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int iconCode;
  final int colorHex;
  final bool isProtected;
  final String? passwordHash;
  // null/absent = top-level ("main") category. One level of nesting only —
  // a category referenced as someone's parentId is never itself expected to
  // have a parentId (enforced by the admin form, not by this model).
  final String? parentId;
  // Main categories only: the categoryGroups/{id} this main category is
  // listed under. null/absent (every pre-existing category) = ungrouped,
  // shown directly on Explore/Home as before — see category_tree.dart.
  final String? groupId;

  Category({
    required this.id,
    required this.name,
    this.iconCode = 0xe2cc, // folder
    this.colorHex = 0xFF1565C0, // blue[800]
    this.isProtected = false,
    this.passwordHash,
    this.parentId,
    this.groupId,
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? 'Unknown',
      iconCode: data['iconCode'] ?? 0xe2cc,
      colorHex: data['colorHex'] ?? 0xFF1565C0,
      isProtected: data['isProtected'] ?? false,
      passwordHash: data['passwordHash'],
      parentId: data['parentId'] as String?,
      groupId: data['groupId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'isProtected': isProtected,
      if (passwordHash != null) 'passwordHash': passwordHash,
      if (parentId != null) 'parentId': parentId,
      if (groupId != null) 'groupId': groupId,
    };
  }

  // Keys are the web Material Icons codepoints stored in Firestore by the Vue admin.
  // Values are Flutter Icons.* constants (different font, same visual icon).
  static const Map<int, IconData> _supportedIcons = {
    0xe88a: Icons.home,
    0xe87d: Icons.favorite,
    0xe838: Icons.star,
    0xe865: Icons.book,
    0xe80c: Icons.school,
    0xe405: Icons.music_note,
    0xeb43: Icons.fitness_center,
    0xe56c: Icons.restaurant,
    0xe548: Icons.local_hospital,
    0xeb3e: Icons.self_improvement,
    0xea30: Icons.sports,
    0xeaae: Icons.church,
    0xe7ef: Icons.group,
    0xe7fb: Icons.people,
    0xe8f9: Icons.work,
    0xe40a: Icons.brush,
    0xe412: Icons.photo,
    0xe430: Icons.wb_sunny,
    0xe564: Icons.terrain,
    0xe566: Icons.directions_run,
    0xe574: Icons.category,
    0xe406: Icons.nature,
    0xe53e: Icons.local_florist,
    0xeb67: Icons.child_care,
    0xe2cc: Icons.folder,
    0xe8b8: Icons.settings,
    0xe7fd: Icons.person,
    0xe0c9: Icons.chat,
    0xe55a: Icons.location_on,
    0xe2bd: Icons.cloud,
    0xe5c3: Icons.flag,
    0xe86f: Icons.map,
    0xe53b: Icons.store,
    0xe8b0: Icons.security,
    0xe3a9: Icons.explore,
    0xe54e: Icons.hotel,
  };

  /// Flutter icon for a web Material Icons codepoint stored by the admin
  /// (shared with CategoryGroup).
  static IconData iconFor(int code) => _supportedIcons[code] ?? Icons.folder;

  bool get isMain => parentId == null;

  IconData get icon => iconFor(iconCode);
  Color get color => Color(colorHex);
}
