import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thread_reply_model.dart';

class ThreadInteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _replies(String postId) =>
      _db.collection('threadPosts').doc(postId).collection('replies');

  DocumentReference<Map<String, dynamic>> _like(String postId, String uid) =>
      _db.collection('threadPosts').doc(postId).collection('likes').doc(uid);

  // Unpaginated: a single thread's reply list, not a global feed — same
  // tradeoff as PostInteractionService.getComments.
  Stream<List<ThreadReplyModel>> getReplies(String postId) {
    return _replies(postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ThreadReplyModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> addReply(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final authorName = (userDoc.data()?['fullName'] as String?) ?? 'Mtumiaji';
    await _replies(postId).add({
      'authorId': uid,
      'authorName': authorName,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReply(String postId, String replyId) {
    // Ownership is enforced by firestore.rules, not here.
    return _replies(postId).doc(replyId).delete();
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
        .collection('threadPosts')
        .doc(postId)
        .snapshots()
        .map((d) => (d.data()?[field] ?? 0) as int);
  }
}
