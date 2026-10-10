import 'package:cloud_firestore/cloud_firestore.dart';

class ThreadReplyModel {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  ThreadReplyModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  factory ThreadReplyModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ThreadReplyModel(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Mtumiaji',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
