import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/l10n.dart';
import '../models/poll_model.dart';
import '../models/thread_post_model.dart';
import '../models/thread_reply_model.dart';
import '../models/thread_scope.dart';
import '../services/conversation_service.dart';
import '../services/thread_interaction_service.dart';
import '../services/thread_post_service.dart';
import '../utils/display_name.dart';
import '../utils/links.dart';
import '../utils/time_ago.dart';
import '../widgets/attachment_views.dart';
import '../widgets/linkified_text.dart';
import '../widgets/poll_view.dart';
import '../widgets/thread_stats_row.dart';
import 'conversation_screen.dart';

class ThreadDetailScreen extends StatefulWidget {
  final ThreadPostModel post;
  // Which feed the post belongs to — the community wall unless opened from
  // a subcategory or user-group feed.
  final ThreadScope scope;
  const ThreadDetailScreen({
    super.key,
    required this.post,
    this.scope = ThreadScope.wall,
  });

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  late final ThreadInteractionService _interactionService =
      ThreadInteractionService(postsPath: widget.scope.postsPath);
  late final ThreadPostService _postService = ThreadPostService(scope: widget.scope);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.sendFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDeletePost() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePostTitle),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _postService.deletePost(widget.post.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _messageAuthor() async {
    final otherName = displayName(widget.post.authorName, context.l10n);
    final conversationId = await ConversationService().getOrCreateConversation(
      otherUid: widget.post.authorId,
      otherName: widget.post.authorName,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversationId: conversationId,
          otherName: otherName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isAuthor = widget.post.authorId == currentUid;
    final canDelete =
        widget.scope.canDelete(authorId: widget.post.authorId, myUid: currentUid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        title: Text(context.l10n.discussion),
        actions: [
          if (!isAuthor)
            IconButton(
              onPressed: _messageAuthor,
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: context.l10n.sendMessage,
            ),
          if (canDelete)
            IconButton(
              onPressed: _confirmDeletePost,
              tooltip: context.l10n.delete,
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            context.l10n.noRepliesYet,
                            style: const TextStyle(color: Colors.grey),
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
    final author = displayName(post.authorName, context.l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                nameInitial(author),
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
                    author,
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
        if (post.type == PollType.hostType) ...[
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          LinkifiedText(
            post.text,
            style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black87),
          ),
        ],
        if (post.attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          AttachmentsView(attachments: post.attachments),
        ] else if (post.imageUrl != null) ...[
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
        for (final link in post.links)
          if (normalizeUrl(link) case final uri?) ...[
            const SizedBox(height: 10),
            LinkPreviewCard(url: uri),
          ],
        const SizedBox(height: 14),
        ThreadStatsRow(
          postId: post.id,
          postsPath: widget.scope.postsPath,
          likeCount: post.likeCount,
          commentCount: post.commentCount,
          iconColor: Colors.grey.shade600,
          fontSize: 13,
        ),
      ],
    );
  }

  Widget _buildReplyTile(ThreadReplyModel reply, String? currentUid) {
    final canDelete = widget.scope.canDelete(authorId: reply.authorId, myUid: currentUid);
    final author = displayName(reply.authorName, context.l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8EAF6),
            child: Text(
              nameInitial(author),
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
                      author,
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
                LinkifiedText(
                  reply.text,
                  style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.black87),
                ),
              ],
            ),
          ),
          if (canDelete)
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
              color: Colors.black.withValues(alpha: 0.05),
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
                // Matches the replies text cap in firestore.rules.
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: context.l10n.writeReplyHint,
                  counterText: '',
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
