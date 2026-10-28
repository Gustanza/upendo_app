import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/chat_channel.dart';
import '../utils/delete_chat.dart';
import '../widgets/chat_room_view.dart';

/// A private 1:1 conversation. The message list and composer are the shared
/// ChatRoomView; if the signed-in user previously deleted this chat "for
/// me", only messages sent after that are shown (see chat_visibility.dart).
class ConversationScreen extends StatelessWidget {
  final String conversationId;
  final String otherName;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        title: Text(otherName),
        actions: [
          PopupMenuButton<String>(
            key: const Key('chatMenu'),
            onSelected: (_) async {
              final deleted = await confirmAndDeleteChatForMe(context,
                  conversationId: conversationId, otherName: otherName);
              if (deleted && context.mounted) Navigator.pop(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(context.l10n.deleteChat),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ChatRoomView(
        channel: ChatChannel.conversation(conversationId),
        emptyText: context.l10n.noMessagesStartConversation,
      ),
    );
  }
}
