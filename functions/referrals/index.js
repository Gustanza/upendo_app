const crypto = require('crypto');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const {
  generateCode,
  normalizeCode,
  validateReferralClaim,
} = require('./codes');

const usersCol = 'users';
const codesCol = 'referralCodes';
const walletsCol = 'wallets';
const claimsCol = 'referralClaims';

// When the Firebase Auth account was created — the trustworthy "is this a
// new user" signal (users.createdAt is client-written). Injectable so
// tests can simulate old accounts.
async function authAccountCreatedAt(uid) {
  const user = await getAuth().getUser(uid);
  return new Date(user.metadata.creationTime);
}

// Gives `uid` a unique referral code, or returns the one they already have.
// Uniqueness comes from creating referralCodes/{code} inside the same
// transaction that stamps users/{uid}.referralCode — tx.create fails on an
// existing code, and a collision just retries with a new random code.
async function assignReferralCode(db, uid, { randomInt = crypto.randomInt, maxAttempts = 25 } = {}) {
  const userRef = db.collection(usersCol).doc(uid);
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const code = generateCode(randomInt);
    const codeRef = db.collection(codesCol).doc(code);
    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError('failed-precondition', 'Complete your profile first', { reason: 'no-profile' });
      }
      const existing = userSnap.data().referralCode;
      if (existing) return { code: existing, created: false };
      const codeSnap = await tx.get(codeRef);
      if (codeSnap.exists) return null; // taken — retry with another code
      tx.create(codeRef, { uid, createdAt: FieldValue.serverTimestamp(), uses: 0 });
      tx.set(userRef, {
        referralCode: code,
        referralCodeCreatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return { code, created: true };
    });
    if (result) return result;
  }
  throw new HttpsError('resource-exhausted', 'Could not allocate a referral code, try again');
}

// Records that `uid` was referred by the owner of `rawCode`. Allowed once,
// only for a new user, never for their own code (see validateReferralClaim).
// The source of truth is referralClaims/{uid} (server-only, never deleted),
// mirrored to users.referredBy for the app/dashboard. Clients can't write
// either (firestore.rules), and can't delete their user doc to start over.
async function applyReferralCodeFor(db, uid, rawCode, {
  now = new Date(),
  getAccountCreatedAt = authAccountCreatedAt,
} = {}) {
  const code = normalizeCode(rawCode);
  let accountCreatedAt = null;
  try {
    accountCreatedAt = await getAccountCreatedAt(uid);
  } catch (err) {
    console.error(`applyReferralCode: no auth account for ${uid}`, err.message);
  }
  const userRef = db.collection(usersCol).doc(uid);
  const claimRef = db.collection(claimsCol).doc(uid);
  const codeRef = db.collection(codesCol).doc(code || '_');
  const paidQuery = db.collection('subscriptions')
    .where('userId', '==', uid)
    .where('status', '==', 'Completed')
    .limit(1);

  return db.runTransaction(async (tx) => {
    const [userSnap, codeSnap, paidSnap, claimSnap] = await Promise.all([
      tx.get(userRef),
      code ? tx.get(codeRef) : Promise.resolve(null),
      tx.get(paidQuery),
      tx.get(claimRef),
    ]);
    const codeOwnerUid = codeSnap && codeSnap.exists ? codeSnap.data().uid : null;
    const reason = validateReferralClaim({
      code,
      uid,
      userData: userSnap.exists ? userSnap.data() : null,
      codeOwnerUid,
      hasCompletedPayment: !paidSnap.empty,
      alreadyClaimed: claimSnap.exists,
      accountCreatedAt,
      now,
    });
    if (reason) {
      throw new HttpsError(
        reason === 'not-found' ? 'not-found' : 'failed-precondition',
        `Referral code rejected: ${reason}`,
        { reason },
      );
    }

    tx.create(claimRef, {
      referrerUid: codeOwnerUid,
      code,
      claimedAt: FieldValue.serverTimestamp(),
    });
    tx.set(userRef, {
      referredBy: codeOwnerUid,
      referredByCode: code,
      referredAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.update(codeRef, { uses: FieldValue.increment(1), lastUsedAt: FieldValue.serverTimestamp() });
    // Referral stats for the admin dashboard / the referrer's wallet card.
    tx.set(db.collection(walletsCol).doc(codeOwnerUid), {
      uid: codeOwnerUid,
      referralCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { referredBy: codeOwnerUid, code };
  });
}

function requireAuth(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  return uid;
}

const generateReferralCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const { code } = await assignReferralCode(getFirestore(), uid);
  return { code };
});

const applyReferralCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const result = await applyReferralCodeFor(getFirestore(), uid, request.data && request.data.code);
  return { ok: true, code: result.code };
});

module.exports = {
  authAccountCreatedAt,
  assignReferralCode,
  applyReferralCodeFor,
  generateReferralCode,
  applyReferralCode,
};
