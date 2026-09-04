import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  // firestore.rules only allows reads a query can prove satisfy it (a
  // broadcast doc with recipientId == null, or a personal doc with
  // recipientId == the caller's uid) — an unconstrained "get everything"
  // query is rejected outright. Filter.or lets Firestore merge both cases
  // server-side into one ordered stream, rather than hand-combining two
  // separate listeners client-side (which risks one side going silent
  // forever if it errors before its first successful emission).
  //
  // Known limitation: any notification doc created before this feature
  // shipped has no recipientId field at all (the old admin compose flow
  // never wrote one), and `isEqualTo: null` only matches docs where the
  // field is explicitly present and null — so pre-deploy notifications
  // won't appear in this feed. Everything created from the deploy forward
  // (broadcast or targeted) is unaffected.
  Stream<List<AppNotification>> getNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final col = FirebaseFirestore.instance.collection('notifications');

    final filter = uid == null
        ? Filter('recipientId', isEqualTo: null)
        : Filter.or(
            Filter('recipientId', isEqualTo: null),
            Filter('recipientId', isEqualTo: uid),
          );

    return col
        .where(filter)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromFirestore(d.id, d.data()))
            .toList());
  }
}
