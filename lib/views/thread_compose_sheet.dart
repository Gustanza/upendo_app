import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/attachment_model.dart';
import '../models/poll_model.dart';
import '../models/thread_scope.dart';
import '../services/attachment_service.dart';
import '../services/thread_post_service.dart';
import '../utils/links.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/attachment_views.dart';
import '../widgets/poll_composer_card.dart';

/// Composer for a thread post in any feed (community wall, subcategory feed
/// or user group). What can be attached comes from [scope]'s MediaLimits —
/// the wall allows images + a ≤10 min video, subcategory/group feeds add
/// PDFs and audio with a ≤5 min video, and groups also allow links.
class ThreadComposeSheet extends StatefulWidget {
  final ThreadScope scope;
  const ThreadComposeSheet({super.key, this.scope = ThreadScope.wall});

  @override
  State<ThreadComposeSheet> createState() => _ThreadComposeSheetState();
}

class _ThreadComposeSheetState extends State<ThreadComposeSheet> {
  // Matches the text cap in firestore.rules for every posts collection.
  static const maxTextLength = ThreadScope.maxTextLength;

  late final ThreadPostService _postService = ThreadPostService(scope: widget.scope);
  final AttachmentService _attachmentService = AttachmentService();
  final TextEditingController _textController = TextEditingController();
  final List<PendingAttachment> _attachments = [];
  final List<Uri> _links = [];
  PollDraft? _pollDraft;
  bool _isPosting = false;
  bool _isCheckingVideo = false;
  double? _uploadProgress;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick(String type) async {
    final picked = await pickValidatedAttachments(
      context,
      type: type,
      limits: widget.scope.limits,
      current: _attachments,
      service: _attachmentService,
      onCheckingVideo: (checking) {
        if (mounted) setState(() => _isCheckingVideo = checking);
      },
    );
    if (picked.isNotEmpty && mounted) setState(() => _attachments.addAll(picked));
  }

  Future<void> _addLink() async {
    final l10n = context.l10n;
    if (_links.length >= ThreadScope.maxLinks) {
      return _snack(l10n.linksMax(ThreadScope.maxLinks));
    }
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addLink),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: l10n.linkHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || !mounted) return;
    final uri = normalizeUrl(raw);
    if (uri == null) return _snack(l10n.invalidLink);
    setState(() => _links.add(uri));
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final text = _textController.text.trim();
    if (text.isEmpty && _attachments.isEmpty && _links.isEmpty && _pollDraft == null) {
      return;
    }

    String postText = text;
    PollData? pollData;
    if (_pollDraft != null) {
      pollData = _pollDraft!.build();
      if (pollData == null) {
        _snack(l10n.pollIncomplete);
        return;
      }
      postText = pollData.question;
    }

    setState(() {
      _isPosting = true;
      _uploadProgress = _attachments.isEmpty || pollData != null ? null : 0;
    });
    try {
      await _postService.createPost(
        text: postText,
        attachments: pollData == null ? _attachments : const [],
        links: pollData == null ? _links.map((u) => u.toString()).toList() : const [],
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
        _snack(l10n.sendFailed('$e'));
      }
    }
  }

  Widget _toolButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = const Color(0xFF0077C2),
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final limits = widget.scope.limits;
    final busy = _isPosting || _isCheckingVideo;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.writePost,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                decoration: InputDecoration(
                  hintText: l10n.whatsOnYourMind,
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
            if (_pollDraft == null)
              for (var i = 0; i < _links.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 18, color: Color(0xFF8B2942)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _links[i].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0077C2)),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: busy ? null : () => setState(() => _links.removeAt(i)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
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
                      l10n.uploadingPercent(((_uploadProgress ?? 0) * 100).round()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_pollDraft == null) ...[
                          _toolButton(
                            tooltip: l10n.attachImages(limits.maxImages),
                            icon: Icons.image_outlined,
                            onPressed: busy ? null : () => _pick(Attachment.image),
                          ),
                          if (limits.allowVideo)
                            _isCheckingVideo
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _toolButton(
                                    tooltip: limits.maxVideoDuration == null
                                        ? l10n.attachVideo
                                        : l10n.attachVideoMax(
                                            limits.maxVideoDuration!.inMinutes),
                                    icon: Icons.videocam_outlined,
                                    onPressed: busy ? null : () => _pick(Attachment.video),
                                  ),
                          if (limits.allowAudio)
                            _toolButton(
                              tooltip: l10n.attachAudio,
                              icon: Icons.audiotrack_rounded,
                              onPressed: busy ? null : () => _pick(Attachment.audio),
                            ),
                          if (limits.allowPdf)
                            _toolButton(
                              tooltip: l10n.attachPdf,
                              icon: Icons.picture_as_pdf_outlined,
                              color: Colors.redAccent,
                              onPressed: busy ? null : () => _pick(Attachment.pdf),
                            ),
                          if (widget.scope.allowLinks)
                            _toolButton(
                              tooltip: l10n.addLink,
                              icon: Icons.link_rounded,
                              color: const Color(0xFF8B2942),
                              onPressed: busy ? null : _addLink,
                            ),
                        ],
                        IconButton(
                          tooltip: l10n.poll,
                          visualDensity: VisualDensity.compact,
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
                              : IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF0077C2)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                      : Text(l10n.publish),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
