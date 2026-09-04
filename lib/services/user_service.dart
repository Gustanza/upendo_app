import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserModel>> getUsers({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _db.collection('users').orderBy('fullName').limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // To help with pagination, we need the last document
  Future<DocumentSnapshot?> getLastDocument({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _db.collection('users').orderBy('fullName').limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.last;
    }
    return null;
  }

  // Prefix match on fullName using the standard Firestore startAt/endAt
  // range-query trick: appending U+F8FF (a private-use codepoint that
  // sorts after virtually every real character) to the upper bound turns
  // an equality range into a "starts with" range. Built via
  // String.fromCharCode rather than embedding the codepoint directly in
  // this source file — that character renders as invisible/blank in most
  // editors and fonts, which makes a missing-suffix bug look identical to
  // a correct one on sight (and just as easy to lose in a future edit).
  // No full-text/fuzzy search, no new field, no schema migration.
  // Case-sensitive, matching how names are actually stored.
  Future<List<UserModel>> searchUsersByName(String query, {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final upperBound = trimmed + String.fromCharCode(0xF8FF);

    final snapshot = await _db
        .collection('users')
        .orderBy('fullName')
        .startAt([trimmed])
        .endAt([upperBound])
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}
