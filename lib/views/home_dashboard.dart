import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upendo_app/views/explore_fragment.dart';
import 'package:upendo_app/views/chat_fragment.dart';
import 'package:upendo_app/views/post_detail_screen.dart';
import 'package:upendo_app/views/account_fragment.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/user_preferences.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 2; // Home is the middle item
  final PostService _postService = PostService();

  // Featured Posts (Somo la Leo)
  final List<PostModel> _featuredPosts = [];
  DocumentSnapshot? _lastFeaturedDoc;
  bool _isLoadingFeatured = false;
  bool _hasMoreFeatured = true;

  // Hot Posts (Mada za Moto)
  final List<PostModel> _hotPosts = [];
  DocumentSnapshot? _lastHotDoc;
  bool _isLoadingHot = false;
  bool _hasMoreHot = true;

  final ScrollController _hotScrollController = ScrollController();
  final UserPreferences _userPreferences = UserPreferences();
  String _userName = 'Mtumiaji'; // Default "User" in Swahili

  @override
  void initState() {
    super.initState();
    _fetchFeaturedPosts();
    _fetchHotPosts();
    _loadUserData();
    _hotScrollController.addListener(_onHotScroll);
  }

  Future<void> _loadUserData() async {
    final user = await _userPreferences.getUserData();
    if (user != null && mounted) {
      setState(() {
        _userName = user.fullName;
      });
    }
  }

  @override
  void dispose() {
    _hotScrollController.dispose();
    super.dispose();
  }

  void _onHotScroll() {
    if (_hotScrollController.position.pixels >=
            _hotScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingHot &&
        _hasMoreHot) {
      _fetchHotPosts();
    }
  }

  Future<void> _fetchFeaturedPosts() async {
    if (_isLoadingFeatured || !_hasMoreFeatured) return;

    setState(() => _isLoadingFeatured = true);

    try {
      final posts = await _postService.getFeaturedPosts(
        startAfter: _lastFeaturedDoc,
        limit: 10,
      );
      if (posts.length < 10) _hasMoreFeatured = false;

      if (posts.isNotEmpty) {
        final lastDoc = await _postService.getLastFeaturedDoc(_lastFeaturedDoc);
        _lastFeaturedDoc = lastDoc;
      }

      setState(() {
        _featuredPosts.addAll(posts);
        _isLoadingFeatured = false;
      });
    } catch (e) {
      debugPrint('Error fetching featured posts: $e');
      setState(() => _isLoadingFeatured = false);
    }
  }

  Future<void> _fetchHotPosts() async {
    if (_isLoadingHot || !_hasMoreHot) return;

    setState(() => _isLoadingHot = true);

    try {
      final posts = await _postService.getHotPosts(
        startAfter: _lastHotDoc,
        limit: 10,
      );
      if (posts.length < 10) _hasMoreHot = false;

      if (posts.isNotEmpty) {
        final lastDoc = await _postService.getLastHotDoc(_lastHotDoc);
        _lastHotDoc = lastDoc;
      }

      setState(() {
        _hotPosts.addAll(posts);
        _isLoadingHot = false;
      });
    } catch (e) {
      debugPrint('Error fetching hot posts: $e');
      setState(() => _isLoadingHot = false);
    }
  }

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
          const ChatFragment(), // 3: Chat
          const AccountFragment(), // 4: Account
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habari $_userName,',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Karibu tujifunze kitu kipya leo',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
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
    if (_featuredPosts.isEmpty && _isLoadingFeatured) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_featuredPosts.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('Hakuna masomo kwa sasa.')),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: _featuredPosts.length + (_hasMoreFeatured ? 1 : 0),
        controller: PageController(viewportFraction: 0.85),
        onPageChanged: (index) {
          if (index == _featuredPosts.length - 1 && _hasMoreFeatured) {
            _fetchFeaturedPosts();
          }
        },
        itemBuilder: (context, index) {
          if (index == _featuredPosts.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = _featuredPosts[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: post),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    image: DecorationImage(
                      image: post.thumbnail.isNotEmpty
                          ? NetworkImage(post.thumbnail)
                          : const AssetImage('assets/images/g272.png')
                                as ImageProvider,
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
                          children: [
                            Text(
                              post.title,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              post.subtitle,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicsSlider() {
    if (_hotPosts.isEmpty && _isLoadingHot) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hotPosts.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Hakuna mada kwa sasa.')),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        controller: _hotScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _hotPosts.length + (_hasMoreHot ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _hotPosts.length) {
            return const SizedBox(
              width: 130,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = _hotPosts[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: post),
                  ),
                ),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 190, // Increased height for better prominence
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: post.thumbnail.isNotEmpty
                                ? NetworkImage(post.thumbnail)
                                : const AssetImage('assets/images/cover.jpg')
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
