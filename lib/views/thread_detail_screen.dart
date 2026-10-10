import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thread_post_model.dart';
import '../models/thread_reply_model.dart';
import '../services/thread_interaction_service.dart';
import '../services/thread_post_service.dart';
import '../utils/time_ago.dart';
import '../widgets/thread_stats_row.dart';

class ThreadDetailScreen extends StatefulWidget {
  final ThreadPostModel post;
  const ThreadDetailScreen({super.key, required this.post});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final ThreadInteractionService _interactionService = ThreadInteractionService();
  final ThreadPostService _postService = ThreadPostService();
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await _interactionService.addReply(widget.post.id, text);
      _replyController.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa chapisho?'),
        content: const Text('Hatua hii haiwezi kutenduliwa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _postService.deletePost(widget.post.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = widget.post.authorId == currentUid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        title: const Text('Mazungumzo'),
        actions: [
          if (isOwner)
            IconButton(
              onPressed: _confirmDeletePost,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPostHeader(),
                const Divider(height: 32),
                StreamBuilder<List<ThreadReplyModel>>(
                  stream: _interactionService.getReplies(widget.post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final replies = snapshot.data ?? [];
                    if (replies.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Hakuna majibu bado. Kuwa wa kwanza!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: replies
                          .map((reply) => _buildReplyTile(reply, currentUid))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    timeAgo(post.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (post.text.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            post.text,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
        if (post.imageUrl != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 14),
        ThreadStatsRow(
          postId: post.id,
          likeCount: post.likeCount,
          commentCount: post.commentCount,
          iconColor: Colors.grey.shade600,
          fontSize: 13,
        ),
      ],
    );
  }

  Widget _buildReplyTile(ThreadReplyModel reply, String? currentUid) {
    final isOwner = reply.authorId == currentUid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8EAF6),
            child: Text(
              reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF0077C2), fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(reply.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(reply.text, style: const TextStyle(fontSize: 14, height: 1.3)),
              ],
            ),
          ),
          if (isOwner)
            GestureDetector(
              onTap: () => _interactionService.deleteReply(widget.post.id, reply.id),
              child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Andika jibu...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Color(0xFF0077C2)),
              onPressed: _isSending ? null : _sendReply,
            ),
          ],
        ),
      ),
    );
  }
}
