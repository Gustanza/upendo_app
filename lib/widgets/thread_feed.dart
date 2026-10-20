import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/poll_model.dart';
import '../models/thread_post_model.dart';
import '../models/thread_scope.dart';
import '../services/thread_post_service.dart';
import '../utils/display_name.dart';
import '../utils/links.dart';
import '../utils/time_ago.dart';
import '../views/thread_compose_sheet.dart';
import '../views/thread_detail_screen.dart';
import 'attachment_views.dart';
import 'linkified_text.dart';
import 'poll_view.dart';
import 'thread_stats_row.dart';

/// Paginated feed of thread posts for one [ThreadScope] — the community
/// wall (ChatFragment), a subcategory's discussion feed, or a user group's
/// posts. Tapping a post opens ThreadDetailScreen for replies.
class ThreadFeed extends StatefulWidget {
  final ThreadScope scope;
  final EdgeInsets padding;

  const ThreadFeed({
    super.key,
    this.scope = ThreadScope.wall,
    this.padding = const EdgeInsets.all(15),
  });

  @override
  State<ThreadFeed> createState() => _ThreadFeedState();
}

class _ThreadFeedState extends State<ThreadFeed> {
  static const _pageSize = 15;

  late final ThreadPostService _postService = ThreadPostService(scope: widget.scope);
  final ScrollController _scrollController = ScrollController();

  final List<ThreadPostModel> _posts = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;

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
        limit: _pageSize,
      );
      if (result.posts.length < _pageSize) _hasMore = false;
      if (result.lastDoc != null) _lastDocument = result.lastDoc;

      if (!mounted) return;
      setState(() {
        _posts.addAll(result.posts);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error fetching thread posts: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _error = e;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _fetchPosts();
  }

  Future<void> _openCompose() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ThreadComposeSheet(scope: widget.scope),
    );
    if (posted == true) await _refresh();
  }

  Future<void> _openThread(ThreadPostModel post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThreadDetailScreen(post: post, scope: widget.scope),
      ),
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

  Future<void> _deletePost(ThreadPostModel post) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePostTitle),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _postService.deletePost(post.id);
      if (mounted) setState(() => _posts.remove(post));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.deleteFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        children: [
          _buildComposePrompt(),
          const SizedBox(height: 15),
          if (_error != null && _posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  context.l10n.errorWithDetails('$_error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else if (_posts.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  context.l10n.noPostsYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
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
              color: Colors.black.withValues(alpha: 0.05),
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
            Expanded(
              child: Text(
                context.l10n.whatsOnYourMind,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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
    final canDelete = widget.scope.canDelete(authorId: post.authorId, myUid: currentUid);
    final author = displayName(post.authorName, context.l10n);

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
              color: Colors.black.withValues(alpha: 0.05),
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
                    nameInitial(author),
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
                        author,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: context.l10n.delete,
                    onPressed: () => _deletePost(post),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  ),
              ],
            ),
            if (post.type == PollType.hostType) ...[
              const SizedBox(height: 10),
              PollView(
                poll: PollData.fromHostFields(
                  question: post.text,
                  pollType: post.pollType,
                  options: post.pollOptions,
                ),
                responsesRef: FirebaseFirestore.instance
                    .collection(widget.scope.postsPath)
                    .doc(post.id)
                    .collection('pollResponses'),
              ),
            ] else if (post.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              LinkifiedText(
                post.text,
                maxLines: 6,
                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
              ),
            ],
            if (post.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              AttachmentsView(attachments: post.attachments),
            ] else if (post.imageUrl != null) ...[
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
            for (final link in post.links)
              if (normalizeUrl(link) case final uri?) ...[
                const SizedBox(height: 8),
                LinkPreviewCard(url: uri),
              ],
            const SizedBox(height: 12),
            ThreadStatsRow(
              postId: post.id,
              postsPath: widget.scope.postsPath,
              likeCount: post.likeCount,
              commentCount: post.commentCount,
            ),
          ],
        ),
      ),
    );
  }
}
