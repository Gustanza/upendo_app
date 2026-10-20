import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n.dart';
import '../models/attachment_model.dart';

String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

// ── Composer: picked-but-not-sent files ────────────────────────

/// Horizontal strip of picked files with a remove button on each.
class AttachmentDraftStrip extends StatelessWidget {
  final List<PendingAttachment> items;
  final void Function(int index)? onRemove;

  const AttachmentDraftStrip({super.key, required this.items, this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: item.type == Attachment.image
                      ? Image.file(File(item.localPath), fit: BoxFit.cover)
                      : _FileTile(
                          icon: switch (item.type) {
                            Attachment.video => Icons.play_circle_fill_rounded,
                            Attachment.audio => Icons.audiotrack_rounded,
                            _ => Icons.picture_as_pdf_rounded,
                          },
                          label: formatFileSize(item.size),
                        ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove!(i),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 11,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FileTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1D2E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Display: sent attachments ──────────────────────────────────

/// Renders a message's / post's attachments: an image grid, then one tile
/// per video, audio and PDF. Tapping opens a full-screen viewer (audio
/// plays inline).
class AttachmentsView extends StatelessWidget {
  final List<Attachment> attachments;
  // Light-on-dark styling, for the sender's own (blue) chat bubbles.
  final bool onDark;

  const AttachmentsView({super.key, required this.attachments, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final images = attachments.where((a) => a.type == Attachment.image).toList();
    final files = attachments.where((a) => a.type != Attachment.image).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.isNotEmpty) _ImageGrid(images: images),
        for (final f in files) ...[
          if (images.isNotEmpty || f != files.first) const SizedBox(height: 6),
          switch (f.type) {
            Attachment.video => _VideoTile(attachment: f),
            Attachment.audio => AudioAttachmentTile(attachment: f, onDark: onDark),
            _ => _PdfTile(attachment: f, onDark: onDark),
          },
        ],
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<Attachment> images;
  const _ImageGrid({required this.images});

  void _open(BuildContext context, int index) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageGalleryScreen(images: images, initialIndex: index),
        ),
      );

  Widget _image(BuildContext context, int i, {double? height}) => GestureDetector(
        onTap: () => _open(context, i),
        child: Image.network(
          images[i].url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Container(height: height ?? 120, color: Colors.grey.shade200),
          errorBuilder: (_, _, _) => Container(
            height: height ?? 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _image(context, 0, height: 200),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemBuilder: (context, i) => _image(context, i),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final Attachment attachment;
  const _VideoTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoViewerScreen(url: attachment.url)),
      ),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 52),
            if (attachment.size != null)
              Positioned(
                right: 10,
                bottom: 8,
                child: Text(
                  formatFileSize(attachment.size!),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PdfTile extends StatelessWidget {
  final Attachment attachment;
  final bool onDark;
  const _PdfTile({required this.attachment, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : const Color(0xFF1A1D2E);
    return Material(
      color: onDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              url: attachment.url,
              title: attachment.name ?? 'PDF',
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name ?? context.l10n.pdfDocument,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (attachment.size != null)
                      Text(
                        formatFileSize(attachment.size!),
                        style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 11),
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
}

/// Inline player for an audio attachment. video_player plays audio-only
/// files too, so no extra dependency is needed; the controller is only
/// created on first tap so a long chat doesn't open dozens of streams.
class AudioAttachmentTile extends StatefulWidget {
  final Attachment attachment;
  final bool onDark;
  const AudioAttachmentTile({super.key, required this.attachment, this.onDark = false});

  @override
  State<AudioAttachmentTile> createState() => _AudioAttachmentTileState();
}

class _AudioAttachmentTileState extends State<AudioAttachmentTile> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final existing = _controller;
    if (existing != null) {
      existing.value.isPlaying ? await existing.pause() : await existing.play();
      return;
    }
    setState(() => _loading = true);
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.attachment.url));
    try {
      await controller.initialize();
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final fg = widget.onDark ? Colors.white : const Color(0xFF1A1D2E);
    final controller = _controller;
    final playing = controller?.value.isPlaying ?? false;
    return Material(
      color: widget.onDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: _loading || _failed ? null : _toggle,
              icon: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _failed
                          ? Icons.error_outline_rounded
                          : playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                      size: 34,
                      color: _failed ? Colors.redAccent : const Color(0xFF8B2942),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _failed
                        ? context.l10n.audioPlaybackFailed
                        : (widget.attachment.name ?? context.l10n.audioClip),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (controller != null)
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(playedColor: Color(0xFF8B2942)),
                    )
                  else if (widget.attachment.size != null)
                    Text(
                      formatFileSize(widget.attachment.size!),
                      style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 11),
                    ),
                  if (controller != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${_fmt(controller.value.position)} / ${_fmt(controller.value.duration)}',
                        style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 10),
                      ),
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

// ── Full-screen viewers ────────────────────────────────────────

class ImageGalleryScreen extends StatelessWidget {
  final List<Attachment> images;
  final int initialIndex;
  const ImageGalleryScreen({super.key, required this.images, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(child: Image.network(images[i].url, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class VideoViewerScreen extends StatefulWidget {
  final String url;
  const VideoViewerScreen({super.key, required this.url});

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  late final VideoPlayerController _video =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _video.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: _video,
          autoPlay: true,
          aspectRatio: _video.value.aspectRatio,
        );
      });
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: _failed
            ? Text(context.l10n.videoPlaybackFailed,
                style: const TextStyle(color: Colors.white70))
            : _chewie == null
                ? const CircularProgressIndicator(color: Colors.white)
                : Chewie(controller: _chewie!),
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String url;
  final String title;
  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: SfPdfViewer.network(url),
    );
  }
}
