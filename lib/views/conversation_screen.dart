import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../services/conversation_service.dart';
import '../utils/time_ago.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ConversationService _service = ConversationService();
  final TextEditingController _messageController = TextEditingController();
  late final Stream<List<MessageModel>> _messagesStream;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Created once here (not inline in build()) so rebuilds — e.g. the two
    // setState calls every _sendMessage() does — don't tear down and
    // reattach the Firestore listener. Same fix as _conversationsStream in
    // conversations_screen.dart.
    _messagesStream = _service.getMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await _service.sendMessage(widget.conversationId, text);
      if (mounted) {
        _messageController.clear();
        setState(() => _isSending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Imeshindwa kutuma: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        title: Text(widget.otherName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Hakuna ujumbe bado. Anza mazungumzo!',
                      style: TextStyle(color: Colors.grey),
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
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, String? currentUid) {
    final isMe = message.senderId == currentUid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
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
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                color: isMe ? Colors.white : const Color(0xFF1A1D2E),
              ),
            ),
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
      ),
    );
  }

  Widget _buildMessageInput() {
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
                controller: _messageController,
                // Matches the 500-char cap firestore.rules enforces server-side
                // (see /conversations/{id}/messages/{id} allow create) — without
                // this, a too-long message would fail silently-ish at the rules
                // layer instead of being prevented up front. counterText hides
                // the default "n/500" counter to keep this compact pill input's
                // layout unchanged.
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Andika ujumbe...',
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
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
