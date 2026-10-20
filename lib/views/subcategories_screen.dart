import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/category_group_model.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/category_navigation.dart';
import '../utils/category_tree.dart';
import '../widgets/category_grid_tile.dart';

// Shown when a main category has one or more children (one level of
// nesting below main — see openCategory in category_navigation.dart).
class SubcategoriesScreen extends StatelessWidget {
  final Category parent;

  const SubcategoriesScreen({super.key, required this.parent});

  @override
  Widget build(BuildContext context) {
    return CategoryListScreen(
      title: parent.name,
      subtitle: context.l10n.chooseSubcategory,
      select: (tree, all) => all.where((c) => c.parentId == parent.id).toList(),
    );
  }
}

// Shown when a category group is tapped on Explore/Home: the main
// categories assigned to it (Category.groupId). From here a main category
// opens exactly as it does from the top-level grid.
class CategoryGroupScreen extends StatelessWidget {
  final CategoryGroup group;

  const CategoryGroupScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return CategoryListScreen(
      title: group.name,
      subtitle: context.l10n.chooseCategory,
      select: (tree, all) => tree.mainsIn(group.id),
    );
  }
}

/// Shared grid screen for a list of categories. Reuses the same grid
/// visual style as explore_fragment.dart's top-level grid, and — like it —
/// subscribes to the live category stream rather than taking a static list,
/// so an admin renaming/adding/removing a category shows up immediately for
/// a user with this screen open.
class CategoryListScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Category> Function(CategoryTree tree, List<Category> all) select;

  const CategoryListScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.select,
  });

  @override
  Widget build(BuildContext context) {
    final categoryService = CategoryService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00AEEF), // Light Blue
                  Color(0xFF00008B), // Dark Blue
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: _CategoryTreeBuilder(
              service: categoryService,
              builder: (context, tree, all) {
                final items = select(tree, all);

                if (items.isEmpty) {
                  return Center(child: Text(context.l10n.noCategoriesNow));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 25,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final category = items[index];
                    return CategoryGridTile(
                      category: category,
                      onTap: () => openCategory(
                        context,
                        category,
                        hasChildren: tree.hasChildren(category),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Subscribes to categories + groups once and hands the built tree (and the
/// flat list) to [builder]. Loading/error states match the old grids.
class _CategoryTreeBuilder extends StatefulWidget {
  final CategoryService service;
  final Widget Function(BuildContext, CategoryTree, List<Category>) builder;

  const _CategoryTreeBuilder({required this.service, required this.builder});

  @override
  State<_CategoryTreeBuilder> createState() => _CategoryTreeBuilderState();
}

class _CategoryTreeBuilderState extends State<_CategoryTreeBuilder> {
  late final Stream<CategoryTree> _tree = widget.service.watchTree();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CategoryTree>(
      stream: _tree,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(context.l10n.errorWithDetails('${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tree = snapshot.data!;
        return widget.builder(context, tree, tree.all);
      },
    );
  }
}
