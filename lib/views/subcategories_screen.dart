import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/category_navigation.dart';
import '../widgets/category_grid_tile.dart';

// Shown when a top-level category has one or more children (one level of
// nesting only — see openCategory in category_navigation.dart). Reuses the
// same grid visual style as explore_fragment.dart's top-level grid, and —
// like it — subscribes to the live category stream rather than taking a
// static list, so an admin renaming/adding/removing a sub-category shows up
// immediately for a user with this screen open, same as the top-level grid.
class SubcategoriesScreen extends StatelessWidget {
  final Category parent;

  const SubcategoriesScreen({super.key, required this.parent});

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
                  parent.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chagua kipengele unachotaka',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: categoryService.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final children = (snapshot.data ?? [])
                    .where((c) => c.parentId == parent.id)
                    .toList();

                if (children.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 25,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    // A child can't have children of its own (one level of
                    // nesting only), so this is always the terminal tap —
                    // password check, then straight to CategoryPostsScreen.
                    return CategoryGridTile(
                      category: child,
                      onTap: () =>
                          openCategory(context, child, hasChildren: false),
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
