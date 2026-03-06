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
}
