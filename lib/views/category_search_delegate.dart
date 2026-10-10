import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/category_navigation.dart';

class CategorySearchDelegate extends SearchDelegate<Category?> {
  final CategoryService _categoryService = CategoryService();

  @override
  String get searchFieldLabel => 'Tafuta categories...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildCategoryList(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildCategoryList(query);
  }

  Widget _buildCategoryList(String query) {
    if (query.isEmpty) {
      return const Center(child: Text('Andika jina la category kutafuta'));
    }

    return StreamBuilder<List<Category>>(
      stream: _categoryService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hitilafu: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];
        final lowerQuery = query.toLowerCase();
        final matches = categories
            .where((c) => c.name.toLowerCase().contains(lowerQuery))
            .toList();

        if (matches.isEmpty) {
          return const Center(child: Text('Category haijapatikana'));
        }

        // A child category never has children of its own (one level of
        // nesting only), so this only needs to know which categories are
        // *someone's* parent to decide leaf vs. parent at tap time.
        final parentIdsWithChildren =
            categories.map((c) => c.parentId).whereType<String>().toSet();

        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final category = matches[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: category.color,
                child: Icon(category.icon, color: Colors.white),
              ),
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  category.isProtected ? const Text('Imefungwa kwa password') : null,
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => openCategory(
                context,
                category,
                hasChildren: parentIdsWithChildren.contains(category.id),
              ),
            );
          },
        );
      },
    );
  }
}
