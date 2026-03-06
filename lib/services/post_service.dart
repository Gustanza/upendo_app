import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<List<PostModel>> getPostsByCategory(String categoryId) async {
    QuerySnapshot snapshot = await _db
        .collection('posts')
        .where('category_id', isEqualTo: categoryId)
        .get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<List<PostModel>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    // Firestore prefix search
    QuerySnapshot snapshot = await _db
        .collection('posts')
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
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
