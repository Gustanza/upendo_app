import 'package:cloud_firestore/cloud_firestore.dart';
import 'attachment_model.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;
  final String type;
  final String? pollType;
  final List<String>? pollOptions;
  final List<Attachment> attachments;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
    this.type = 'text',
    this.pollType,
    this.pollOptions,
    this.attachments = const [],
  });

  factory MessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      type: data['type'] ?? 'text',
      pollType: data['pollType'] as String?,
      pollOptions: data['pollOptions'] is List
          ? (data['pollOptions'] as List).map((e) => e.toString()).toList()
          : null,
      attachments: Attachment.listFrom(data['attachments']),
    );
  }
}
