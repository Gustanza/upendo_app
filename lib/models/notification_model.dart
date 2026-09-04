import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? sentAt;
  // null/absent means a public broadcast; otherwise the uid this
  // notification is targeted at (e.g. a comment/like on their post).
  final String? recipientId;
  final String? type;
  final String? postId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.createdAt,
    this.sentAt,
    this.recipientId,
    this.type,
    this.postId,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      recipientId: data['recipientId'] as String?,
      type: data['type'] as String?,
      postId: data['postId'] as String?,
    );
  }
}
