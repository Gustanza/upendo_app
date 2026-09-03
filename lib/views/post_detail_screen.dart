import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/user_preferences.dart';
import '../services/post_interaction_service.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlayerInitialized = false;
  final UserPreferences _userPreferences = UserPreferences();
  final PostInteractionService _interactionService = PostInteractionService();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == 'video' || widget.post.type == 'audio') {
      _initializePlayer();
    }
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final saved = await _userPreferences.isPostSaved(widget.post.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSave() async {
    await _userPreferences.toggleSavePost(widget.post.id);
    final saved = await _userPreferences.isPostSaved(widget.post.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Imehifadhiwa!' : 'Imeondolewa!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.fileUrl),
    );
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: widget.post.type == 'video'
          ? _videoPlayerController!.value.aspectRatio
          : 16 / 9,
      allowFullScreen: widget.post.type == 'video',
      showControls: true,
      isLive: false,
      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    setState(() {
      _isPlayerInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPdf = widget.post.type == 'pdf';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          if (isPdf)
            Expanded(child: SfPdfViewer.network(widget.post.fileUrl))
          else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildMediaPlayer(), _buildContent()],
                ),
              ),
            ),
            _buildBottomSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              image: widget.post.thumbnail.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.post.thumbnail),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.post.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleSave,
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlayer() {
    if (widget.post.type == 'pdf') {
      return const SizedBox.shrink();
    }

    if (!_isPlayerInitialized) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.post.type == 'video') {
      return SizedBox(
        height: 250,
        child: Chewie(controller: _chewieController!),
      );
    }

    if (widget.post.type == 'audio') {
      return _buildAudioPlayerUI();
    }

    return const SizedBox.shrink();
  }

  Widget _buildAudioPlayerUI() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: Colors.blue.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wimbo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      widget.post.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_videoPlayerController!.value.isPlaying) {
                      _videoPlayerController!.pause();
                    } else {
                      _videoPlayerController!.play();
                    }
                  });
                },
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 40,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          VideoProgressIndicator(
            _videoPlayerController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.blue.shade800,
              bufferedColor: Colors.blue.shade100,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
          _buildLikeButton(),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _openComments,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    StreamBuilder<int>(
                      stream: _interactionService.commentCount(widget.post.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? widget.post.commentCount;
                        return Text(
                          count > 0 ? 'Comments ($count)' : 'Comments',
                          style: const TextStyle(color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_note, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return StreamBuilder<bool>(
      stream: _interactionService.likedByMe(widget.post.id),
      builder: (context, likedSnapshot) {
        final isLiked = likedSnapshot.data ?? false;
        return StreamBuilder<int>(
          stream: _interactionService.likeCount(widget.post.id),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? widget.post.likeCount;
            return GestureDetector(
              onTap: () => _interactionService.toggleLike(widget.post.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isLiked
                      ? const Color(0xFFFFE5EA)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isLiked ? Colors.redAccent : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: isLiked ? Colors.redAccent : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(
        postId: widget.post.id,
        interactionService: _interactionService,
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final PostInteractionService interactionService;

  const _CommentsSheet({
    required this.postId,
    required this.interactionService,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await widget.interactionService.addComment(widget.postId, text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: widget.interactionService.getComments(widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text(
                            'No comments yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isOwner = comment.userId == currentUid;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8EAF6),
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Color(0xFF0077C2)),
                          ),
                        ),
                        title: Text(
                          comment.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(comment.text),
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.grey),
                                onPressed: () => widget.interactionService
                                    .deleteComment(widget.postId, comment.id),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Andika maoni...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
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
                    onPressed: _isSending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
