// Referral + wallet transactions against the Firestore emulator.
// Run with:  npm run test:emulator   (firebase emulators:exec sets
// FIRESTORE_EMULATOR_HOST; the tests are skipped without it).
const { test, describe, before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

const PROJECT_ID = 'demo-moyo-test';
const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;

const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// Account age normally comes from Firebase Auth; these tests inject it.
const freshAccount = { getAccountCreatedAt: async () => new Date() };
const oldAccount = { getAccountCreatedAt: async () => new Date('2020-01-01') };

const { assignReferralCode, applyReferralCodeFor } = require('../../referrals/index');
const { creditReferralCommission } = require('../../wallet/commission');
const { requestWithdrawalFor, resolveWithdrawalFor } = require('../../wallet/withdrawals');

let db;

async function clearFirestore() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
}

async function newUser(uid, extra = {}) {
  await db.collection('users').doc(uid).set({
    fullName: uid,
    createdAt: Timestamp.now(),
    ...extra,
  });
}

async function completedSubscription(id, userId, amount) {
  await db.collection('subscriptions').doc(id).set({ userId, amount, payment_amount: String(amount), status: 'Completed', currency: 'TZS' });
}

describe('referrals & wallet (Firestore emulator)', { skip: !hasEmulator && 'FIRESTORE_EMULATOR_HOST not set' }, () => {
  before(() => {
    if (!getApps().length) initializeApp({ projectId: PROJECT_ID });
    db = getFirestore();
  });
  beforeEach(clearFirestore);

  test('generateReferralCode: unique, stable, retries on collision', async () => {
    await newUser('alice');
    await newUser('bob');
    const a = await assignReferralCode(db, 'alice', { randomInt: () => 0 }); // AAAA
    assert.deepEqual(a, { code: 'AAAA', created: true });

    // Same user again → same code, nothing new allocated.
    const again = await assignReferralCode(db, 'alice');
    assert.deepEqual(again, { code: 'AAAA', created: false });

    // Bob's RNG first collides with AAAA, then yields BBBB.
    let calls = 0;
    const rng = () => (calls++ < 4 ? 0 : 1);
    const b = await assignReferralCode(db, 'bob', { randomInt: rng });
    assert.equal(b.code, 'BBBB');
    assert.equal((await db.doc('referralCodes/AAAA').get()).data().uid, 'alice');
    assert.equal((await db.doc('referralCodes/BBBB').get()).data().uid, 'bob');
    assert.equal((await db.doc('users/bob').get()).data().referralCode, 'BBBB');
  });

  test('applyReferralCode: once, not own code, new users only', async () => {
    await newUser('owner');
    const { code } = await assignReferralCode(db, 'owner');

    await newUser('newbie');
    await applyReferralCodeFor(db, 'newbie', code.toLowerCase(), freshAccount);
    const newbie = (await db.doc('users/newbie').get()).data();
    assert.equal(newbie.referredBy, 'owner');
    assert.equal((await db.doc('wallets/owner').get()).data().referralCount, 1);

    const reasonOf = async (uid, c, opts = freshAccount) => {
      try { await applyReferralCodeFor(db, uid, c, opts); return null; } catch (e) { return e.details && e.details.reason; }
    };
    assert.equal(await reasonOf('newbie', code), 'already-referred');
    assert.equal(await reasonOf('owner', code), 'own-code');
    assert.equal(await reasonOf('newbie', 'ZZZZ'), 'already-referred');

    await newUser('veteran', { createdAt: Timestamp.fromDate(new Date('2020-01-01')) });
    assert.equal(await reasonOf('veteran', code, oldAccount), 'not-new-user');

    await newUser('payer');
    await completedSubscription('sub0', 'payer', 10000);
    assert.equal(await reasonOf('payer', code), 'not-new-user');

    await newUser('typo');
    assert.equal(await reasonOf('typo', 'ZZZZ'), 'not-found');
    assert.equal(await reasonOf('typo', 'AB0C'), 'invalid-format');
    // Still exactly one referral counted, recorded in referralClaims.
    assert.equal((await db.doc('wallets/owner').get()).data().referralCount, 1);
    assert.equal((await db.doc('referralClaims/newbie').get()).data().referrerUid, 'owner');
  });

  test('commission is credited once per payment, even on repeated/concurrent callbacks', async () => {
    await newUser('referrer');
    await newUser('friend', { referredBy: 'referrer' });
    await completedSubscription('sub1', 'friend', 10000);

    const first = await creditReferralCommission(db, 'sub1');
    assert.equal(first.credited, true);
    assert.equal(first.amount, 100);

    // Webhook repeated (sequential) and racing (concurrent).
    const repeat = await creditReferralCommission(db, 'sub1');
    assert.deepEqual(repeat, { credited: false, reason: 'already-credited' });
    const racing = await Promise.all([1, 2, 3].map(() => creditReferralCommission(db, 'sub1')));
    assert.ok(racing.every((r) => !r.credited));

    let wallet = (await db.doc('wallets/referrer').get()).data();
    assert.equal(wallet.balance, 100);
    assert.equal(wallet.totalEarned, 100);
    const ledger = await db.collection('wallets/referrer/transactions').get();
    assert.equal(ledger.size, 1);
    assert.equal(ledger.docs[0].id, 'referral_sub1');

    // A second, separate payment by the same friend earns again.
    await completedSubscription('sub2', 'friend', 2500);
    await Promise.all([creditReferralCommission(db, 'sub2'), creditReferralCommission(db, 'sub2')]);
    wallet = (await db.doc('wallets/referrer').get()).data();
    assert.equal(wallet.balance, 125);
    assert.equal((await db.collection('wallets/referrer/transactions').get()).size, 2);
  });

  test('no credit for unreferred payers or unfinished payments', async () => {
    await newUser('solo');
    await completedSubscription('sub3', 'solo', 10000);
    assert.equal((await creditReferralCommission(db, 'sub3')).reason, 'no-referrer');

    await newUser('r');
    await newUser('f', { referredBy: 'r' });
    await db.doc('subscriptions/sub4').set({ userId: 'f', amount: 10000, status: 'PROCESSING' });
    assert.equal((await creditReferralCommission(db, 'sub4')).reason, 'not-completed');
    assert.equal((await creditReferralCommission(db, 'missing')).reason, 'no-subscription');
    assert.equal((await db.doc('wallets/r').get()).exists, false);
  });

  test('withdrawal reserves the amount atomically; reject refunds, approve pays', async () => {
    await newUser('earner');
    await db.doc('wallets/earner').set({ uid: 'earner', balance: 25000, totalEarned: 25000 });
    const form = {
      fullName: 'Earner One', phone: '+255712345678', amount: 15000, notes: 'M-Pesa',
      idType: 'passport', idPhotoPath: 'withdrawals/earner/1_id.jpg',
    };

    const { withdrawalId } = await requestWithdrawalFor(db, 'earner', form);
    let wallet = (await db.doc('wallets/earner').get()).data();
    assert.equal(wallet.balance, 10000);
    assert.equal(wallet.pendingWithdrawal, 15000);
    assert.equal((await db.doc(`withdrawalRequests/${withdrawalId}`).get()).data().status, 'pending');

    // Can't spend the reserved money twice.
    await assert.rejects(requestWithdrawalFor(db, 'earner', form), (e) => e.details.reason === 'insufficient-balance');
    await assert.rejects(requestWithdrawalFor(db, 'earner', { ...form, amount: 5000 }), (e) => e.details.reason === 'below-minimum');

    await resolveWithdrawalFor(db, 'admin', { withdrawalId, action: 'reject', note: 'ID unclear' });
    wallet = (await db.doc('wallets/earner').get()).data();
    assert.equal(wallet.balance, 25000);
    assert.equal(wallet.pendingWithdrawal, 0);
    // Resolving twice is refused (no double refund).
    await assert.rejects(resolveWithdrawalFor(db, 'admin', { withdrawalId, action: 'reject' }), (e) => e.details.reason === 'not-pending');

    const second = await requestWithdrawalFor(db, 'earner', { ...form, amount: 20000 });
    await resolveWithdrawalFor(db, 'admin', { withdrawalId: second.withdrawalId, action: 'approve' });
    wallet = (await db.doc('wallets/earner').get()).data();
    assert.equal(wallet.balance, 5000);
    assert.equal(wallet.pendingWithdrawal, 0);
    assert.equal(wallet.totalWithdrawn, 20000);
    assert.equal((await db.doc(`withdrawalRequests/${second.withdrawalId}`).get()).data().status, 'paid');
  });
});
