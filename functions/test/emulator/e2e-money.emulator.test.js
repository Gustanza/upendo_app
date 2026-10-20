// Tester-added end-to-end journeys for referral + wallet, driven through the
// REAL entry points: the ClickPesa webhook (resolvePaymentClickPesa), the
// PesaPal IPN (resolvePayment) and the onCall wrappers (generateReferralCode,
// applyReferralCode, requestWithdrawal, adminResolveWithdrawal).
// External HTTP (axios) is stubbed — nothing leaves the machine.
// Run with: npm run test:emulator  (skipped without FIRESTORE_EMULATOR_HOST).
const { test, describe, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');

const PROJECT_ID = 'demo-moyo-test';
const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;

// ---- stub axios BEFORE the payment modules create their clients ----------
const axios = require('axios');
const pesapalScript = { amount: 30000, status: 'Completed' };
// What ClickPesa's "Query Payment Status" API reports per orderReference
// (the webhook body itself is no longer trusted). Missing → no payment.
const clickpesaScript = {};
const httpCalls = [];
axios.create = () => ({
  post: async (url, body) => {
    httpCalls.push(['POST', url]);
    if (url.includes('/Auth/RequestToken')) return { data: { status: 200, token: 'tok' } };
    if (url.includes('/generate-token')) return { data: { success: true, token: 'Bearer cp' } };
    throw new Error(`unexpected POST ${url}`);
  },
  get: async (url) => {
    httpCalls.push(['GET', url]);
    const cp = url.match(/^\/payments\/([^/?]+)$/);
    if (cp) {
      const ref = decodeURIComponent(cp[1]);
      const s = clickpesaScript[ref];
      return { data: s ? [{ id: `cp-${ref}`, orderReference: ref, channel: 'TIGO-PESA', message: 'ok', ...s }] : [] };
    }
    if (url.includes('GetTransactionStatus')) {
      return {
        data: {
          status: 200,
          payment_status_description: pesapalScript.status,
          amount: pesapalScript.amount,
          payment_method: 'MpesaTZ',
          message: 'ok',
          payment_account: '2557xxxx',
          merchant_reference: 'x',
        },
      };
    }
    throw new Error(`unexpected GET ${url}`);
  },
});

const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

let db;
let fft;
let wrap;
let H; // handlers

async function clearFirestore() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
}

// Minimal express-like req/res for a v2 onRequest handler.
function callHttp(fn, { method = 'POST', body = {}, query = {} } = {}) {
  return new Promise((resolve, reject) => {
    const headers = { origin: 'https://example.test' };
    const req = {
      method, body, query, headers, url: '/', originalUrl: '/',
      get: (h) => headers[h.toLowerCase()], header: (h) => headers[h.toLowerCase()],
    };
    const outHeaders = {};
    const res = {
      statusCode: 200,
      setHeader: (k, v) => { outHeaders[k.toLowerCase()] = v; },
      getHeader: (k) => outHeaders[k.toLowerCase()],
      removeHeader: (k) => { delete outHeaders[k.toLowerCase()]; },
      status(code) { this.statusCode = code; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      send(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      end(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      on() {}, once() {}, emit() {},
    };
    Promise.resolve(fn(req, res)).catch(reject);
  });
}

const clickpesaReceived = (orderReference, collectedAmount) => ({
  event: 'PAYMENT RECEIVED',
  data: { orderReference, status: 'SUCCESS', collectedAmount, channel: 'TIGO-PESA', message: 'ok' },
});

// applyReferralCode judges "new user" from the Auth account, so every
// seeded user also gets an (emulated) Auth account created now.
async function seedUser(uid, extra = {}) {
  await getAuth().createUser({ uid }).catch((e) => { if (e.code !== 'auth/uid-already-exists') throw e; });
  await db.collection('users').doc(uid).set({ fullName: uid, email: `${uid}@x.test`, createdAt: Timestamp.now(), isActive: false, ...extra });
}

// Mirrors what subscribeClickPesa / subscribe write before the provider calls back.
async function seedPendingSubscription(id, userId, amount, provider = 'clickpesa') {
  await db.collection('subscriptions').doc(id).set({
    userId, packageId: 'pkg1', packageName: 'Mwezi', durationDays: 30,
    amount, currency: 'TZS', provider, status: 'PROCESSING',
  });
}

async function wallet(uid) {
  const s = await db.collection('wallets').doc(uid).get();
  return s.exists ? s.data() : {};
}
async function ledger(uid) {
  const s = await db.collection('wallets').doc(uid).collection('transactions').get();
  return s.docs.map((d) => ({ id: d.id, ...d.data() }));
}

const authOf = (uid, email, verified = true) => ({ uid, token: { uid, email, email_verified: verified } });

async function expectHttpsError(promise, code) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    return true;
  });
}

