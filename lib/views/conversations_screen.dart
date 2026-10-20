import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';
import '../utils/display_name.dart';
import '../utils/time_ago.dart';
import 'conversation_screen.dart';
import 'new_conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ConversationService _service = ConversationService();
  late final Stream<List<ConversationModel>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    // Created once here (not inline in build()) so rebuilds don't tear down
    // and reattach the Firestore listener — same pattern as _convStream in
    // home_dashboard.dart.
    _conversationsStream = _service.getConversations();
    _markSeen();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('conv_last_seen', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _confirmDelete(String otherName) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteChatTitle(otherName)),
        content: Text(l10n.deleteChatBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // Hides the chat for this user only — the other participant keeps the
  // full history, and a new message from them brings it back here.
  Future<bool> _deleteForMe(ConversationModel c, String otherName) async {
    if (!await _confirmDelete(otherName)) return false;
    try {
      await _service.deleteConversationForMe(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.chatDeleted)));
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed('$e'))));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(l10n.messagesTitle),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewConversationScreen()),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: l10n.newMessage,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8EAF0), height: 1),
        ),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 56, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 14),
                  Text(l10n.noConversationsYet,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final c = conversations[i];
              final otherName = uid == null
                  ? l10n.userFallbackName
                  : displayName(c.otherParticipantName(uid), l10n);
              final preview = c.lastMessageText ?? l10n.startConversation;

              // Swipe left (or long-press) to delete the chat for me.
              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _deleteForMe(c, otherName),
                background: Container(
                  color: Colors.red.shade400,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  title: Text(
                    otherName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  trailing: Text(
                    timeAgo(c.updatedAt),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                  onLongPress: () => _deleteForMe(c, otherName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(
                          conversationId: c.id,
                          otherName: otherName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
