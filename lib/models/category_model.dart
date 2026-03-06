import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int iconCode;
  final int colorHex;

  Category({
    required this.id,
    required this.name,
    this.iconCode = 0xe491, // people_outline
    this.colorHex = 0xFF1565C0, // blue[800]
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? 'Unknown',
      iconCode: data['iconCode'] ?? 0xe491,
      colorHex: data['colorHex'] ?? 0xFF1565C0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'iconCode': iconCode, 'colorHex': colorHex};
  }

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorHex);
}
