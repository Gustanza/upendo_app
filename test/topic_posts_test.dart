import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/models/category_model.dart';
import 'package:upendo_app/models/post_model.dart';
import 'package:upendo_app/utils/topic_posts.dart';

// The subcategory hub's Topics tab used to query only posts whose
// category_id == the subcategory, so admin posts assigned to the main
// category (which, once it has subcategories, never shows its own list)
// were invisible: "No topics yet".
void main() {
  PostModel post(String id, String categoryId, {DateTime? at}) => PostModel.fromMap(id, {
        'title': id,
        'category_id': categoryId,
        if (at != null) 'created_at': Timestamp.fromDate(at),
      });

  final sub = Category(id: 'sub1', name: 'Malezi', parentId: 'main1');
  final main = Category(id: 'main1', name: 'Familia');

  test('a subcategory shows its own posts and its main category\'s', () {
    expect(topicCategoryIds(sub), ['sub1', 'main1']);
  });

  test('a main/leaf category shows only its own posts', () {
    expect(topicCategoryIds(main), ['main1']);
    expect(topicCategoryIds(Category(id: 'x', name: 'x', parentId: '')), ['x']);
  });

  test('own posts first, then the parent\'s; newest first; undated last', () {
    final ordered = orderTopics([
      post('mainOld', 'main1', at: DateTime(2026, 1, 1)),
      post('subUndated', 'sub1'),
      post('subOld', 'sub1', at: DateTime(2026, 2, 1)),
      post('mainNew', 'main1', at: DateTime(2026, 9, 1)),
      post('subNew', 'sub1', at: DateTime(2026, 10, 1)),
    ], sub);
    expect(ordered.map((p) => p.id), ['subNew', 'subOld', 'subUndated', 'mainNew', 'mainOld']);
  });

  test('admin dashboard fields are read (category_id, created_at)', () {
    final p = post('p', 'sub1', at: DateTime.utc(2026, 10, 27));
    expect(p.categoryId, 'sub1');
    expect(p.createdAt, DateTime.utc(2026, 10, 27).toLocal());
  });
}
