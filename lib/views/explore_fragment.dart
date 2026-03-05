import 'package:flutter/material.dart';

class ExploreFragment extends StatelessWidget {
  const ExploreFragment({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      {
        'title': 'Vijana',
        'icon': Icons.people_outline,
        'color': Colors.blue.shade800,
      },
      {
        'title': 'Wachumba',
        'icon': Icons.favorite_outline,
        'color': Colors.blue.shade100,
      },
      {'title': 'Wanandoa', 'icon': Icons.wc, 'color': Colors.blue.shade100},
      {
        'title': 'Malezi',
        'icon': Icons.family_restroom,
        'color': Colors.blue.shade100,
      },
      {
        'title': 'Migogoro',
        'icon': Icons.forum_outlined,
        'color': Colors.blue.shade800,
      },
      {
        'title': 'Malengo',
        'icon': Icons.directions_bike,
        'color': Colors.blue.shade100,
      },
      {
        'title': 'Kuachana',
        'icon': Icons.heart_broken_outlined,
        'color': Colors.blue.shade100,
      },
      {
        'title': 'Dini & Tamaduni',
        'icon': Icons.groups_3_outlined,
        'color': Colors.blue.shade100,
      },
      {
        'title': 'Afya ya Akili',
        'icon': Icons.psychology_outlined,
        'color': Colors.blue.shade100,
      },
      {'title': 'Mjane/Mgane', 'icon': null, 'color': Colors.grey.shade200},
      {'title': 'Single Parent', 'icon': null, 'color': Colors.grey.shade200},
      {'title': 'Wazee', 'icon': null, 'color': Colors.grey.shade200},
    ];

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
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 25,
              childAspectRatio: 0.8,
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final bool isMainBlue = topic['color'] == Colors.blue.shade800;

              return Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: topic['color'] as Color,
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
                      child: topic['icon'] != null
                          ? Icon(
                              topic['icon'] as IconData,
                              color: isMainBlue
                                  ? Colors.white
                                  : Colors.blue.shade800,
                              size: 45,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topic['title'] as String,
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
          ),
        ),
      ],
    );
  }
}
