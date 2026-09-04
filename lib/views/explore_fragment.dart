import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';
import '../utils/category_navigation.dart';
import '../widgets/category_grid_tile.dart';

class ExploreFragment extends StatelessWidget {
  const ExploreFragment({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryService = CategoryService();

    return Column(
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
                onPressed:
                    () {}, // Optional: Handle back if this was a separate screen
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 10),
              const Text(
                'Chagua Mada\nyako pendwa',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Jifunze kwa Video, Sauti, Soma na Muziki',
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

              final categories = snapshot.data ?? [];

              // The main grid only ever shows top-level categories — a
              // category that's someone else's child never appears here,
              // it only shows up inside that parent's SubcategoriesScreen.
              final topLevel =
                  categories.where((c) => c.parentId == null).toList();

              if (topLevel.isEmpty) {
                return const Center(child: Text('No categories found.'));
              }

              // Only used to decide, at tap time, which screen to push —
              // SubcategoriesScreen subscribes to the live stream itself
              // rather than being handed this snapshot's children, so it
              // stays current after navigation (see subcategories_screen.dart).
              final parentIdsWithChildren = categories
                  .map((c) => c.parentId)
                  .whereType<String>()
                  .toSet();

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 25,
                  childAspectRatio: 0.8,
                ),
                itemCount: topLevel.length,
                itemBuilder: (context, index) {
                  final category = topLevel[index];
                  return CategoryGridTile(
                    category: category,
                    onTap: () => openCategory(
                      context,
                      category,
                      hasChildren: parentIdsWithChildren.contains(category.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
