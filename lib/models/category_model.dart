import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int iconCode;
  final int colorHex;
  final bool isProtected;
  final String? passwordHash;

  Category({
    required this.id,
    required this.name,
    this.iconCode = 0xe2cc, // folder
    this.colorHex = 0xFF1565C0, // blue[800]
    this.isProtected = false,
    this.passwordHash,
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? 'Unknown',
      iconCode: data['iconCode'] ?? 0xe2cc,
      colorHex: data['colorHex'] ?? 0xFF1565C0,
      isProtected: data['isProtected'] ?? false,
      passwordHash: data['passwordHash'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'isProtected': isProtected,
      if (passwordHash != null) 'passwordHash': passwordHash,
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

  IconData get icon => _supportedIcons[iconCode] ?? Icons.folder;
  Color get color => Color(colorHex);
}
