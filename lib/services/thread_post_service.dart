import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/thread_post_model.dart';

class ThreadPostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _threadPosts =>
      _db.collection('threadPosts');

  // Returns the last raw doc alongside the parsed page so callers can use it
  // as the next page's cursor without a second round-trip to Firestore.
  Future<({List<ThreadPostModel> posts, DocumentSnapshot? lastDoc})> getFeed({
    DocumentSnapshot? startAfter,
    int limit = 15,
  }) async {
    Query query =
        _threadPosts.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    return (
      posts: snapshot.docs.map((doc) => ThreadPostModel.fromFirestore(doc)).toList(),
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  Future<ThreadPostModel?> getPostById(String postId) async {
    final doc = await _threadPosts.doc(postId).get();
    if (!doc.exists) return null;
    return ThreadPostModel.fromFirestore(doc);
  }

  // Creates the doc first (so we have an id to scope the Storage path to),
  // then uploads the image and attaches its URL — keeps orphaned uploads
  // impossible to reference even if the upload step fails.
  Future<void> createPost({required String text, XFile? image}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final authorName = (userDoc.data()?['fullName'] as String?) ?? 'Mtumiaji';

    final docRef = await _threadPosts.add({
      'authorId': uid,
      'authorName': authorName,
      'text': text.trim(),
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (image != null) {
      final path = 'threadPosts/${docRef.id}/image.jpg';
      final ref = _storage.ref(path);
      await ref.putData(
        await image.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      await docRef.update({'imageUrl': url, 'imagePath': path});
    }
  }

  Future<void> deletePost(String postId) {
    // Reply/like subcollections and the Storage image are cleaned up
    // server-side by the cleanupThreadPost Cloud Function.
    return _threadPosts.doc(postId).delete();
  }
}
