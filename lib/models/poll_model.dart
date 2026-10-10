import 'package:cloud_firestore/cloud_firestore.dart';

class PollType {
  static const String multipleChoice = 'multiple_choice';
  static const String openText = 'open_text';

  // The value stored in a host doc's `type` field (posts/threadPosts/
  // messages) when it carries a poll — one named constant instead of the
  // literal 'poll' repeated at every render site.
  static const String hostType = 'poll';
}

class PollData {
  final String question;
  final String pollType;
  final List<String> options;

  PollData({
    required this.question,
    required this.pollType,
    this.options = const [],
  });

  // Builds a PollData from a host doc's raw (nullable) poll fields, applying
  // the same "missing pollType/options" defaults every render call site
  // needs — one place to keep them consistent instead of each screen
  // repeating `pollType ?? PollType.multipleChoice`.
  factory PollData.fromHostFields({
    required String question,
    String? pollType,
    List<String>? options,
  }) {
    return PollData(
      question: question,
      pollType: pollType ?? PollType.multipleChoice,
      options: options ?? const [],
    );
  }

  bool get isMultipleChoice => pollType == PollType.multipleChoice;
}

class PollResponseModel {
  final String uid;
  final String answer;
  final DateTime? answeredAt;

  PollResponseModel({
    required this.uid,
    required this.answer,
    this.answeredAt,
  });

  factory PollResponseModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return PollResponseModel(
      uid: uid,
      answer: data['answer'] ?? '',
      answeredAt: (data['answeredAt'] as Timestamp?)?.toDate(),
    );
  }
}
