import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poll_model.dart';

// Polls have no dedicated top-level collection — they live as extra fields on
// whatever doc hosts them (a post, threadPost or chat message), with answers
// in a pollResponses subcollection under it. Callers pass in that
// subcollection's reference rather than this service owning one itself.
class PollService {
  // No count-query/aggregation methods: callers tally client-side from
  // watchResponses since audiences are small (a private chat has 2 people,
  // a category/wall poll's response count is realistically small too).
  Stream<List<PollResponseModel>> watchResponses(
      CollectionReference<Map<String, dynamic>> responsesRef) {
    return responsesRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => PollResponseModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  Future<void> submitResponse({
    required CollectionReference<Map<String, dynamic>> responsesRef,
    required String answer,
  }) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return responsesRef.doc(uid).set({
      'answer': answer,
      'answeredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> retractResponse(
      CollectionReference<Map<String, dynamic>> responsesRef) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return responsesRef.doc(uid).delete();
  }
}
