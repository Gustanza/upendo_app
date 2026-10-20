import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/chat_visibility.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? updatedAt;
  // "Delete chat (for me)": uid → when that participant deleted the chat.
  // Only the deleting participant's view changes — see chat_visibility.dart.
  // Absent on conversations nobody has deleted (every pre-existing doc).
  final Map<String, DateTime> deletedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.updatedAt,
    this.deletedAt = const {},
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? const []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? const {}),
      lastMessageText: lastMessage?['text'] as String?,
      lastMessageSenderId: lastMessage?['senderId'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deletedAt: parseDeletedAt(data['deletedAt']),
    );
  }

  /// Parses the raw `deletedAt` map. A value still pending its
  /// FieldValue.serverTimestamp() (null in the local cache right after this
  /// device deleted the chat) counts as "now", so the chat disappears from
  /// the list immediately instead of after the server round-trip.
  static Map<String, DateTime> parseDeletedAt(dynamic raw, {DateTime? now}) {
    if (raw is! Map) return const {};
    final result = <String, DateTime>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        result['$key'] = value.toDate();
      } else if (value == null) {
        result['$key'] = now ?? DateTime.now();
      }
    });
    return result;
  }

  String otherParticipantId(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  String otherParticipantName(String myUid, {String fallback = ''}) =>
      participantNames[otherParticipantId(myUid)] ?? fallback;

  DateTime? deletedAtFor(String uid) => deletedAt[uid];

  bool isVisibleTo(String uid) => isConversationVisible(
        deletedAt: deletedAt[uid],
        updatedAt: updatedAt,
      );
}
