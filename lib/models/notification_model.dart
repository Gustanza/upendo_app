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
  final String? conversationId;
  // Only set on broadcast (recipientId == null) comment/like notifications
  // on /posts — the uid of whoever commented/liked, so the current user's
  // own action can be filtered out of their own notification list. A
  // topic-based broadcast push can't itself exclude the actor's device, but
  // the in-app list can skip it — see NotificationService.getNotifications.
  final String? actorId;

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
    this.conversationId,
    this.actorId,
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
      conversationId: data['conversationId'] as String?,
      actorId: data['actorId'] as String?,
    );
  }
}
