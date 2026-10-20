const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { REFERRAL_COMMISSION_RATE } = require('./constants');
const { round2, paymentAmountOf, commissionFor } = require('./money');

// Credits the referrer of whoever paid `subscriptionId` with 1% of the
// amount, exactly once per payment. Called by both payment completion
// paths (ClickPesa webhook, PesaPal IPN) right after they mark the
// subscription "Completed" — providers retry/duplicate those callbacks, so
// idempotency matters:
//  * the ledger entry id is derived from the subscription id
//    (wallets/{referrer}/transactions/referral_{subscriptionId}), and
//  * it's read and written in the same transaction as the balance, so two
//    concurrent callbacks can't both credit — Firestore retries the loser,
//    which then sees the entry and stops.
// Never throws for "nothing to do" cases; returns { credited, reason }.
async function creditReferralCommission(db, subscriptionId) {
  const subRef = db.collection('subscriptions').doc(subscriptionId);
  const ledgerId = `referral_${subscriptionId}`;

  return db.runTransaction(async (tx) => {
    const subSnap = await tx.get(subRef);
    if (!subSnap.exists) return { credited: false, reason: 'no-subscription' };
    const sub = subSnap.data();
    if (sub.status !== 'Completed') return { credited: false, reason: 'not-completed' };
    if (!sub.userId) return { credited: false, reason: 'no-payer' };

    // referralClaims/{uid} is the permanent record (survives the user doc
    // being recreated); users.referredBy is its mirror.
    const [payerSnap, claimSnap] = await Promise.all([
      tx.get(db.collection('users').doc(sub.userId)),
      tx.get(db.collection('referralClaims').doc(sub.userId)),
    ]);
    const payer = payerSnap.exists ? payerSnap.data() : {};
    const referrerUid = (claimSnap.exists && claimSnap.data().referrerUid) || payer.referredBy;
    if (!referrerUid || referrerUid === sub.userId) {
      return { credited: false, reason: 'no-referrer' };
    }

    const walletRef = db.collection('wallets').doc(referrerUid);
    const ledgerRef = walletRef.collection('transactions').doc(ledgerId);
    const [ledgerSnap, walletSnap] = await Promise.all([tx.get(ledgerRef), tx.get(walletRef)]);
    if (ledgerSnap.exists) return { credited: false, reason: 'already-credited' };

    const paid = paymentAmountOf(sub);
    const commission = commissionFor(paid);
    if (commission <= 0) return { credited: false, reason: 'zero-amount' };

    const wallet = walletSnap.exists ? walletSnap.data() : {};
    const balance = round2((wallet.balance || 0) + commission);
    const totalEarned = round2((wallet.totalEarned || 0) + commission);

    tx.set(walletRef, {
      uid: referrerUid,
      balance,
      totalEarned,
      pendingWithdrawal: wallet.pendingWithdrawal || 0,
      totalWithdrawn: wallet.totalWithdrawn || 0,
      currency: 'TZS',
      updatedAt: FieldValue.serverTimestamp(),
      ...(walletSnap.exists && wallet.createdAt ? {} : { createdAt: FieldValue.serverTimestamp() }),
    }, { merge: true });
    tx.set(ledgerRef, {
      type: 'referral_credit',
      amount: commission,
      balanceAfter: balance,
      subscriptionId,
      fromUid: sub.userId,
      fromName: payer.fullName || '',
      paymentAmount: paid,
      rate: REFERRAL_COMMISSION_RATE,
      currency: sub.currency || 'TZS',
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(subRef, {
      referralCredit: {
        referrerUid,
        amount: commission,
        creditedAt: FieldValue.serverTimestamp(),
      },
    }, { merge: true });
    return { credited: true, amount: commission, referrerUid };
  });
}

// Payment-path wrapper: a referral problem must never break activating the
// payer's subscription, so failures are logged, not thrown.
async function creditReferralCommissionSafely(subscriptionId, db = getFirestore()) {
  try {
    const result = await creditReferralCommission(db, subscriptionId);
    if (result.credited) {
      console.log(`referral commission ${result.amount} → ${result.referrerUid} for ${subscriptionId}`);
    }
    return result;
  } catch (err) {
    console.error(`creditReferralCommission failed for ${subscriptionId}`, err);
    return { credited: false, reason: 'error' };
  }
}

// True when a subscriptions/{id} write moved it into "Completed".
function becameCompleted(before, after) {
  return !!after && after.status === 'Completed' && (!before || before.status !== 'Completed');
}

// Backstop for the inline calls in the payment webhooks: if crediting
// failed after the subscription was already marked Completed (e.g. the
// function crashed between the two writes), this trigger still credits it.
// creditReferralCommission is idempotent, so running both is safe.
const creditReferralOnCompletion = onDocumentWritten('subscriptions/{subscriptionId}', async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!becameCompleted(before, after)) return;
  await creditReferralCommissionSafely(event.params.subscriptionId);
});

module.exports = {
  creditReferralCommission,
  creditReferralCommissionSafely,
  becameCompleted,
  creditReferralOnCompletion,
};
