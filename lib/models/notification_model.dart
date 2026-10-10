import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? sentAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.createdAt,
    this.sentAt,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}
