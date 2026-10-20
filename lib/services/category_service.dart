import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_group_model.dart';
import '../models/category_model.dart';
import '../utils/category_tree.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Category>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// All category groups (a handful of docs). Sorting/empty-group hiding is
  /// done by CategoryTree.
  Stream<List<CategoryGroup>> getCategoryGroups() {
    return _db.collection('categoryGroups').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryGroup.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Categories + groups combined into the 3-level hierarchy, re-emitted
  /// whenever either collection changes. If groups can't be read (e.g.
  /// before the new rules are deployed) the tree simply has no groups, so
  /// Explore/Home keep working exactly as they did before groups existed.
  Stream<CategoryTree> watchTree() {
    late final StreamController<CategoryTree> controller;
    List<Category>? categories;
    List<CategoryGroup>? groups;
    StreamSubscription<List<Category>>? categoriesSub;
    StreamSubscription<List<CategoryGroup>>? groupsSub;

    void emit() {
      final c = categories, g = groups;
      if (c != null && g != null) controller.add(CategoryTree.build(c, g));
    }

    controller = StreamController<CategoryTree>(
      onListen: () {
        categoriesSub = getCategories().listen((v) {
          categories = v;
          emit();
        }, onError: controller.addError);
        groupsSub = getCategoryGroups().listen((v) {
          groups = v;
          emit();
        }, onError: (_) {
          groups = const [];
          emit();
        });
      },
      onCancel: () async {
        await categoriesSub?.cancel();
        await groupsSub?.cancel();
      },
    );
    return controller.stream;
  }
}
