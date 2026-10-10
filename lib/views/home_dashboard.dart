import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:upendo_app/views/explore_fragment.dart';
import 'package:upendo_app/views/chat_fragment.dart';
import 'package:upendo_app/views/post_detail_screen.dart';
import 'package:upendo_app/views/account_fragment.dart';
import 'package:upendo_app/views/post_search_delegate.dart';
import 'package:upendo_app/views/saved_fragment.dart';
import 'package:upendo_app/views/notifications_screen.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../services/post_service.dart';
import '../services/user_preferences.dart';
import '../services/notification_service.dart';
import '../widgets/post_stats_row.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 2;
  final PostService _postService = PostService();

  final List<PostModel> _featuredPosts = [];
  DocumentSnapshot? _lastFeaturedDoc;
  bool _isLoadingFeatured = false;
  bool _hasMoreFeatured = true;
  int _currentFeaturedPage = 0;

  final List<PostModel> _hotPosts = [];
  DocumentSnapshot? _lastHotDoc;
  bool _isLoadingHot = false;
  bool _hasMoreHot = true;

  final ScrollController _hotScrollController = ScrollController();
  final UserPreferences _userPreferences = UserPreferences();
  String _userName = 'Mtumiaji';
  final GlobalKey<SavedFragmentState> _savedFragmentKey =
      GlobalKey<SavedFragmentState>();

  int _notifLastSeenMs = 0;
  Stream<List<AppNotification>>? _notifStream;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedPosts();
    _fetchHotPosts();
    _loadUserData();
    _initNotifications();
    _hotScrollController.addListener(_onHotScroll);
    _checkForUpdate();
  }

  Future<void> _loadUserData() async {
    final user = await _userPreferences.getUserData();
    if (user != null && mounted) {
      setState(() => _userName = user.fullName);
    }
  }

  Future<void> _initNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifLastSeenMs = prefs.getInt('notif_last_seen') ?? 0;
      _notifStream = NotificationService().getNotifications();
    });
  }

  Future<void> _checkForUpdate() async {
    if (!kReleaseMode) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _hotScrollController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == 1) _savedFragmentKey.currentState?.fetchSavedPosts();
    if (mounted) setState(() => _currentIndex = index);
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

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ExploreFragment(),
          SavedFragment(key: _savedFragmentKey),
          _buildHomeFragment(),
          const ChatFragment(),
          const AccountFragment(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      extendBody: true,
    );
  }

  Widget _buildHomeFragment() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          _buildSectionHeader('Somo la Leo!', onMore: () => _switchTab(0)),
          const SizedBox(height: 14),
          _buildLessonsCarousel(),
          const SizedBox(height: 8),
          _buildPageDots(),
          const SizedBox(height: 28),
          _buildSectionHeader('Mada za Moto!', onMore: () => _switchTab(0)),
          const SizedBox(height: 14),
          _buildTopicsSlider(),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habari, $_userName 👋',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Karibu tujifunze kitu kipya leo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<List<AppNotification>>(
                      stream: _notifStream,
                      builder: (context, snapshot) {
                        final hasUnread = (snapshot.data ?? []).any(
                          (n) => (n.createdAt?.millisecondsSinceEpoch ?? 0) > _notifLastSeenMs,
                        );
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                            final prefs = await SharedPreferences.getInstance();
                            if (mounted) {
                              setState(() => _notifLastSeenMs =
                                  prefs.getInt('notif_last_seen') ?? 0);
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(60),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // Search bar
                GestureDetector(
                  onTap: () => showSearch(
                    context: context,
                    delegate: PostSearchDelegate(),
                  ),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: Color(0xFF0077C2), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tafuta masomo, mada...',
                            style: TextStyle(
                              color: Color(0xFFADB5BD),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tafuta',
                            style: TextStyle(
                              color: Color(0xFF0077C2),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────

  Widget _buildSectionHeader(String title, {required VoidCallback onMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0077C2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ona zaidi →',
              style: TextStyle(
                color: Color(0xFF0077C2),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Featured carousel ────────────────────────────────────────

  Widget _buildLessonsCarousel() {
    if (_featuredPosts.isEmpty && _isLoadingFeatured) {
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, i) => Container(
            width: MediaQuery.of(context).size.width * 0.82,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE0E6EF),
              highlightColor: const Color(0xFFF4F7FC),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_featuredPosts.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Hakuna masomo kwa sasa.')),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: _featuredPosts.length + (_hasMoreFeatured ? 1 : 0),
        controller: PageController(viewportFraction: 0.88),
        onPageChanged: (index) {
          if (index < _featuredPosts.length) {
            setState(() => _currentFeaturedPage = index);
          }
          if (index == _featuredPosts.length - 1 && _hasMoreFeatured) {
            _fetchFeaturedPosts();
          }
        },
        itemBuilder: (context, index) {
          if (index == _featuredPosts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildFeaturedCard(_featuredPosts[index]);
        },
      ),
    );
  }

  Future<void> _openPostAndRefresh(PostModel post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
    final updated = await _postService.getPostById(post.id);
    if (updated == null || !mounted) return;
    setState(() {
      final fIndex = _featuredPosts.indexWhere((p) => p.id == updated.id);
      if (fIndex != -1) _featuredPosts[fIndex] = updated;
      final hIndex = _hotPosts.indexWhere((p) => p.id == updated.id);
      if (hIndex != -1) _hotPosts[hIndex] = updated;
    });
  }

  Widget _buildFeaturedCard(PostModel post) {
    return GestureDetector(
      onTap: () => _openPostAndRefresh(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00008B).withAlpha(50),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (post.thumbnail.isNotEmpty)
                Image.network(
                  post.thumbnail,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E6EF),
                      highlightColor: const Color(0xFFF4F7FC),
                      child: Container(color: Colors.white),
                    );
                  },
                )
              else
                Image.asset('assets/images/g272.png', fit: BoxFit.cover),
              // Bottom-up gradient for text readability
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD00008B)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
              // "Soma" chip — top right
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Somo',
                    style: TextStyle(
                      color: Color(0xFF0077C2),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Title + subtitle — bottom left
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    if (post.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    PostStatsRow(
                      postId: post.id,
                      likeCount: post.likeCount,
                      commentCount: post.commentCount,
                      iconColor: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page dots ────────────────────────────────────────────────

  Widget _buildPageDots() {
    if (_featuredPosts.length <= 1) return const SizedBox.shrink();
    final dotCount = _featuredPosts.length.clamp(0, 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotCount, (i) {
        final isActive = i == _currentFeaturedPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF0077C2)
                : const Color(0xFFD0D8E4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Hot topics horizontal list ───────────────────────────────

  Widget _buildTopicsSlider() {
    if (_hotPosts.isEmpty && _isLoadingHot) {
      return SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, i) => Shimmer.fromColors(
            baseColor: const Color(0xFFE0E6EF),
            highlightColor: const Color(0xFFF4F7FC),
            child: Container(
              width: 148,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      );
    }

    if (_hotPosts.isEmpty) {
      return const SizedBox(
        height: 230,
        child: Center(child: Text('Hakuna mada kwa sasa.')),
      );
    }

    return SizedBox(
      height: 230,
      child: ListView.builder(
        controller: _hotScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _hotPosts.length + (_hasMoreHot ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _hotPosts.length) {
            return const SizedBox(
              width: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildHotCard(_hotPosts[index]);
        },
      ),
    );
  }

  Widget _buildHotCard(PostModel post) {
    return GestureDetector(
      onTap: () => _openPostAndRefresh(post),
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
              child: Stack(
                children: [
                  if (post.thumbnail.isNotEmpty)
                    Image.network(
                      post.thumbnail,
                      height: 155,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: const Color(0xFFE0E6EF),
                          highlightColor: const Color(0xFFF4F7FC),
                          child: Container(
                            height: 155,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      height: 155,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0D1B4B),
                            Color(0xFF00008B),
                            Color(0xFF1A0050),
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(18),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Subtle bottom gradient on image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x8000008B)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2E),
                        height: 1.35,
                      ),
                    ),
                    PostStatsRow(
                      postId: post.id,
                      likeCount: post.likeCount,
                      commentCount: post.commentCount,
                      iconColor: Colors.grey,
                      fontSize: 11,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.explore_outlined, Icons.explore, 'Explore'),
            _buildNavItem(
                1, Icons.bookmark_border, Icons.bookmark, 'Saved'),
            _buildCenterHomeItem(),
            _buildNavItem(
                3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
            _buildNavItem(
                4, Icons.person_outline, Icons.person, 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF0077C2) : const Color(0xFFADB5BD),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF0077C2)
                    : const Color(0xFFADB5BD),
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF0077C2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHomeItem() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _switchTab(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [const Color(0xFF00AEEF), const Color(0xFF0055CC)]
                : [const Color(0xFF4488DD), const Color(0xFF0044AA)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0077C2).withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isSelected ? Icons.home_rounded : Icons.home_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
