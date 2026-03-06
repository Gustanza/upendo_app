import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';

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
          color: const Color(0xFFF2F2F2),
          padding: const EdgeInsets.only(
            top: 60,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_back, color: Colors.black87),
              const SizedBox(height: 20),
              const Text(
                'Chagua Mada\nyako pendwa',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Jifunze kwa Video, Sauti, Soma na Muziki',
                style: TextStyle(fontSize: 14, color: Colors.black54),
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

              if (categories.isEmpty) {
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
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  // Using blue[800] as a reference for white icon theme
                  final bool isMainBlue = category.colorHex == 0xFF1565C0;

                  return Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            category.icon,
                            color: isMainBlue
                                ? Colors.white
                                : Colors.blue.shade800,
                            size: 45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
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
