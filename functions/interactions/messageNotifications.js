const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { notifyRecipient, truncate } = require('./_util');

// Preview text for a message sent with attachments but no text, so the
// conversation list and push body aren't blank.
function attachmentLabel(attachments) {
  if (!Array.isArray(attachments) || attachments.length === 0) return '';
  const types = new Set(attachments.map((a) => a && a.type));
  if (types.size > 1) return '📎 Viambatisho';
  if (types.has('image')) return attachments.length > 1 ? `📷 Picha ${attachments.length}` : '📷 Picha';
  if (types.has('video')) return '🎥 Video';
  if (types.has('pdf')) return '📄 PDF';
  if (types.has('audio')) return '🎵 Sauti';
  return '📎 Kiambatisho';
}

// Messages are never updated/deleted by clients (see firestore.rules), so
// this only ever needs to react to creation — no transitionDelta needed
// here, unlike the onDocumentWritten triggers in this directory.
const notifyConversationMessage = onDocumentCreated(
  'conversations/{conversationId}/messages/{messageId}',
  async (event) => {
    const message = event.data.data();
    const senderId = message.senderId;
    const text = message.text || attachmentLabel(message.attachments);

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
