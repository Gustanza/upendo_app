import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/conversation_service.dart';

/// Asks for confirmation, then hides a 1:1 chat for the signed-in user only —
/// the other participant keeps the full history, and a new message from them
/// brings it back here (see chat_visibility.dart). Shared by the inbox list
/// (swipe / long-press) and the chat screen's ⋮ menu. Returns true once the
/// chat is deleted.
Future<bool> confirmAndDeleteChatForMe(
  BuildContext context, {
  required String conversationId,
  required String otherName,
  ConversationService? service,
}) async {
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
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await (service ?? ConversationService()).deleteConversationForMe(conversationId);
    messenger.showSnackBar(SnackBar(content: Text(l10n.chatDeleted)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.deleteFailed('$e'))));
    return false;
  }
}
