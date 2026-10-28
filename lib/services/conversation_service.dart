import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attachment_model.dart';
import '../models/chat_channel.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/poll_model.dart';
import '../utils/chat_visibility.dart';
import 'attachment_service.dart';

class ConversationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  // Matches firestore.rules' create check: the two uids sorted
  // lexicographically and joined with '_', so the doc id alone proves who
  // the conversation is between.
  String _conversationId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }

  // Returns the existing conversation with `otherUid`, or creates it first.
  // Not fully race-safe against two simultaneous first-time creates (both
  // participants opening the thread at the same instant) — an acceptable
  // tradeoff here since the two writes would be near-identical anyway, and
  // a transaction felt like more machinery than a 1:1 conversation needs.
  Future<String> getOrCreateConversation({
    required String otherUid,
    required String otherName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final conversationId = _conversationId(uid, otherUid);
    final ref = _conversations.doc(conversationId);
    final snap = await ref.get();
    if (!snap.exists) {
      final myDoc = await _db.collection('users').doc(uid).get();
      final myName = (myDoc.data()?['fullName'] as String?) ?? '';
      await ref.set({
        'participants': [uid, otherUid]..sort(),
        'participantNames': {uid: myName, otherUid: otherName},
        'lastMessage': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return conversationId;
  }

  // Unpaginated: a user's own conversation list is bounded by how many
  // people they've messaged, not a global feed — same tradeoff as
  // PostInteractionService.getComments. Conversations this user deleted
  // "for me" are dropped until a newer message brings them back.
  Stream<List<ConversationModel>> getConversations() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _conversations
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ConversationModel.fromFirestore(d))
            .where((c) => c.isVisibleTo(uid))
            .toList());
  }

  /// "Delete chat" — hides the conversation and its current messages for
  /// the signed-in user only (see chat_visibility.dart). firestore.rules
  /// allows a participant to write exactly this one field.
  Future<void> deleteConversationForMe(String conversationId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _conversations.doc(conversationId).update({
      'deletedAt.$uid': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MessageModel>> getMessages(String conversationId) =>
      watchMessages(ChatChannel.conversation(conversationId));

  /// Live, oldest-first messages of any chat. For a private conversation
  /// the signed-in user previously deleted, messages up to that moment are
  /// filtered out.
  Stream<List<MessageModel>> watchMessages(ChatChannel channel) async* {
    DateTime? deletedAt;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (channel.conversationId != null && uid != null) {
      final snap = await _conversations.doc(channel.conversationId).get();
      if (snap.exists) {
        deletedAt = ConversationModel.fromFirestore(snap).deletedAtFor(uid);
      }
    }
    yield* _db
        .collection(channel.messagesPath)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) {
          final messages = snap.docs
              .map((d) => MessageModel.fromFirestore(d.id, d.data()))
              .toList();
          // A just-sent message has createdAt == null in the local cache
          // until its FieldValue.serverTimestamp() resolves — Firestore's
          // orderBy('createdAt') sorts null first (oldest), which briefly
          // flashes a just-sent message to the wrong end of the reversed
          // chat list in ChatRoomView. Re-sort here treating a pending
          // (null) createdAt as "now" so it renders as the most recent
          // message immediately, then settles into the same spot once the
          // real timestamp arrives.
          messages.sort((a, b) {
            final aMs = a.createdAt?.millisecondsSinceEpoch;
            final bMs = b.createdAt?.millisecondsSinceEpoch;
            if (aMs == null && bMs == null) return 0;
            if (aMs == null) return 1;
            if (bMs == null) return -1;
            return aMs.compareTo(bMs);
          });
          return visibleSince(messages, deletedAt, (m) => m.createdAt);
        });
  }

  Future<void> sendMessage(
    String conversationId,
    String text, {
    PollData? poll,
    List<PendingAttachment> attachments = const [],
    void Function(double progress)? onUploadProgress,
  }) =>
      sendTo(
        ChatChannel.conversation(conversationId),
        text,
        poll: poll,
        attachments: attachments,
        onUploadProgress: onUploadProgress,
      );

  // Attachments are uploaded to the channel's storage folder before the
  // message doc is written, so the recipient never sees a message whose
  // files are still missing. Text may be empty when attachments are sent.
  Future<void> sendTo(
    ChatChannel channel,
    String text, {
    PollData? poll,
    List<PendingAttachment> attachments = const [],
    void Function(double progress)? onUploadProgress,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = _db.collection(channel.messagesPath).doc();
    String? senderName;
    if (channel.showSenderNames) {
      final myDoc = await _db.collection('users').doc(uid).get();
      senderName = (myDoc.data()?['fullName'] as String?) ?? '';
    }
    final uploaded = await AttachmentService().uploadAll(
      channel.storageFolder(docRef.id, uploaderUid: uid),
      attachments,
      onProgress: onUploadProgress,
    );
    await docRef.set({
      'senderId': uid,
      'senderName': ?senderName,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'type': poll != null ? PollType.hostType : 'text',
      'pollType': poll?.pollType,
      'pollOptions': poll?.options,
      if (uploaded.isNotEmpty)
        'attachments': uploaded.map((a) => a.toMap()).toList(),
    });
  }

  /// Room messages only (ChatChannel.allowDeletingMessages) — firestore.rules
  /// lets the sender, the group owner or an admin delete; attachments are
  /// removed by the cleanupRoomMessage Cloud Function.
  Future<void> deleteMessage(ChatChannel channel, String messageId) =>
      _db.collection(channel.messagesPath).doc(messageId).delete();
}
