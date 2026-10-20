const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { isAdminAuth } = require('../admin/isAdmin');
const { MIN_WITHDRAWAL_TZS, ID_TYPES } = require('./constants');
const { round2 } = require('./money');

const PHONE_PATTERN = /^\+?[0-9][0-9 ]{7,18}$/;

// Checks a withdrawal form. Pure; returns { value } or { error: reason }.
function validateWithdrawalInput(uid, data) {
  const input = data || {};
  const fullName = typeof input.fullName === 'string' ? input.fullName.trim() : '';
  const phone = typeof input.phone === 'string' ? input.phone.trim() : '';
  const notes = typeof input.notes === 'string' ? input.notes.trim() : '';
  const amount = typeof input.amount === 'number' ? input.amount : Number(input.amount);
  const idType = input.idType;
  const idPhotoPath = typeof input.idPhotoPath === 'string' ? input.idPhotoPath : '';

  if (fullName.length < 3 || fullName.length > 100) return { error: 'invalid-name' };
  if (!PHONE_PATTERN.test(phone)) return { error: 'invalid-phone' };
  if (!Number.isFinite(amount) || amount <= 0) return { error: 'invalid-amount' };
  if (amount < MIN_WITHDRAWAL_TZS) return { error: 'below-minimum' };
  if (notes.length > 500) return { error: 'notes-too-long' };
  if (!ID_TYPES.includes(idType)) return { error: 'invalid-id-type' };
  // The ID photo must be one this user uploaded to their own folder
  // (storage.rules only lets them write withdrawals/{theirUid}/...).
  if (!idPhotoPath.startsWith(`withdrawals/${uid}/`) || idPhotoPath.includes('..')) {
    return { error: 'invalid-id-photo' };
  }
  return { value: { fullName, phone, notes, amount: round2(amount), idType, idPhotoPath } };
}

// Creates a pending withdrawalRequests doc and reserves the amount: it's
// moved from wallet.balance to wallet.pendingWithdrawal in the same
// transaction, with a ledger entry, so the balance can never be spent twice.
async function requestWithdrawalFor(db, uid, data) {
  const { value, error } = validateWithdrawalInput(uid, data);
  if (error) throw new HttpsError('invalid-argument', `Invalid withdrawal: ${error}`, { reason: error });

  const walletRef = db.collection('wallets').doc(uid);
  const requestRef = db.collection('withdrawalRequests').doc();
  const userRef = db.collection('users').doc(uid);

  return db.runTransaction(async (tx) => {
    const [walletSnap, userSnap] = await Promise.all([tx.get(walletRef), tx.get(userRef)]);
    const wallet = walletSnap.exists ? walletSnap.data() : {};
    const balance = wallet.balance || 0;
    if (value.amount > balance) {
      throw new HttpsError('failed-precondition', 'Insufficient balance', { reason: 'insufficient-balance' });
    }
    const user = userSnap.exists ? userSnap.data() : {};
    const newBalance = round2(balance - value.amount);
    const pending = round2((wallet.pendingWithdrawal || 0) + value.amount);

    tx.set(requestRef, {
      uid,
      ...value,
      currency: 'TZS',
      status: 'pending',
      userName: user.fullName || '',
      userEmail: user.email || '',
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(walletRef, {
      uid,
      balance: newBalance,
      pendingWithdrawal: pending,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.set(walletRef.collection('transactions').doc(`withdrawal_${requestRef.id}`), {
      type: 'withdrawal_hold',
      amount: -value.amount,
      balanceAfter: newBalance,
      withdrawalId: requestRef.id,
      currency: 'TZS',
      createdAt: FieldValue.serverTimestamp(),
    });
    return { withdrawalId: requestRef.id, balance: newBalance };
  });
}

// Admin decision on a pending request:
//  * approve → marked "paid" (the money is sent manually outside the app);
//    the reserved amount leaves pendingWithdrawal for totalWithdrawn.
//  * reject  → the reserved amount is refunded to the wallet balance.
// Only pending requests can be resolved, so a double click can't refund
// or pay twice.
async function resolveWithdrawalFor(db, adminUid, { withdrawalId, action, note }) {
  if (typeof withdrawalId !== 'string' || !withdrawalId) {
    throw new HttpsError('invalid-argument', 'withdrawalId is required');
  }
  if (action !== 'approve' && action !== 'reject') {
    throw new HttpsError('invalid-argument', 'action must be approve or reject');
  }
  const requestRef = db.collection('withdrawalRequests').doc(withdrawalId);

  return db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) throw new HttpsError('not-found', 'Withdrawal request not found');
    const request = requestSnap.data();
    if (request.status !== 'pending') {
      throw new HttpsError('failed-precondition', `Request already ${request.status}`, { reason: 'not-pending' });
    }
    const walletRef = db.collection('wallets').doc(request.uid);
    const walletSnap = await tx.get(walletRef);
    const wallet = walletSnap.exists ? walletSnap.data() : {};
    const pending = round2(Math.max(0, (wallet.pendingWithdrawal || 0) - request.amount));
    const adminNote = typeof note === 'string' ? note.trim().slice(0, 500) : '';
    const status = action === 'approve' ? 'paid' : 'rejected';

    tx.update(requestRef, {
      status,
      adminNote,
      resolvedBy: adminUid,
      resolvedAt: FieldValue.serverTimestamp(),
    });

    const ledgerRef = walletRef.collection('transactions').doc(`withdrawal_${withdrawalId}_${status}`);
    if (action === 'approve') {
      tx.set(walletRef, {
        pendingWithdrawal: pending,
        totalWithdrawn: round2((wallet.totalWithdrawn || 0) + request.amount),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      // Informational: the balance already dropped when the request was made.
      tx.set(ledgerRef, {
        type: 'withdrawal_paid',
        amount: 0,
        withdrawalAmount: request.amount,
        balanceAfter: wallet.balance || 0,
        withdrawalId,
        currency: 'TZS',
        createdAt: FieldValue.serverTimestamp(),
      });
    } else {
      const balance = round2((wallet.balance || 0) + request.amount);
      tx.set(walletRef, {
        balance,
        pendingWithdrawal: pending,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      tx.set(ledgerRef, {
        type: 'withdrawal_refund',
        amount: request.amount,
        balanceAfter: balance,
        withdrawalId,
        note: adminNote,
        currency: 'TZS',
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    return { status };
  });
}

const requestWithdrawal = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  return requestWithdrawalFor(getFirestore(), uid, request.data);
});

const adminResolveWithdrawal = onCall(async (request) => {
  const db = getFirestore();
  if (!(await isAdminAuth(request.auth, db))) {
    throw new HttpsError('permission-denied', 'Admins only');
  }
  return resolveWithdrawalFor(db, request.auth.uid, request.data || {});
});

module.exports = {
  validateWithdrawalInput,
  requestWithdrawalFor,
  resolveWithdrawalFor,
  requestWithdrawal,
  adminResolveWithdrawal,
};
