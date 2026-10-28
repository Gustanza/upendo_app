import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String thumbnail;
  final String fileUrl;
  final String type;
  final bool featured;
  final bool hot;
  final String categoryId;
  // Maintained server-side only by Cloud Functions — never written by client,
  // deliberately excluded from toFirestore().
  final int likeCount;
  final int commentCount;
  final String? pollType;
  final List<String>? pollOptions;
  // created_at, written by the admin dashboard (PostFormModal). Older posts
  // may not have it.
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.thumbnail,
    required this.fileUrl,
    required this.type,
    required this.featured,
    required this.hot,
    required this.categoryId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.pollType,
    this.pollOptions,
    this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel.fromMap(doc.id, data);
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      thumbnail: data['thumbnail'] ?? '',
      fileUrl: data['file_url'] ?? '',
      type: data['type'] ?? 'video',
      featured: data['featured'] ?? false,
      hot: data['hot'] ?? false,
      categoryId: data['category_id'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      pollType: data['pollType'] as String?,
      pollOptions: data['pollOptions'] is List
          ? (data['pollOptions'] as List).map((e) => e.toString()).toList()
          : null,
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'thumbnail': thumbnail,
      'file_url': fileUrl,
      'type': type,
      'featured': featured,
      'hot': hot,
      'category_id': categoryId,
      'pollType': pollType,
      'pollOptions': pollOptions,
    };
  }
}
