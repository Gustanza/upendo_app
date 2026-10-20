// "Delete chat for me" — pure rules, shared by ConversationService and the
// unit tests (test/chat_visibility_test.dart).
//
// Deleting stamps conversations/{id}.deletedAt.{myUid} with the server time.
// Nothing is removed from Firestore and the other participant's view is
// untouched. For the deleting user:
//  * the conversation is hidden from their list until a message newer than
//    their deletedAt arrives (updatedAt is bumped server-side by
//    notifyConversationMessage on every new message), and
//  * inside the conversation, only messages newer than deletedAt are shown.

/// Whether a conversation belongs in this user's list.
bool isConversationVisible({DateTime? deletedAt, DateTime? updatedAt}) {
  if (deletedAt == null) return true;
  return updatedAt != null && updatedAt.isAfter(deletedAt);
}

/// Whether a single message should be shown to a user who deleted the chat
/// at [deletedAt]. A message still pending its server timestamp
/// (createdAt == null) was just sent, so it's always newer.
bool isMessageVisible({DateTime? createdAt, DateTime? deletedAt}) {
  if (deletedAt == null || createdAt == null) return true;
  return createdAt.isAfter(deletedAt);
}

/// Filters [items] down to those created after [deletedAt].
List<T> visibleSince<T>(
  List<T> items,
  DateTime? deletedAt,
  DateTime? Function(T item) createdAtOf,
) {
  if (deletedAt == null) return items;
  return items
      .where((m) => isMessageVisible(createdAt: createdAtOf(m), deletedAt: deletedAt))
      .toList();
}
