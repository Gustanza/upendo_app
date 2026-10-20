import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attachment_model.dart';
import '../models/poll_model.dart';
import '../models/thread_post_model.dart';
import '../models/thread_scope.dart';
import 'attachment_service.dart';

class ThreadPostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ThreadScope scope;

  /// Defaults to the community wall; pass a subcategory/group scope to work
  /// on that feed instead.
  ThreadPostService({this.scope = ThreadScope.wall});

  CollectionReference<Map<String, dynamic>> get _threadPosts =>
      _db.collection(scope.postsPath);

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

  // Reserves the doc id first (to scope the Storage folder), uploads the
  // attachments, then writes the doc — so the feed never shows a post whose
  // media is still uploading. Everything under {postsPath}/{id}/ in Storage
  // is removed by the cleanup Cloud Functions when the post is deleted.
  Future<void> createPost({
    required String text,
    List<PendingAttachment> attachments = const [],
    List<String> links = const [],
    PollData? poll,
    void Function(double progress)? onUploadProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final authorName = (userDoc.data()?['fullName'] as String?) ?? '';

    final docRef = _threadPosts.doc();
    final uploaded = await AttachmentService().uploadAll(
      '${scope.postsPath}/${docRef.id}',
      attachments,
      onProgress: onUploadProgress,
    );
    final firstImage =
        uploaded.where((a) => a.type == Attachment.image).firstOrNull;

    await docRef.set({
      'authorId': uid,
      'authorName': authorName,
      'text': text.trim(),
      'imageUrl': firstImage?.url,
      'createdAt': FieldValue.serverTimestamp(),
      'type': poll != null ? PollType.hostType : 'text',
      'pollType': poll?.pollType,
      'pollOptions': poll?.options,
      if (uploaded.isNotEmpty)
        'attachments': uploaded.map((a) => a.toMap()).toList(),
      if (scope.allowLinks && links.isNotEmpty) 'links': links,
    });
  }

  Future<void> deletePost(String postId) {
    // Reply/like subcollections and Storage files are cleaned up
    // server-side by the cleanup Cloud Functions. firestore.rules lets the
    // author — or, in a group, its owner or an admin — delete.
    return _threadPosts.doc(postId).delete();
  }
}