describe('E2E money journeys (real handlers, stubbed HTTP)', { skip: !hasEmulator && 'FIRESTORE_EMULATOR_HOST not set' }, () => {
  before(() => {
    if (!getApps().length) initializeApp({ projectId: PROJECT_ID });
    db = getFirestore();
    fft = require('firebase-functions-test')({ projectId: PROJECT_ID });
    wrap = fft.wrap;
    H = {
      ...require('../../payments/clickpesa'),
      ...require('../../payments/ipnresolver'),
      ...require('../../referrals/index'),
      ...require('../../wallet/withdrawals'),
    };
  });
  after(() => fft && fft.cleanup());
  beforeEach(async () => {
    await clearFirestore();
    await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: 'DELETE' });
    httpCalls.length = 0;
    for (const k of Object.keys(clickpesaScript)) delete clickpesaScript[k];
  });

  test('referral journey: code → apply → ClickPesa webhook x3 + PesaPal IPN x2 → credited exactly once per payment at 1%', async () => {
    await seedUser('alice');
    await seedUser('bob');

    const gen = wrap(H.generateReferralCode);
    const { code } = await gen({ data: {}, auth: authOf('alice', 'alice@x.test') });
    assert.match(code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{4}$/);
    // stable
    assert.equal((await gen({ data: {}, auth: authOf('alice', 'alice@x.test') })).code, code);

    const apply = wrap(H.applyReferralCode);
    // own code refused
    await expectHttpsError(apply({ data: { code }, auth: authOf('alice', 'alice@x.test') }), 'failed-precondition');
    // lower-case + spaces normalised
    const r = await apply({ data: { code: ` ${code.toLowerCase()} ` }, auth: authOf('bob', 'bob@x.test') });
    assert.equal(r.ok, true);
    // second time refused
    await expectHttpsError(apply({ data: { code }, auth: authOf('bob', 'bob@x.test') }), 'failed-precondition');
    // unauthenticated refused
    await expectHttpsError(apply({ data: { code } }), 'unauthenticated');

    // --- ClickPesa: webhook delivered three times (two of them concurrently)
    await seedPendingSubscription('subCP0000000000000001', 'bob', 25000);
    clickpesaScript.subCP0000000000000001 = { status: 'SUCCESS', collectedAmount: '25000' };
    const first = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000001', '25000') });
    assert.equal(first.body.activated, true, JSON.stringify(first.body));
    await Promise.all([
      callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000001', '25000') }),
      callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000001', '25000') }),
    ]);
    let w = await wallet('alice');
    assert.equal(w.balance, 250);
    assert.equal(w.totalEarned, 250);
    assert.equal((await db.doc('users/bob').get()).data().isActive, true);

    // --- PesaPal IPN for a second payment, delivered twice
    await seedPendingSubscription('subPP0000000000000002', 'bob', 30000, 'pesapal');
    pesapalScript.amount = 30000; pesapalScript.status = 'Completed';
    const ipn = { method: 'GET', query: { OrderTrackingId: 'trk-1', OrderMerchantReference: 'subPP0000000000000002' } };
    const p1 = await callHttp(H.resolvePayment, ipn);
    assert.equal(p1.body.activated, true, JSON.stringify(p1.body));
    await callHttp(H.resolvePayment, ipn);

    w = await wallet('alice');
    assert.equal(w.balance, 550);
    assert.equal(w.totalEarned, 550);
    const entries = (await ledger('alice')).filter((e) => e.type === 'referral_credit');
    assert.equal(entries.length, 2);
    assert.deepEqual(entries.map((e) => e.amount).sort((a, b) => a - b), [250, 300]);
    assert.ok(httpCalls.some(([, u]) => u.includes('GetTransactionStatus')), 'PesaPal status endpoint (stub) was consulted');

    // Payer is never credited themselves.
    assert.deepEqual(await wallet('bob'), {});
  });

  test('inflated provider amount is capped at the package price; failed payment credits nothing', async () => {
    await seedUser('alice');
    await seedUser('bob');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'bob', code);

    await seedPendingSubscription('subCP0000000000000003', 'bob', 10000);
    clickpesaScript.subCP0000000000000003 = { status: 'FAILED', collectedAmount: '0' };
    await callHttp(H.resolvePaymentClickPesa, { body: { event: 'PAYMENT FAILED', data: { orderReference: 'subCP0000000000000003', status: 'FAILED', collectedAmount: '0', channel: 'x', message: 'Cancelled' } } });
    assert.equal((await wallet('alice')).balance, undefined);
    assert.equal((await wallet('alice')).referralCount, 1);

    // ClickPesa itself reports an inflated amount → still capped.
    clickpesaScript.subCP0000000000000003 = { status: 'SUCCESS', collectedAmount: '9999999' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000003', '9999999') });
    assert.equal((await wallet('alice')).balance, 100);

    // Odd amount → rounding to 2 decimals
    await seedPendingSubscription('subPP0000000000000004', 'bob', 12345);
    pesapalScript.amount = '12,345.00';
    await callHttp(H.resolvePayment, { method: 'GET', query: { OrderTrackingId: 't', OrderMerchantReference: 'subPP0000000000000004' } });
    assert.equal((await wallet('alice')).balance, 223.45);
  });

  test('referral cannot be applied after the user has a completed payment', async () => {
    await seedUser('alice');
    await seedUser('carol');
    const { code } = await H.assignReferralCode(db, 'alice');
    await seedPendingSubscription('subCP0000000000000005', 'carol', 10000);
    clickpesaScript.subCP0000000000000005 = { status: 'SUCCESS', collectedAmount: '10000' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000005', '10000') });
    await expectHttpsError(
      wrap(H.applyReferralCode)({ data: { code }, auth: authOf('carol', 'carol@x.test') }),
      'failed-precondition',
    );
    assert.equal((await db.doc('users/carol').get()).data().referredBy, undefined);
  });

  test('withdrawal journey via callables: min, balance, reserve, reject→refund, approve→withdrawn, admin-only', async () => {
    await seedUser('alice');
    await db.collection('admins').doc('boss@moyo.test').set({ note: 'admin' });
    await db.collection('wallets').doc('alice').set({ uid: 'alice', balance: 25000, totalEarned: 25000, pendingWithdrawal: 0, totalWithdrawn: 0 });

    const req = wrap(H.requestWithdrawal);
    const resolve = wrap(H.adminResolveWithdrawal);
    const form = (amount) => ({
      fullName: 'Alice Doe', phone: '+255712345678', amount,
      idType: 'national_id', idPhotoPath: 'withdrawals/alice/1_id.jpg',
    });
    const alice = authOf('alice', 'alice@x.test');

    await expectHttpsError(req({ data: form(12000) }), 'unauthenticated');
    await expectHttpsError(req({ data: form(9999.99), auth: alice }), 'invalid-argument');
    await expectHttpsError(req({ data: form(-50000), auth: alice }), 'invalid-argument');
    await expectHttpsError(req({ data: form('abc'), auth: alice }), 'invalid-argument');
    await expectHttpsError(req({ data: form(NaN), auth: alice }), 'invalid-argument');
    await expectHttpsError(req({ data: form(25000.01), auth: alice }), 'failed-precondition');
    await expectHttpsError(req({ data: { ...form(12000), idPhotoPath: 'withdrawals/bob/x.jpg' }, auth: alice }), 'invalid-argument');

    // valid (string amount accepted and normalised)
    const r1 = await req({ data: form('12000'), auth: alice });
    let w = await wallet('alice');
    assert.equal(w.balance, 13000);
    assert.equal(w.pendingWithdrawal, 12000);
    const doc1 = (await db.doc(`withdrawalRequests/${r1.withdrawalId}`).get()).data();
    assert.equal(doc1.status, 'pending');
    assert.equal(doc1.amount, 12000);

    // non-admins / unverified admin email cannot resolve
    await expectHttpsError(resolve({ data: { withdrawalId: r1.withdrawalId, action: 'approve' }, auth: alice }), 'permission-denied');
    await expectHttpsError(resolve({ data: { withdrawalId: r1.withdrawalId, action: 'approve' }, auth: authOf('mallory', 'boss@moyo.test', false) }), 'permission-denied');
    await expectHttpsError(resolve({ data: { withdrawalId: r1.withdrawalId, action: 'approve' } }), 'permission-denied');

    const boss = authOf('bossUid', 'Boss@Moyo.test'); // case-insensitive match
    await resolve({ data: { withdrawalId: r1.withdrawalId, action: 'reject', note: 'ID blurry' }, auth: boss });
    w = await wallet('alice');
    assert.equal(w.balance, 25000);
    assert.equal(w.pendingWithdrawal, 0);
    // cannot flip a rejected request to paid
    await expectHttpsError(resolve({ data: { withdrawalId: r1.withdrawalId, action: 'approve' }, auth: boss }), 'failed-precondition');

    // two concurrent requests that together exceed the balance → exactly one wins
    const results = await Promise.allSettled([
      req({ data: form(15000), auth: alice }),
      req({ data: form(15000), auth: alice }),
    ]);
    const ok = results.filter((x) => x.status === 'fulfilled');
    assert.equal(ok.length, 1, JSON.stringify(results.map((x) => x.status)));
    w = await wallet('alice');
    assert.equal(w.balance, 10000);
    assert.equal(w.pendingWithdrawal, 15000);

    const wid = ok[0].value.withdrawalId;
    // double-click approve: concurrently → exactly one succeeds
    const appr = await Promise.allSettled([
      resolve({ data: { withdrawalId: wid, action: 'approve' }, auth: boss }),
      resolve({ data: { withdrawalId: wid, action: 'approve' }, auth: boss }),
    ]);
    assert.equal(appr.filter((x) => x.status === 'fulfilled').length, 1);
    w = await wallet('alice');
    assert.equal(w.balance, 10000);
    assert.equal(w.pendingWithdrawal, 0);
    assert.equal(w.totalWithdrawn, 15000);
    assert.equal((await db.doc(`withdrawalRequests/${wid}`).get()).data().status, 'paid');
    await expectHttpsError(resolve({ data: { withdrawalId: wid, action: 'reject' }, auth: boss }), 'failed-precondition');
    await expectHttpsError(resolve({ data: { withdrawalId: wid, action: 'delete' }, auth: boss }), 'invalid-argument');
    await expectHttpsError(resolve({ data: { withdrawalId: 'nope', action: 'approve' }, auth: boss }), 'not-found');

    const types = (await ledger('alice')).map((e) => e.type).sort();
    assert.deepEqual(types, ['withdrawal_hold', 'withdrawal_hold', 'withdrawal_paid', 'withdrawal_refund']);
  });

  // ---- Former bugs (were `todo`), now fixed ------------------------------

  test('FIXED: a forged ClickPesa webhook (no checksum, unknown to ClickPesa) activates nothing and pays nothing', async () => {
    await seedUser('alice');
    await seedUser('bob');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'bob', code);
    await seedPendingSubscription('subCP0000000000000009', 'bob', 50000);
    // The attacker (bob) knows his own orderReference. No checksum, and
    // ClickPesa's status API has no such payment (clickpesaScript empty):
    const r = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000009', '50000') });
    assert.equal(r.body.activated, undefined);
    const bob = (await db.doc('users/bob').get()).data();
    assert.notEqual(bob.isActive, true, 'forged webhook activated a subscription');
    assert.equal((await wallet('alice')).balance, undefined, 'forged webhook credited a commission');
    assert.equal((await db.doc('subscriptions/subCP0000000000000009').get()).data().status, 'PROCESSING');
    assert.ok(httpCalls.some(([m, u]) => m === 'GET' && u === '/payments/subCP0000000000000009'), 'ClickPesa status API consulted');

    // ClickPesa says it's still processing → not completed either.
    clickpesaScript.subCP0000000000000009 = { status: 'PROCESSING', collectedAmount: '0' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000009', '50000') });
    assert.notEqual((await db.doc('users/bob').get()).data().isActive, true);

    // A present-but-wrong checksum is rejected before anything else.
    clickpesaScript.subCP0000000000000009 = { status: 'SUCCESS', collectedAmount: '50000' };
    const bad = clickpesaReceived('subCP0000000000000009', '50000');
    bad.data.checksum = 'deadbeef';
    const rej = await callHttp(H.resolvePaymentClickPesa, { body: bad });
    assert.equal(rej.body.rejected, 'checksum mismatch');
    assert.notEqual((await db.doc('users/bob').get()).data().isActive, true);

    // Only when ClickPesa confirms the payment does it activate and pay.
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000009', '1') });
    assert.equal((await db.doc('users/bob').get()).data().isActive, true);
    assert.equal((await wallet('alice')).balance, 500);
  });

  test('FIXED: a later FAILED callback never downgrades a Completed subscription (ClickPesa and PesaPal)', async () => {
    await seedUser('dan');
    await seedPendingSubscription('subCP0000000000000010', 'dan', 10000);
    clickpesaScript.subCP0000000000000010 = { status: 'SUCCESS', collectedAmount: '10000' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000010', '10000') });
    clickpesaScript.subCP0000000000000010 = { status: 'FAILED', collectedAmount: '0' };
    await callHttp(H.resolvePaymentClickPesa, {
      body: { event: 'PAYMENT FAILED', data: { orderReference: 'subCP0000000000000010', status: 'FAILED' } },
    });
    assert.equal((await db.doc('subscriptions/subCP0000000000000010').get()).data().status, 'Completed');

    await seedPendingSubscription('subPP0000000000000011', 'dan', 10000, 'pesapal');
    pesapalScript.status = 'Completed'; pesapalScript.amount = 10000;
    const ipn = { method: 'GET', query: { OrderTrackingId: 't', OrderMerchantReference: 'subPP0000000000000011' } };
    await callHttp(H.resolvePayment, ipn);
    pesapalScript.status = 'Failed';
    await callHttp(H.resolvePayment, ipn);
    assert.equal((await db.doc('subscriptions/subPP0000000000000011').get()).data().status, 'Completed');
    pesapalScript.status = 'Completed';
  });

  test('FIXED: ClickPesa status API down → 503 so ClickPesa retries; nothing is trusted meanwhile', async () => {
    await seedUser('eve');
    await seedPendingSubscription('subCP0000000000000012', 'eve', 10000);
    clickpesaScript.subCP0000000000000012 = { status: 'SUCCESS', collectedAmount: '10000' };
    // Make only this lookup blow up.
    const original = clickpesaScript.subCP0000000000000012;
    Object.defineProperty(clickpesaScript, 'subCP0000000000000012', { get() { throw new Error('ECONNRESET'); }, configurable: true });
    const r = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000012', '10000') });
    assert.equal(r.status, 503);
    assert.notEqual((await db.doc('users/eve').get()).data().isActive, true);
    Object.defineProperty(clickpesaScript, 'subCP0000000000000012', { value: original, configurable: true, writable: true, enumerable: true });
  });

  test('FIXED: "new user only" uses the Auth account age — rewriting users.createdAt does not help', async () => {
    await seedUser('alice');
    await seedUser('old', { createdAt: Timestamp.fromDate(new Date('2024-01-01')) });
    const { code } = await H.assignReferralCode(db, 'alice');
    const oldAccount = { getAccountCreatedAt: async () => new Date('2024-01-01') };
    await expectHttpsError(H.applyReferralCodeFor(db, 'old', code, oldAccount), 'failed-precondition');
    // Even with a fresh-looking users.createdAt (which the rules now also forbid):
    await db.doc('users/old').set({ createdAt: Timestamp.now() }, { merge: true });
    await expectHttpsError(H.applyReferralCodeFor(db, 'old', code, oldAccount), 'failed-precondition');
    assert.equal((await db.doc('users/old').get()).data().referredBy, undefined);
    // Default lookup really reads the Auth emulator: a brand-new account passes.
    await seedUser('fresh', { createdAt: Timestamp.fromDate(new Date('2020-01-01')) });
    await H.applyReferralCodeFor(db, 'fresh', code);
    assert.equal((await db.doc('referralClaims/fresh').get()).data().referrerUid, 'alice');
  });

  test('FIXED: deleting and recreating the user doc does not allow a second referral claim; commission still goes to the first referrer', async () => {
    await seedUser('alice');
    await seedUser('mallory');
    await seedUser('bob');
    const a = await H.assignReferralCode(db, 'alice');
    const m = await H.assignReferralCode(db, 'mallory');
    await H.applyReferralCodeFor(db, 'bob', a.code);
    // (Rules now deny a client deleting its own user doc; simulate an admin delete.)
    await db.doc('users/bob').delete();
    await seedUser('bob');
    await expectHttpsError(H.applyReferralCodeFor(db, 'bob', m.code), 'failed-precondition');
    // users.referredBy is gone, but referralClaims still routes the commission.
    await seedPendingSubscription('subCP0000000000000013', 'bob', 20000);
    clickpesaScript.subCP0000000000000013 = { status: 'SUCCESS', collectedAmount: '20000' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000013', '20000') });
    assert.equal((await wallet('alice')).balance, 200);
    assert.equal((await wallet('mallory')).balance, undefined);
  });

  test('FIXED: commission backstop trigger fires only on the transition to Completed (and is idempotent)', async () => {
    const { becameCompleted, creditReferralOnCompletion } = require('../../wallet/commission');
    assert.equal(becameCompleted(null, { status: 'Completed' }), true);
    assert.equal(becameCompleted({ status: 'PROCESSING' }, { status: 'Completed' }), true);
    assert.equal(becameCompleted({ status: 'Completed' }, { status: 'Completed', referralCredit: {} }), false);
    assert.equal(becameCompleted({ status: 'PROCESSING' }, { status: 'Failed' }), false);
    assert.equal(becameCompleted({ status: 'Completed' }, null), false);

    // Simulate "inline credit failed after the batch committed": mark
    // Completed directly, then deliver the trigger event (twice).
    await seedUser('alice');
    await seedUser('bob');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'bob', code);
    await seedPendingSubscription('subCP0000000000000014', 'bob', 40000);
    const before = (await db.doc('subscriptions/subCP0000000000000014').get());
    await db.doc('subscriptions/subCP0000000000000014').set({ status: 'Completed' }, { merge: true });
    const after = (await db.doc('subscriptions/subCP0000000000000014').get());
    const trigger = wrap(creditReferralOnCompletion);
    const change = fft.makeChange(before, after);
    await trigger({ data: change, params: { subscriptionId: 'subCP0000000000000014' } });
    await trigger({ data: change, params: { subscriptionId: 'subCP0000000000000014' } });
    assert.equal((await wallet('alice')).balance, 400);
    assert.equal((await ledger('alice')).length, 1);
  });
  // ---- Tester re-verification (round 2) ------------------------------------

  test('RETEST: 503 → retry activates once; later duplicates never re-extend subscriptionExpiry', async () => {
    await seedUser('alice');
    await seedUser('fay');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'fay', code);
    await seedPendingSubscription('subCP0000000000000020', 'fay', 10000);
    Object.defineProperty(clickpesaScript, 'subCP0000000000000020', { get() { throw new Error('ETIMEDOUT'); }, configurable: true, enumerable: true });
    assert.equal((await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000020', '10000') })).status, 503);
    Object.defineProperty(clickpesaScript, 'subCP0000000000000020', { value: { status: 'SUCCESS', collectedAmount: '10000' }, configurable: true, writable: true, enumerable: true });
    const ok = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000020', '10000') });
    assert.equal(ok.body.activated, true);
    const u1 = (await db.doc('users/fay').get()).data();
    const sub1 = (await db.doc('subscriptions/subCP0000000000000020').get()).data();
    await new Promise((r) => setTimeout(r, 30));
    // more retries, some concurrent
    await Promise.all([1, 2, 3].map(() => callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000020', '10000') })));
    const u2 = (await db.doc('users/fay').get()).data();
    const sub2 = (await db.doc('subscriptions/subCP0000000000000020').get()).data();
    assert.equal(u2.subscriptionExpiry.toMillis(), u1.subscriptionExpiry.toMillis(), 'expiry re-extended by duplicate');
    assert.equal(sub2.expires_at, sub1.expires_at);
    assert.equal(u2.isActive, true);
    assert.equal((await wallet('alice')).balance, 100);
    assert.equal((await ledger('alice')).length, 1);
  });

  test('RETEST: inline credit and backstop trigger racing concurrently credit exactly once', async () => {
    const { creditReferralOnCompletion } = require('../../wallet/commission');
    await seedUser('alice');
    await seedUser('gus');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'gus', code);
    await seedPendingSubscription('subCP0000000000000021', 'gus', 70000);
    const before = await db.doc('subscriptions/subCP0000000000000021').get();
    clickpesaScript.subCP0000000000000021 = { status: 'SUCCESS', collectedAmount: '70000' };
    // First let the webhook mark it Completed, then race trigger deliveries
    // against more webhook deliveries.
    const trigger = wrap(creditReferralOnCompletion);
    const hook = () => callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000021', '70000') });
    const firstHook = hook();
    await firstHook;
    const after = await db.doc('subscriptions/subCP0000000000000021').get();
    const change = fft.makeChange(before, after);
    await Promise.all([
      trigger({ data: change, params: { subscriptionId: 'subCP0000000000000021' } }),
      trigger({ data: change, params: { subscriptionId: 'subCP0000000000000021' } }),
      hook(), hook(),
      trigger({ data: change, params: { subscriptionId: 'subCP0000000000000021' } }),
    ]);
    assert.equal((await wallet('alice')).balance, 700);
    assert.equal((await ledger('alice')).length, 1);
    // And a full race from PROCESSING: hooks + direct credits in parallel.
    await seedPendingSubscription('subCP0000000000000022', 'gus', 10000);
    clickpesaScript.subCP0000000000000022 = { status: 'SUCCESS', collectedAmount: '10000' };
    await Promise.all([
      callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000022', '10000') }),
      callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000022', '10000') }),
      require('../../wallet/commission').creditReferralCommissionSafely('subCP0000000000000022', db),
      require('../../wallet/commission').creditReferralCommissionSafely('subCP0000000000000022', db),
    ]);
    // the direct credits may have run before Completed (no-op) — top up with one more
    await require('../../wallet/commission').creditReferralCommissionSafely('subCP0000000000000022', db);
    assert.equal((await wallet('alice')).balance, 800);
    assert.equal((await ledger('alice')).length, 2);
  });

  test('FIXED: ClickPesa reports SUCCESS but collectedAmount below the package price → recorded as Underpaid, not activated, no commission', async () => {
    await seedUser('alice');
    await seedUser('hal');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'hal', code);
    await seedPendingSubscription('subCP0000000000000023', 'hal', 50000);
    clickpesaScript.subCP0000000000000023 = { status: 'SUCCESS', collectedAmount: 100 };
    const r = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000023', '50000') });
    assert.equal(r.body.activated, false);
    assert.notEqual((await db.doc('users/hal').get()).data().isActive, true, 'underpaid payment activated the subscription');
    const sub = (await db.doc('subscriptions/subCP0000000000000023').get()).data();
    assert.equal(sub.status, 'Underpaid');
    assert.equal(sub.payment_amount, 100);
    assert.equal((await wallet('alice')).balance, undefined);
    // A later full payment for the same order still activates.
    clickpesaScript.subCP0000000000000023 = { status: 'SUCCESS', collectedAmount: 50000 };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000023', '50000') });
    assert.equal((await db.doc('users/hal').get()).data().isActive, true);
    assert.equal((await wallet('alice')).balance, 500);
  });

  test('FIXED: REFUNDED / REVERSED / PENDING / ON-HOLD never activate; a record for another orderReference is ignored', async () => {
    await seedUser('ivy');
    await seedPendingSubscription('subCP0000000000000025', 'ivy', 10000);
    for (const status of ['REFUNDED', 'REVERSED', 'PENDING', 'ON-HOLD', 'PROCESSING']) {
      clickpesaScript.subCP0000000000000025 = { status, collectedAmount: 10000 };
      await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000025', '10000') });
      assert.notEqual((await db.doc('users/ivy').get()).data().isActive, true, status);
      assert.equal((await db.doc('subscriptions/subCP0000000000000025').get()).data().status, status);
    }
    // ClickPesa answering with some other order's successful payment must not count.
    const { fetchClickPesaPayment } = require('../../payments/clickpesa');
    clickpesaScript.subCP0000000000000025 = { status: 'SUCCESS', collectedAmount: 10000, orderReference: 'someOtherOrder' };
    assert.equal(await fetchClickPesaPayment('subCP0000000000000025'), null);
    const r = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000025', '10000') });
    assert.equal(r.body.reason, 'unverified');
    assert.notEqual((await db.doc('users/ivy').get()).data().isActive, true);
  });

  test('FIXED: PesaPal IPN with a verified amount below the package price is not activated', async () => {
    await seedUser('jon');
    await seedPendingSubscription('subPP0000000000000026', 'jon', 30000, 'pesapal');
    pesapalScript.status = 'Completed'; pesapalScript.amount = 2999;
    const ipn = { method: 'GET', query: { OrderTrackingId: 't', OrderMerchantReference: 'subPP0000000000000026' } };
    const r = await callHttp(H.resolvePayment, ipn);
    assert.equal(r.body.activated, false);
    assert.equal((await db.doc('subscriptions/subPP0000000000000026').get()).data().status, 'Underpaid');
    assert.notEqual((await db.doc('users/jon').get()).data().isActive, true);
    pesapalScript.amount = 30000;
    await callHttp(H.resolvePayment, ipn);
    assert.equal((await db.doc('users/jon').get()).data().isActive, true);
  });

  test('RETEST: legacy user doc without createdAt/isActive completes payment and gets activated', async () => {
    await getAuth().createUser({ uid: 'legacy' });
    await db.doc('users/legacy').set({ fullName: 'L', country: 'Tanzania', region: 'Dodoma', phone: '+2557', fcmTokens: ['t'] });
    await seedPendingSubscription('subCP0000000000000024', 'legacy', 10000);
    clickpesaScript.subCP0000000000000024 = { status: 'SUCCESS', collectedAmount: '10000' };
    const r = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000024', '10000') });
    assert.equal(r.body.activated, true);
    const u = (await db.doc('users/legacy').get()).data();
    assert.equal(u.isActive, true);
    assert.deepEqual(u.fcmTokens, ['t']);
  });
  test('RETEST3: old pending subscriptions with amount missing / 0 / formatted string still complete on a real payment', async () => {
    await seedUser('kim');
    const cases = [
      ['subCP0000000000000030', undefined, '10000'],
      ['subCP0000000000000031', 0, '10000'],
      ['subCP0000000000000032', '25,000', '25000'],
      ['subCP0000000000000033', '25000', 25000],
      ['subCP0000000000000034', 25000, '25000.00'],
    ];
    for (const [id, amount, collected] of cases) {
      await db.collection('subscriptions').doc(id).set({
        userId: 'kim', packageId: 'pkg1', durationDays: 30, currency: 'TZS', provider: 'clickpesa', status: 'PROCESSING',
        ...(amount === undefined ? {} : { amount }),
      });
      clickpesaScript[id] = { status: 'SUCCESS', collectedAmount: collected };
      const r = await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived(id, String(collected)) });
      assert.equal(r.body.activated, true, `${id} amount=${amount} collected=${collected}: ${JSON.stringify(r.body)}`);
      assert.equal((await db.doc(`subscriptions/${id}`).get()).data().status, 'Completed');
    }
    // PesaPal old pending sub with string amount
    await db.collection('subscriptions').doc('subPP0000000000000035').set({ userId: 'kim', packageId: 'pkg1', durationDays: 30, amount: '30000', status: 'PENDING' });
    pesapalScript.status = 'Completed'; pesapalScript.amount = 30000;
    const p = await callHttp(H.resolvePayment, { method: 'GET', query: { OrderTrackingId: 't', OrderMerchantReference: 'subPP0000000000000035' } });
    assert.equal(p.body.activated, true);
    // Verified amount missing/0 is refused even when the status says paid.
    await seedPendingSubscription('subCP0000000000000036', 'kim', 10000);
    clickpesaScript.subCP0000000000000036 = { status: 'SUCCESS' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000036', '10000') });
    assert.equal((await db.doc('subscriptions/subCP0000000000000036').get()).data().status, 'Underpaid');
  });

  test('RETEST3: Underpaid → Completed later: inline + backstop trigger (concurrent) credit exactly once; duplicate Underpaid callbacks harmless', async () => {
    const { creditReferralOnCompletion } = require('../../wallet/commission');
    await seedUser('alice');
    await seedUser('lou');
    const { code } = await H.assignReferralCode(db, 'alice');
    await H.applyReferralCodeFor(db, 'lou', code);
    await seedPendingSubscription('subCP0000000000000037', 'lou', 20000);
    clickpesaScript.subCP0000000000000037 = { status: 'SUCCESS', collectedAmount: '5000' };
    await Promise.all([1, 2].map(() => callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000037', '5000') })));
    const before = await db.doc('subscriptions/subCP0000000000000037').get();
    assert.equal(before.data().status, 'Underpaid');
    // Trigger on the Underpaid write is a no-op
    await wrap(creditReferralOnCompletion)({ data: fft.makeChange(await db.doc('subscriptions/subCP0000000000000037').get(), before), params: { subscriptionId: 'subCP0000000000000037' } });
    assert.equal((await wallet('alice')).balance, undefined);
    clickpesaScript.subCP0000000000000037 = { status: 'SUCCESS', collectedAmount: '20000' };
    await callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000037', '20000') });
    const after = await db.doc('subscriptions/subCP0000000000000037').get();
    const change = fft.makeChange(before, after);
    const trigger = wrap(creditReferralOnCompletion);
    await Promise.all([
      trigger({ data: change, params: { subscriptionId: 'subCP0000000000000037' } }),
      trigger({ data: change, params: { subscriptionId: 'subCP0000000000000037' } }),
      callHttp(H.resolvePaymentClickPesa, { body: clickpesaReceived('subCP0000000000000037', '20000') }),
    ]);
    assert.equal((await wallet('alice')).balance, 200);
    assert.equal((await ledger('alice')).length, 1);
    assert.equal((await db.doc('users/lou').get()).data().isActive, true);
  });
});
