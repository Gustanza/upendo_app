import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/post_model.dart';
import '../utils/topic_posts.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _searchPostsUrl =
      'https://searchposts-dcnp2gn42a-uc.a.run.app';

  Future<List<PostModel>> getFeaturedPosts({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    Query query = _db
        .collection('posts')
        .where('featured', isEqualTo: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<List<PostModel>> getHotPosts({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    Query query = _db
        .collection('posts')
        .where('hot', isEqualTo: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  // Helper to get the actual DocumentSnapshot for pagination
  Future<DocumentSnapshot?> getLastFeaturedDoc(
    DocumentSnapshot? startAfter,
  ) async {
    Query query = _db
        .collection('posts')
        .where('featured', isEqualTo: true)
        .limit(10);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
  }

  Future<DocumentSnapshot?> getLastHotDoc(DocumentSnapshot? startAfter) async {
    Query query = _db
        .collection('posts')
        .where('hot', isEqualTo: true)
        .limit(10);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
  }

  Future<PostModel?> getPostById(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  /// Live Topics list of [category]: its own posts plus, for a
  /// subcategory, its main category's (see utils/topic_posts.dart). A
  /// single-field `whereIn` with client-side ordering needs no composite
  /// index, and (unlike orderBy('created_at')) keeps older posts that have
  /// no created_at. A doc that can't be parsed is skipped instead of failing
  /// the whole list, which used to show up as "No topics yet".
  Stream<List<PostModel>> watchTopics(Category category) {
    return _db
        .collection('posts')
        .where('category_id', whereIn: topicCategoryIds(category))
        .snapshots()
        .map((snap) {
      final posts = <PostModel>[];
      for (final doc in snap.docs) {
        try {
          posts.add(PostModel.fromFirestore(doc));
        } catch (e) {
          debugPrint('PostService.watchTopics: skipping posts/${doc.id}: $e');
        }
      }
      return orderTopics(posts, category);
    });
  }

  Future<List<PostModel>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse(_searchPostsUrl).replace(
      queryParameters: {'q': query},
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('searchPosts failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? []);

    return results
        .map((item) => PostModel.fromMap(
              item['id'] as String,
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<List<PostModel>> getPostsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore whereIn limit is 10, so if there are more we might need to chunk
    // or just handle up to 10 for now as a simple implementation.
    // For many apps, users don't save hundreds of posts immediately.
    // Let's implement chunking just in case.
    List<PostModel> posts = [];
    for (var i = 0; i < ids.length; i += 10) {
      var chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      QuerySnapshot snapshot = await _db
          .collection('posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      posts.addAll(
        snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
      );
    }
    return posts;
  }
}
