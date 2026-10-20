import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/models/conversation_model.dart';
import 'package:upendo_app/models/message_model.dart';
import 'package:upendo_app/utils/chat_visibility.dart';

// "Delete chat for me": the conversation disappears for the deleting user
// until a newer message arrives, and only messages after the deletion are
// shown to them. The other participant is unaffected.
void main() {
  final deletedAt = DateTime(2026, 5, 1, 12);

  group('isConversationVisible', () {
    test('visible when never deleted (pre-existing docs have no deletedAt)', () {
      expect(isConversationVisible(deletedAt: null, updatedAt: DateTime(2020)), isTrue);
      expect(isConversationVisible(deletedAt: null, updatedAt: null), isTrue);
    });

    test('hidden after deleting, while nothing newer has arrived', () {
      expect(
        isConversationVisible(deletedAt: deletedAt, updatedAt: deletedAt.subtract(const Duration(minutes: 5))),
        isFalse,
      );
      expect(isConversationVisible(deletedAt: deletedAt, updatedAt: deletedAt), isFalse);
      expect(isConversationVisible(deletedAt: deletedAt, updatedAt: null), isFalse);
    });

    test('reappears once a message newer than deletedAt bumps updatedAt', () {
      expect(
        isConversationVisible(deletedAt: deletedAt, updatedAt: deletedAt.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('message filtering', () {
    MessageModel msg(String id, DateTime? at) =>
        MessageModel(id: id, senderId: 'other', text: id, createdAt: at);

    test('only messages after deletedAt are shown; pending (null) ones always', () {
      final messages = [
        msg('old', deletedAt.subtract(const Duration(days: 1))),
        msg('same-instant', deletedAt),
        msg('new', deletedAt.add(const Duration(minutes: 1))),
        msg('pending', null),
      ];
      final visible = visibleSince(messages, deletedAt, (m) => m.createdAt);
      expect(visible.map((m) => m.id), ['new', 'pending']);
    });

    test('nothing filtered when the user never deleted the chat', () {
      final messages = [msg('a', DateTime(2020)), msg('b', null)];
      expect(visibleSince(messages, null, (m) => m.createdAt), same(messages));
    });
  });

  group('ConversationModel', () {
    ConversationModel conv({Map<String, DateTime> deleted = const {}, DateTime? updatedAt}) =>
        ConversationModel(
          id: 'a_b',
          participants: const ['a', 'b'],
          participantNames: const {'a': 'Asha', 'b': 'Baraka'},
          updatedAt: updatedAt,
          deletedAt: deleted,
        );

    test('deleting is per user — the other participant still sees the chat', () {
      final c = conv(deleted: {'a': deletedAt}, updatedAt: deletedAt.subtract(const Duration(hours: 1)));
      expect(c.isVisibleTo('a'), isFalse);
      expect(c.isVisibleTo('b'), isTrue);
      expect(c.deletedAtFor('a'), deletedAt);
      expect(c.deletedAtFor('b'), isNull);
    });

    test('parseDeletedAt reads Timestamps, treats a pending server timestamp as now, ignores junk', () {
      final now = DateTime(2026, 6, 1);
      final parsed = ConversationModel.parseDeletedAt({
        'a': Timestamp.fromDate(deletedAt),
        'b': null,
        'c': 'not a timestamp',
      }, now: now);
      expect(parsed, {'a': deletedAt, 'b': now});
      expect(ConversationModel.parseDeletedAt(null), isEmpty);
      expect(ConversationModel.parseDeletedAt('oops'), isEmpty);
    });

    test('otherParticipantName uses the provided fallback', () {
      final c = ConversationModel(id: 'x', participants: const ['a', 'b'], participantNames: const {});
      expect(c.otherParticipantName('a', fallback: 'User'), 'User');
    });
  });
}
