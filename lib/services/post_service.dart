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
}
