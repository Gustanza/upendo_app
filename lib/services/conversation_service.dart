import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/poll_model.dart';

class ConversationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

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
      final myName = (myDoc.data()?['fullName'] as String?) ?? 'Mtumiaji';
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
  // PostInteractionService.getComments.
  Stream<List<ConversationModel>> getConversations() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _conversations
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ConversationModel.fromFirestore(d)).toList());
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _messages(conversationId)
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
          // chat list in conversation_screen.dart. Re-sort here treating a
          // pending (null) createdAt as "now" so it renders as the most
          // recent message immediately, then settles into the same spot
          // once the real timestamp arrives.
          messages.sort((a, b) {
            final aMs = a.createdAt?.millisecondsSinceEpoch;
            final bMs = b.createdAt?.millisecondsSinceEpoch;
            if (aMs == null && bMs == null) return 0;
            if (aMs == null) return 1;
            if (bMs == null) return -1;
            return aMs.compareTo(bMs);
          });
          return messages;
        });
  }

  Future<void> sendMessage(String conversationId, String text, {PollData? poll}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _messages(conversationId).add({
      'senderId': uid,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'type': poll != null ? PollType.hostType : 'text',
      'pollType': poll?.pollType,
      'pollOptions': poll?.options,
    });
  }
}
