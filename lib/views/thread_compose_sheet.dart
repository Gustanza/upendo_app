import 'package:flutter/material.dart';
import '../models/attachment_model.dart';
import '../models/poll_model.dart';
import '../services/attachment_service.dart';
import '../services/thread_post_service.dart';
import '../widgets/attachment_views.dart';
import '../widgets/poll_composer_card.dart';

class ThreadComposeSheet extends StatefulWidget {
  const ThreadComposeSheet({super.key});

  @override
  State<ThreadComposeSheet> createState() => _ThreadComposeSheetState();
}

class _ThreadComposeSheetState extends State<ThreadComposeSheet> {
  // Matches the threadPosts text cap in firestore.rules.
  static const maxTextLength = 1000;
  static const _maxImages = 5;
  static const _maxVideoDuration = Duration(minutes: 10);

  final ThreadPostService _postService = ThreadPostService();
  final AttachmentService _attachmentService = AttachmentService();
  final TextEditingController _textController = TextEditingController();
  final List<PendingAttachment> _attachments = [];
  PollDraft? _pollDraft;
  bool _isPosting = false;
  bool _isCheckingVideo = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int _countOf(String type) => _attachments.where((a) => a.type == type).length;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImages() async {
    final room = _maxImages - _countOf(Attachment.image);
    if (room <= 0) return _snack('Unaweza kuweka picha 5 tu kwa pamoja');
    final picked = await _attachmentService.pickImages(room);
    if (picked.isNotEmpty && mounted) setState(() => _attachments.addAll(picked));
  }

  Future<void> _pickVideo() async {
    if (_countOf(Attachment.video) > 0) {
      return _snack('Unaweza kuweka video moja tu kwenye chapisho');
    }
    final picked = await _attachmentService.pickVideo();
    if (picked == null || !mounted) return;

    setState(() => _isCheckingVideo = true);
    final duration = await _attachmentService.videoDuration(picked.localPath);
    if (!mounted) return;
    setState(() => _isCheckingVideo = false);

    if (duration == null) return _snack('Imeshindwa kusoma video hii');
    if (duration > _maxVideoDuration) {
      return _snack('Video isizidi dakika 10');
    }
    setState(() => _attachments.add(picked));
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachments.isEmpty && _pollDraft == null) return;

    String postText = text;
    PollData? pollData;
    if (_pollDraft != null) {
      pollData = _pollDraft!.build();
      if (pollData == null) {
        _snack('Jaza swali la kura kikamilifu');
        return;
      }
      postText = pollData.question;
    }

    setState(() {
      _isPosting = true;
      _uploadProgress = _attachments.isEmpty ? null : 0;
    });
    try {
      await _postService.createPost(
        text: postText,
        attachments: pollData == null ? _attachments : const [],
        poll: pollData,
        onUploadProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _uploadProgress = null;
        });
        _snack('Imeshindwa kutuma: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isPosting || _isCheckingVideo;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Andika Chapisho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (_pollDraft == null)
            TextField(
              controller: _textController,
              maxLines: 6,
              minLines: 3,
              maxLength: maxTextLength,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Unafikiria nini?',
                border: InputBorder.none,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              // Up to 15 options won't fit on screen — scroll within a cap.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: PollComposerCard(
                    draft: _pollDraft!,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            ),
          if (_pollDraft == null && _attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AttachmentDraftStrip(
                items: _attachments,
                onRemove: busy ? null : (i) => setState(() => _attachments.removeAt(i)),
              ),
            ),
          if (_uploadProgress != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: LinearProgressIndicator(value: _uploadProgress)),
                  const SizedBox(width: 8),
                  Text(
                    'Inapakia ${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (_pollDraft == null) ...[
                IconButton(
                  tooltip: 'Picha (hadi 5)',
                  onPressed: busy ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined, color: Color(0xFF0077C2)),
                ),
                IconButton(
                  tooltip: 'Video (isizidi dakika 10)',
                  onPressed: busy ? null : _pickVideo,
                  icon: _isCheckingVideo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.videocam_outlined, color: Color(0xFF0077C2)),
                ),
              ],
              IconButton(
                onPressed: busy
                    ? null
                    : () => setState(
                          () => _pollDraft = _pollDraft == null ? PollDraft() : null,
                        ),
                icon: Icon(
                  Icons.poll_outlined,
                  color: _pollDraft == null ? const Color(0xFF0077C2) : Colors.white,
                ),
                style: _pollDraft == null
                    ? null
                    : IconButton.styleFrom(backgroundColor: const Color(0xFF0077C2)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077C2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Chapisha'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
