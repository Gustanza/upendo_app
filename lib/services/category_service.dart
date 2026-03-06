import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Category>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }
}
