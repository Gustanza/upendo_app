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
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      thumbnail: data['thumbnail'] ?? '',
      fileUrl: data['file_url'] ?? '',
      type: data['type'] ?? 'video',
      featured: data['featured'] ?? false,
      hot: data['hot'] ?? false,
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
    };
  }
}
