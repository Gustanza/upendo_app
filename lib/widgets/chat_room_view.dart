import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/l10n.dart';
import '../models/attachment_model.dart';
import '../models/chat_channel.dart';
import '../models/message_model.dart';
import '../models/poll_model.dart';
import '../services/attachment_service.dart';
import '../services/conversation_service.dart';
import '../utils/display_name.dart';
import '../utils/time_ago.dart';
import 'attachment_picker.dart';
import 'attachment_views.dart';
import 'linkified_text.dart';
import 'poll_composer_card.dart';
import 'poll_view.dart';

/// Message list + composer for any [ChatChannel]: a private conversation
/// (ConversationScreen), a subcategory chat room or a user group's chat.
/// Has no Scaffold of its own so it can sit inside a tab.
class ChatRoomView extends StatefulWidget {
  final ChatChannel channel;
  final String? emptyText;

  const ChatRoomView({super.key, required this.channel, this.emptyText});

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final ConversationService _service = ConversationService();
  final TextEditingController _messageController = TextEditingController();
  late final Stream<List<MessageModel>> _messagesStream;
  bool _isSending = false;
  bool _isCheckingVideo = false;
  PollDraft? _pollDraft;
  final AttachmentService _attachmentService = AttachmentService();
  final List<PendingAttachment> _pending = [];
  double? _uploadProgress;

  ChatChannel get _channel => widget.channel;

  // Limits (images per message, total attachments, video length, file
  // sizes) come from the channel and match firestore.rules/storage.rules
  // for that collection — without this, e.g. repeatedly adding PDFs on top
  // of photos passes client-side but gets rejected by the security rule at
  // send time.
  Future<void> _showAttachMenu() async {
    final choice = await showAttachmentTypeMenu(context, _channel.limits);
    if (choice == null || !mounted) return;
    final picked = await pickValidatedAttachments(
      context,
      type: choice,
      limits: _channel.limits,
      current: _pending,
      service: _attachmentService,
      onCheckingVideo: (checking) {
        if (mounted) setState(() => _isCheckingVideo = checking);
      },
    );
    if (picked.isNotEmpty && mounted) setState(() => _pending.addAll(picked));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    // Created once here (not inline in build()) so rebuilds — e.g. the two
    // setState calls every _sendMessage() does — don't tear down and
    // reattach the Firestore listener. Same fix as _conversationsStream in
    // conversations_screen.dart.
    _messagesStream = _service.watchMessages(_channel);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    PollData? pollData;
    String text;
    if (_pollDraft != null) {
      pollData = _pollDraft!.build();
      if (pollData == null) {
        _snack(context.l10n.pollIncomplete);
        return;
      }
      text = pollData.question;
    } else {
      text = _messageController.text.trim();
    }
    final attachments = pollData == null ? List.of(_pending) : <PendingAttachment>[];
    if ((text.isEmpty && attachments.isEmpty) || _isSending) return;
    setState(() {
      _isSending = true;
      _uploadProgress = attachments.isEmpty ? null : 0;
    });
    try {
      await _service.sendTo(
        _channel,
        text,
        poll: pollData,
        attachments: attachments,
        onUploadProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (mounted) {
        _messageController.clear();
        setState(() {
          _isSending = false;
          _uploadProgress = null;
          _pollDraft = null;
          _pending.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _uploadProgress = null;
        });
        _snack(context.l10n.sendFailed('$e'));
      }
    }
  }

  Future<void> _confirmDeleteMessage(MessageModel message) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMessageTitle),
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
      await _service.deleteMessage(_channel, message.id);
    } catch (e) {
      if (mounted) _snack(context.l10n.deleteFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _messagesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(context.l10n.errorWithDetails('${snapshot.error}')),
                );
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    widget.emptyText ?? context.l10n.noMessagesYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }
              // reverse: true anchors the list at the newest message
              // without extra scroll-controller bookkeeping.
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  return _buildMessageBubble(message, currentUid);
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(MessageModel message, String? currentUid) {
    final isMe = message.senderId == currentUid;
    final canDelete = _channel.canDelete(senderId: message.senderId, myUid: currentUid);
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF0077C2) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_channel.showSenderNames && !isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                displayName(message.senderName, context.l10n),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B2942),
                ),
              ),
            ),
          if (message.type == PollType.hostType)
            PollView(
              poll: PollData.fromHostFields(
                question: message.text,
                pollType: message.pollType,
                options: message.pollOptions,
              ),
              responsesRef: FirebaseFirestore.instance
                  .collection(_channel.messagesPath)
                  .doc(message.id)
                  .collection('pollResponses'),
            )
          else ...[
            if (message.attachments.isNotEmpty)
              AttachmentsView(attachments: message.attachments, onDark: isMe),
            if (message.attachments.isNotEmpty && message.text.isNotEmpty)
              const SizedBox(height: 6),
            if (message.text.isNotEmpty)
              LinkifiedText(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: isMe ? Colors.white : const Color(0xFF1A1D2E),
                ),
                linkColor: isMe ? Colors.white : const Color(0xFF0077C2),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            timeAgo(message.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
    );
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: canDelete
          ? GestureDetector(
              onLongPress: () => _confirmDeleteMessage(message),
              child: bubble,
            )
          : bubble,
    );
  }

  Widget _buildMessageInput() {
    final busy = _isSending || _isCheckingVideo;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pollDraft != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                // Up to 15 options won't fit on screen — scroll within a cap.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: PollComposerCard(
                      draft: _pollDraft!,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
              ),
            if (_pollDraft == null && _pending.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttachmentDraftStrip(
                  items: _pending,
                  onRemove: busy ? null : (i) => setState(() => _pending.removeAt(i)),
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
                      context.l10n.uploadingPercent(
                          ((_uploadProgress ?? 0) * 100).round()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (_pollDraft == null)
                  IconButton(
                    tooltip: context.l10n.attach,
                    onPressed: busy ? null : _showAttachMenu,
                    icon: _isCheckingVideo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_rounded, color: Color(0xFF0077C2)),
                  ),
                IconButton(
                  tooltip: context.l10n.poll,
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
                if (_pollDraft == null)
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      // Matches the 500-char cap firestore.rules enforces
                      // server-side on every messages collection — without
                      // this, a too-long message would fail at the rules
                      // layer instead of being prevented up front.
                      // counterText hides the default "n/500" counter to
                      // keep this compact pill input's layout unchanged.
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: context.l10n.writeMessageHint,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Color(0xFF0077C2)),
                  onPressed: busy ? null : _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
