import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.updatedAt,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? const []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? const {}),
      lastMessageText: lastMessage?['text'] as String?,
      lastMessageSenderId: lastMessage?['senderId'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  String otherParticipantId(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  String otherParticipantName(String myUid) =>
      participantNames[otherParticipantId(myUid)] ?? 'Mtumiaji';
}
