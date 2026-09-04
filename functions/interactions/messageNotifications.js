const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { notifyRecipient } = require('./_util');

// Push previews are short — a long message shouldn't produce an unwieldy
// notification body.
const PREVIEW_LENGTH = 80;

function truncate(text) {
  // String.prototype.slice cuts by UTF-16 code unit, which can split a
  // surrogate pair (e.g. an emoji) in half and produce a broken glyph in
  // the push body. Array.from iterates by Unicode code point instead, so
  // truncation always lands on a whole-character boundary.
  const codePoints = Array.from(text);
  return codePoints.length > PREVIEW_LENGTH
    ? `${codePoints.slice(0, PREVIEW_LENGTH - 1).join('')}…`
    : text;
}

// Messages are never updated/deleted by clients (see firestore.rules), so
// this only ever needs to react to creation — no transitionDelta needed
// here, unlike the onDocumentWritten triggers in this directory.
const notifyConversationMessage = onDocumentCreated(
  'conversations/{conversationId}/messages/{messageId}',
  async (event) => {
    const message = event.data.data();
    const senderId = message.senderId;
    const text = message.text || '';

    const conversationRef = getFirestore().collection('conversations').doc(event.params.conversationId);
    const conversationSnap = await conversationRef.get();
    if (!conversationSnap.exists) return;

    const conversation = conversationSnap.data();
    const participants = conversation.participants || [];
    const recipientId = participants.find((uid) => uid !== senderId);

    // Keeps the conversation list's preview fields current — mirrors how
    // updateCommentCount/updateLikeCount (counters.js) maintain server-only
    // aggregate fields elsewhere; clients never write these directly (see
    // firestore.rules, which has no allow update for /conversations).
    await conversationRef.update({
      lastMessage: { text, senderId, createdAt: message.createdAt },
      updatedAt: FieldValue.serverTimestamp(),
    });

    const senderName = (conversation.participantNames || {})[senderId] || 'Mtumiaji';

    await notifyRecipient({
      recipientId,
      actorId: senderId,
      title: senderName,
      body: truncate(text),
      type: 'message',
      conversationId: event.params.conversationId,
    });
  },
);

module.exports = { notifyConversationMessage };
