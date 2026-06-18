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

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorHex);
}
