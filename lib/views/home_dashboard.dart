import 'package:flutter/material.dart';
import 'package:upendo_app/views/explore_fragment.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 2; // Home is the middle item

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ExploreFragment(), // 0: Explore
          _buildEmptyFragment('Saved Content'), // 1: Saved
          _buildHomeFragment(), // 2: Home
          _buildEmptyFragment('Chat Messages'), // 3: Chat
          _buildEmptyFragment('Your Account'), // 4: Account
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true,
    );
  }

  Widget _buildEmptyFragment(String title) {
    return Center(
      child: Text(
        '$title Screen',
        style: const TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildHomeFragment() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          _buildHeader(),
          const SizedBox(height: 20),

          // Somo la Leo! Section
          _buildSectionHeader('Somo la Leo!'),
          const SizedBox(height: 10),
          _buildLessonsCarousel(),

          const SizedBox(height: 20),

          // Mada za Moto! Section
          _buildSectionHeader('Mada za Moto!'),
          const SizedBox(height: 10),
          _buildTopicsSlider(),

          const SizedBox(height: 100), // Bottom padding for navigation bar
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Habari John Peter,',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Karibu tujifunze kitu kipya leo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const Icon(
                Icons.signal_cellular_alt,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Search Bar
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  'Tafuta',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.chevron_left, color: Colors.blueAccent),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildLessonsCarousel() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: 3,
        controller: PageController(viewportFraction: 0.85),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              image: const DecorationImage(
                image: AssetImage(
                  'assets/images/g272.png',
                ), // Using existing asset
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.blue.shade900.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        'Siri ya Ndoa\nInayodumu',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Mambo Kumi (10)\nya kuzingatia ili ndoa\nyako idumu.',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicsSlider() {
    final topics = [
      {'title': 'Malezi ya Watoto', 'image': 'assets/images/cover.jpg'},
      {'title': 'Kutatua Matatizo', 'image': 'assets/images/cover.jpg'},
      {'title': 'Upendo Uzeeni', 'image': 'assets/images/cover.jpg'},
    ];

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return Container(
            width: 130,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(topics[index]['image']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  topics[index]['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.search_outlined, 'Explore'),
          _buildNavItem(1, Icons.file_present_outlined, 'Saved'),
          _buildCenterHomeItem(),
          _buildNavItem(3, Icons.chat_bubble_outline, 'Chat'),
          _buildNavItem(4, Icons.person_outline, 'Account'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 26),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterHomeItem() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        height: 50,
        width: 50,
        decoration: const BoxDecoration(
          color: Color(0xFF0077C2), // Home Blue
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.home, color: Colors.white, size: 28),
      ),
    );
  }
}
