import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';

class PostInteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _db.collection('posts').doc(postId).collection('comments');

  DocumentReference<Map<String, dynamic>> _like(String postId, String uid) =>
      _db.collection('posts').doc(postId).collection('likes').doc(uid);

  // Unpaginated: this is a single post's thread in a modal sheet, not a global
  // feed. If a post ever accumulates a huge number of comments, add .limit()
  // + cursor pagination here — not needed preemptively.
  Stream<List<CommentModel>> getComments(String postId) {
    return _comments(postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommentModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> addComment(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final userName = (userDoc.data()?['fullName'] as String?) ?? 'Mtumiaji';
    await _comments(postId).add({
      'userId': uid,
      'userName': userName,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) {
    // Ownership is enforced by firestore.rules, not here.
    return _comments(postId).doc(commentId).delete();
  }

  Stream<bool> likedByMe(String postId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _like(postId, uid).snapshots().map((d) => d.exists);
  }

  Future<void> toggleLike(String postId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = _like(postId, uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<int> likeCount(String postId) => _postCount(postId, 'likeCount');

  Stream<int> commentCount(String postId) => _postCount(postId, 'commentCount');

  Stream<int> _postCount(String postId, String field) {
    return _db
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((d) => (d.data()?[field] ?? 0) as int);
  }
}
