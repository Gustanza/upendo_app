import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime? createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    this.createdAt,
  });

  factory CommentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CommentModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Mtumiaji',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
