import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/post_model.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.post.type == 'video' || widget.post.type == 'audio') {
      _initializePlayer();
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('Comments', style: TextStyle(color: Colors.grey)),
                ],
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
}
