// ensureAdmin against the Firestore emulator, then the admin-only rules it
// unlocks (category groups + the groupId batch on categories). Run with:
//   npm run test:emulator
const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, addDoc, collection, writeBatch, serverTimestamp, deleteField, setDoc } = require('firebase/firestore');

const PROJECT_ID = 'demo-moyo-test';
const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { ensureAdminFor } = require('../../admin/ensureAdmin');

const ADMIN = 'moyoapptanzania@gmail.com';
const LIST = [ADMIN];
const authOf = (uid, email, verified = true) => ({ uid, token: { email, email_verified: verified } });
let env; let db;

describe('ensureAdmin bootstrap (Firestore emulator)', { skip: !hasEmulator && 'FIRESTORE_EMULATOR_HOST not set' }, () => {
  before(async () => {
    if (!getApps().length) initializeApp({ projectId: PROJECT_ID });
    db = getFirestore();
    const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
    env = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '../../../firestore.rules'), 'utf8') },
    });
  });
  after(async () => { await env?.cleanup(); });
  beforeEach(async () => { await env.clearFirestore(); });

  test('BUG: without an admins doc the dashboard cannot create a category group', async () => {
    const adminDb = env.authenticatedContext('adminUid', { email: ADMIN, email_verified: true }).firestore();
    await assertFails(addDoc(collection(adminDb, 'categoryGroups'), { name: 'Elimu', order: 0 }));
  });

  test('creates admins/{email} for an allowlisted verified caller, idempotently', async () => {
    assert.deepEqual(await ensureAdminFor(db, authOf('adminUid', 'MoyoAppTanzania@gmail.com'), LIST), { admin: true, created: true });
    const snap = await db.doc(`admins/${ADMIN}`).get();
    assert.equal(snap.exists, true);
    assert.equal(snap.data().uid, 'adminUid');
    assert.deepEqual(await ensureAdminFor(db, authOf('adminUid', ADMIN), LIST), { admin: true, created: false });
  });

  test('never creates a doc for non-allowlisted, unverified or anonymous callers', async () => {
    assert.deepEqual(await ensureAdminFor(db, authOf('x', 'mallory@gmail.com'), LIST), { admin: false, created: false });
    assert.deepEqual(await ensureAdminFor(db, authOf('x', ADMIN, false), LIST), { admin: false, created: false });
    await assert.rejects(ensureAdminFor(db, null, LIST), (e) => e.code === 'unauthenticated');
    assert.equal((await db.collection('admins').get()).size, 0);
  });

  test('a hand-made admins doc still counts even if the email is not allowlisted', async () => {
    await db.doc('admins/helper@gmail.com').set({ addedBy: 'console' });
    assert.deepEqual(await ensureAdminFor(db, authOf('h', 'helper@gmail.com'), LIST), { admin: true, created: false });
  });

  test('after bootstrap: New Group save (group + chunked groupId batch on categories) succeeds', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const s = ctx.firestore();
      for (let i = 0; i < 5; i++) await setDoc(doc(s, 'categories', `main${i}`), { name: `Main ${i}` });
    });
    await ensureAdminFor(db, authOf('adminUid', ADMIN), LIST);
    const a = env.authenticatedContext('adminUid', { email: ADMIN, email_verified: true }).firestore();
    // Exact CategoryGroupsView.save() writes.
    const g = await assertSucceeds(addDoc(collection(a, 'categoryGroups'), {
      name: 'Elimu', order: 1, iconCode: 0xe574, colorHex: 0xFF8B2942, updatedAt: serverTimestamp(), createdAt: serverTimestamp(),
    }));
    const batch = writeBatch(a);
    for (let i = 0; i < 5; i++) batch.update(doc(a, 'categories', `main${i}`), { groupId: g.id, updatedAt: serverTimestamp() });
    await assertSucceeds(batch.commit());
    const undo = writeBatch(a);
    undo.update(doc(a, 'categories', 'main0'), { groupId: deleteField(), updatedAt: serverTimestamp() });
    await assertSucceeds(undo.commit());
    // The doc it created is not writable by clients, so no one can self-promote.
    await assertFails(setDoc(doc(env.authenticatedContext('m', { email: 'm@x.com', email_verified: true }).firestore(), 'admins/m@x.com'), { x: 1 }));
  });
});
