import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thread_post_model.dart';
import '../services/thread_post_service.dart';
import '../utils/time_ago.dart';
import '../widgets/thread_stats_row.dart';
import 'thread_compose_sheet.dart';
import 'thread_detail_screen.dart';

class ChatFragment extends StatefulWidget {
  const ChatFragment({super.key});

  @override
  State<ChatFragment> createState() => _ChatFragmentState();
}

class _ChatFragmentState extends State<ChatFragment> {
  final ThreadPostService _postService = ThreadPostService();
  final ScrollController _scrollController = ScrollController();

  final List<ThreadPostModel> _posts = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _postService.getFeed(
        startAfter: _lastDocument,
        limit: 15,
      );
      if (result.posts.length < 15) _hasMore = false;
      if (result.lastDoc != null) _lastDocument = result.lastDoc;

      setState(() {
        _posts.addAll(result.posts);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching thread posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openCompose() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ThreadComposeSheet(),
    );
    if (posted == true) {
      setState(() {
        _posts.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      await _fetchPosts();
    }
  }

  Future<void> _openThread(ThreadPostModel post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ThreadDetailScreen(post: post)),
    );
    final updated = await _postService.getPostById(post.id);
    if (!mounted) return;
    setState(() {
      if (updated == null) {
        _posts.removeWhere((p) => p.id == post.id);
      } else {
        final index = _posts.indexWhere((p) => p.id == updated.id);
        if (index != -1) _posts[index] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 80,
            left: 25,
            right: 25,
            bottom: 40,
          ),
          child: const Center(
            child: Text(
              'Ukuta wa Jumuiya',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Feed
        Expanded(
          child: _posts.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _posts.clear();
                      _lastDocument = null;
                      _hasMore = true;
                    });
                    await _fetchPosts();
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15),
                    children: [
                      _buildComposePrompt(),
                      const SizedBox(height: 15),
                      if (_posts.isEmpty && !_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Hakuna chapisho bado. Kuwa wa kwanza kuchapisha!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ..._posts.map(_buildPostCard),
                      if (_hasMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildComposePrompt() {
    return GestureDetector(
      onTap: _openCompose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8EAF6),
              child: Icon(Icons.person, color: Color(0xFF0077C2), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unafikiria nini?',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const Icon(Icons.image_outlined, color: Color(0xFF0077C2)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(ThreadPostModel post) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = post.authorId == currentUid;

    return GestureDetector(
      onTap: () => _openThread(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      await _postService.deletePost(post.id);
                      if (mounted) setState(() => _posts.remove(post));
                    },
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.text,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ThreadStatsRow(
              postId: post.id,
              likeCount: post.likeCount,
              commentCount: post.commentCount,
            ),
          ],
        ),
      ),
    );
  }
}
