import 'package:cloud_firestore/cloud_firestore.dart';
import 'attachment_model.dart';

class ThreadPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;
  // Maintained server-side only by Cloud Functions — never written by client.
  final int likeCount;
  final int commentCount;
  final String type;
  final String? pollType;
  final List<String>? pollOptions;
  // Images (up to 5) and/or a video. imageUrl above mirrors the first image
  // so builds from before attachments existed still show something.
  final List<Attachment> attachments;

  ThreadPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.imageUrl,
    this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.type = 'text',
    this.pollType,
    this.pollOptions,
    this.attachments = const [],
  });

  factory ThreadPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ThreadPostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Mtumiaji',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      type: data['type'] ?? 'text',
      pollType: data['pollType'] as String?,
      pollOptions: data['pollOptions'] is List
          ? (data['pollOptions'] as List).map((e) => e.toString()).toList()
          : null,
      attachments: Attachment.listFrom(data['attachments']),
    );
  }
}
