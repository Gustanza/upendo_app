import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/models/category_group_model.dart';
import 'package:upendo_app/models/category_model.dart';
import 'package:upendo_app/utils/category_tree.dart';

void main() {
  Category cat(String id, {String? parentId, String? groupId}) =>
      Category(id: id, name: id, parentId: parentId, groupId: groupId);

  test('no groups at all → every main category is ungrouped (legacy data)', () {
    final tree = CategoryTree.build([
      cat('health'),
      cat('faith'),
      cat('nutrition', parentId: 'health'),
    ], const []);
    expect(tree.hasGroups, isFalse);
    expect(tree.ungroupedMains.map((c) => c.id), ['health', 'faith']);
    expect(tree.hasChildren(tree.ungroupedMains.first), isTrue);
    expect(tree.hasChildren(tree.ungroupedMains.last), isFalse);
  });

  test('main categories are listed under their group; subcategories never are', () {
    final groups = [CategoryGroup(id: 'life', name: 'Life')];
    final tree = CategoryTree.build([
      cat('health', groupId: 'life'),
      cat('faith'),
      // A stray groupId on a subcategory must not pull it to the top level.
      cat('nutrition', parentId: 'health', groupId: 'life'),
    ], groups);
    expect(tree.groups.map((g) => g.id), ['life']);
    expect(tree.mainsIn('life').map((c) => c.id), ['health']);
    expect(tree.ungroupedMains.map((c) => c.id), ['faith']);
  });

  test('a groupId pointing at a deleted group falls back to ungrouped', () {
    final tree = CategoryTree.build([cat('health', groupId: 'gone')], const []);
    expect(tree.ungroupedMains.map((c) => c.id), ['health']);
  });

  test('empty groups are hidden; groups sort by order then name', () {
    final groups = [
      CategoryGroup(id: 'b', name: 'Beta', order: 1),
      CategoryGroup(id: 'a', name: 'alpha', order: 1),
      CategoryGroup(id: 'z', name: 'Zed', order: 0),
      CategoryGroup(id: 'empty', name: 'Empty', order: -1),
    ];
    final tree = CategoryTree.build([
      cat('1', groupId: 'a'),
      cat('2', groupId: 'b'),
      cat('3', groupId: 'z'),
    ], groups);
    expect(tree.groups.map((g) => g.id), ['z', 'a', 'b']);
  });

  test('Category/CategoryGroup tolerate missing fields', () {
    final c = Category.fromFirestore('x', const {});
    expect(c.groupId, isNull);
    expect(c.isMain, isTrue);
    final g = CategoryGroup.fromFirestore('g', const {});
    expect(g.order, 0);
    expect(g.name, 'Unknown');
  });
}
