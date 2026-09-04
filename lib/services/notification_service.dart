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
  // never wrote one), and matching on recipientId == null only matches docs
  // where the field is explicitly present and null — so pre-deploy
  // notifications won't appear in this feed. Everything created from the
  // deploy forward (broadcast or targeted) is unaffected.
  Stream<List<AppNotification>> getNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final col = FirebaseFirestore.instance.collection('notifications');

    // Deliberately isNull: true, not isEqualTo: null — the Filter
    // constructor counts non-null named-operator arguments to enforce
    // "exactly one operator", and a null *value* passed to isEqualTo is
    // indistinguishable from the parameter not being passed at all, so
    // isEqualTo: null always fails that assertion at construction time
    // (before any network call — this crashed every call to this method).
    // isNull: true produces the identical underlying '==' / null query.
    final filter = uid == null
        ? Filter('recipientId', isNull: true)
        : Filter.or(
            Filter('recipientId', isNull: true),
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
