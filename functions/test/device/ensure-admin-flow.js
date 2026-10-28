// TEST-ONLY: the dashboard's ensureAdmin flow end-to-end against the LOCAL
// emulators (auth + firestore + functions, project moyoapptanzania-cf0e7,
// functions/.env.local ADMIN_EMAILS=admin@test.moyo,...). Uses the same
// client SDK calls as vue/src/utils/adminBootstrap.js + CategoryGroupsView.
//
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//   node test/device/ensure-admin-flow.js
const assert = require('node:assert/strict');
const admin = require('firebase-admin/app');
const { getAuth: adminAuth } = require('firebase-admin/auth');
const { getFirestore: adminDb } = require('firebase-admin/firestore');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, signInWithEmailAndPassword, signOut } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, addDoc, collection, serverTimestamp, doc, getDoc } = require('firebase/firestore');
const { getFunctions, connectFunctionsEmulator, httpsCallable } = require('firebase/functions');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('emulator env vars not set — refusing'); process.exit(1);
}
const PROJECT = 'moyoapptanzania-cf0e7';
admin.initializeApp({ projectId: PROJECT });

async function user(email, verified) {
  try { await adminAuth().deleteUser((await adminAuth().getUserByEmail(email)).uid); } catch {}
  await adminAuth().createUser({ email, password: 'secret123', emailVerified: verified });
}

(async () => {
  await adminDb().doc('admins/admin@test.moyo').delete();
  await adminDb().doc('admins/mallory@test.moyo').delete();
  await user('admin@test.moyo', true);
  await user('mallory@test.moyo', true);

  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake-api-key', authDomain: 'x' }, 'flow');
  const auth = getAuth(app); connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const db = getFirestore(app); connectFirestoreEmulator(db, '127.0.0.1', 8080);
  const fns = getFunctions(app); connectFunctionsEmulator(fns, '127.0.0.1', 5001);
  const ensureAdmin = httpsCallable(fns, 'ensureAdmin');
  const newGroup = () => addDoc(collection(db, 'categoryGroups'),
    { name: 'Flow group ' + Date.now(), order: 99, iconCode: 0xe574, colorHex: 0xFF8B2942, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
  const out = [];
  const denied = async (what, p) => {
    try { await p; } catch (e) { assert.match(String(e.code), /permission-denied/); out.push(`DENIED ok: ${what}`); return; }
    throw new Error(`${what} unexpectedly succeeded`);
  };

  // Unauthenticated call
  try { await ensureAdmin(); throw new Error('unauth call succeeded'); }
  catch (e) { assert.equal(e.code, 'functions/unauthenticated'); out.push('ensureAdmin unauthenticated -> functions/unauthenticated'); }

  // 1. Allowlisted admin: before bootstrap the write fails (the reported bug)
  await signInWithEmailAndPassword(auth, 'admin@test.moyo', 'secret123');
  await denied('admin creates category group BEFORE ensureAdmin', newGroup());
  const r1 = (await ensureAdmin()).data;
  assert.deepEqual(r1, { admin: true, created: true });
  const r2 = (await ensureAdmin()).data;
  assert.deepEqual(r2, { admin: true, created: false });
  out.push(`ensureAdmin(admin) -> ${JSON.stringify(r1)} then ${JSON.stringify(r2)}`);
  const ref = await newGroup();
  out.push(`admin creates category group AFTER ensureAdmin -> ok (${ref.id})`);
  await signOut(auth);

  // 2. Verified but not allowlisted, trying to pass someone else's email
  await signInWithEmailAndPassword(auth, 'mallory@test.moyo', 'secret123');
  const r3 = (await ensureAdmin({ email: 'admin@test.moyo' })).data;
  assert.deepEqual(r3, { admin: false, created: false });
  out.push(`ensureAdmin(mallory, data.email=admin) -> ${JSON.stringify(r3)}`);
  assert.equal((await adminDb().doc('admins/mallory@test.moyo').get()).exists, false);
  await denied('mallory creates category group', newGroup());
  await denied('mallory writes admins/mallory@test.moyo directly',
    require('firebase/firestore').setDoc(doc(db, 'admins/mallory@test.moyo'), { email: 'mallory@test.moyo' }));
  await signOut(auth);

  // 3. Allowlisted address but unverified token
  await adminAuth().updateUser((await adminAuth().getUserByEmail('admin@test.moyo')).uid, { emailVerified: false });
  await adminDb().doc('admins/admin@test.moyo').delete();
  await signInWithEmailAndPassword(auth, 'admin@test.moyo', 'secret123');
  const r4 = (await ensureAdmin()).data;
  assert.deepEqual(r4, { admin: false, created: false });
  assert.equal((await adminDb().doc('admins/admin@test.moyo').get()).exists, false);
  out.push(`ensureAdmin(allowlisted but UNVERIFIED) -> ${JSON.stringify(r4)}, no doc`);
  await adminAuth().updateUser((await adminAuth().getUserByEmail('admin@test.moyo')).uid, { emailVerified: true });
  await signOut(auth);

  await deleteApp(app);
  console.log(out.map((l) => 'PASS ' + l).join('\n'));
  process.exit(0);
})().catch((e) => { console.error('FAIL', e); process.exit(1); });
