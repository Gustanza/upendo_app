import 'media_limits.dart';

/// Where a chat's messages live and what may be sent there. One chat UI
/// (ChatRoomView) serves private 1:1 conversations, subcategory-wide chat
/// rooms and user-group chats — they differ only in these settings.
class ChatChannel {
  /// Firestore collection holding the message docs.
  final String messagesPath;

  /// Storage folder prefix for a message's attachments; the message id is
  /// appended. Must match the paths allowed by storage.rules.
  final String storagePrefix;

  /// Set for private conversations only — enables "delete chat for me"
  /// filtering (see chat_visibility.dart).
  final String? conversationId;

  /// Group rooms show (and store) the sender's name on each bubble.
  final bool showSenderNames;

  /// Rooms let senders delete their own messages, and [moderatorId] (a
  /// group owner) delete anyone's. 1:1 messages can't be deleted.
  final bool allowDeletingMessages;
  final String? moderatorId;

  final MediaLimits limits;

  const ChatChannel({
    required this.messagesPath,
    required this.storagePrefix,
    this.conversationId,
    this.showSenderNames = false,
    this.allowDeletingMessages = false,
    this.moderatorId,
    this.limits = MediaLimits.directMessage,
  });

  /// Private 1:1 chat. Storage keeps its original layout
  /// (conversations/{id}/{messageId}/…).
  factory ChatChannel.conversation(String conversationId) => ChatChannel(
        messagesPath: 'conversations/$conversationId/messages',
        storagePrefix: 'conversations/$conversationId',
        conversationId: conversationId,
      );

  /// The open chat room every user can join inside a subcategory.
  factory ChatChannel.subcategory(String categoryId) => ChatChannel(
        messagesPath: 'subcategoryFeeds/$categoryId/messages',
        storagePrefix: 'subcategoryFeeds/$categoryId/messages',
        showSenderNames: true,
        allowDeletingMessages: true,
        limits: MediaLimits.community,
      );

  /// A user group's members-only chat. The owner moderates it.
  factory ChatChannel.group(String groupId, {required String ownerId}) =>
      ChatChannel(
        messagesPath: 'userGroups/$groupId/messages',
        storagePrefix: 'userGroups/$groupId/messages',
        showSenderNames: true,
        allowDeletingMessages: true,
        moderatorId: ownerId,
        limits: MediaLimits.community,
      );

  String storageFolder(String messageId) => '$storagePrefix/$messageId';

  bool canDelete({required String senderId, required String? myUid}) =>
      allowDeletingMessages &&
      myUid != null &&
      (senderId == myUid || moderatorId == myUid);
}
