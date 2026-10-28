// TEST-ONLY: seeds the LOCAL Firebase emulators for the on-device journeys
// in integration_test/e2e_journeys_test.dart. Refuses to run unless the
// emulator env vars are set, so it can never write to production.
//
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//   FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 node test/device/seed-device-e2e.js
//
// The project id must equal the app's (lib/firebase_options.dart) because
// the Android app can't be re-pointed to a demo- project; the data only
// ever lives in the local emulators.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');

for (const v of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!process.env[v]) {
    console.error(`${v} is not set — refusing to seed (would hit production).`);
    process.exit(1);
  }
}

const PROJECT = process.env.SEED_PROJECT || 'moyoapptanzania-cf0e7';
initializeApp({ projectId: PROJECT });
const auth = getAuth();
const db = getFirestore();

const PASSWORD = 'secret123';
const USERS = [
  { key: 'A', email: 'alice@test.moyo', name: 'Alice Tester' },
  { key: 'B', email: 'bob@test.moyo', name: 'Bob Tester' },
  { key: 'C', email: 'carol@test.moyo', name: 'Carol Outsider' },
];

async function upsertUser(u) {
  let rec;
  try {
    rec = await auth.getUserByEmail(u.email);
  } catch {
    rec = await auth.createUser({ email: u.email, password: PASSWORD, displayName: u.name, emailVerified: true });
  }
  await db.doc(`users/${rec.uid}`).set({
    fullName: u.name,
    email: u.email,
    country: 'Tanzania',
    region: 'Dar es Salaam',
    phone: '+255700000000',
    isActive: true,
    subscriptionExpiry: Timestamp.fromDate(new Date(Date.now() + 30 * 864e5)),
    activePackageId: 'pkg-monthly',
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return rec.uid;
}

(async () => {
  const uids = {};
  for (const u of USERS) uids[u.key] = await upsertUser(u);

  await db.doc('categoryGroups/grp-e2e').set({ name: 'E2E Group', order: 0, iconCode: 0xe574, colorHex: 0xFF8B2942 });
  await db.doc('categories/cat-main').set({ name: 'E2E Main', iconCode: 0xe87d, colorHex: 0xFF8B2942, groupId: 'grp-e2e' });
  await db.doc('categories/cat-sub').set({ name: 'E2E Sub', iconCode: 0xe838, colorHex: 0xFF1565C0, parentId: 'cat-main' });

  const now = Date.now();
  await db.doc('posts/post-main').set({
    title: 'Main category topic', subtitle: 'Posted on the main category', description: 'main',
    type: 'article', thumbnail: '', file_url: '', category_id: 'cat-main',
    featured: false, hot: false, likeCount: 0, commentCount: 0,
    created_at: Timestamp.fromMillis(now - 60000),
  });
  await db.doc('posts/post-sub').set({
    title: 'Subcategory topic', subtitle: 'Posted on the subcategory', description: 'sub',
    type: 'article', thumbnail: '', file_url: '', category_id: 'cat-sub',
    featured: false, hot: false, likeCount: 0, commentCount: 0,
    created_at: Timestamp.fromMillis(now - 120000),
  });
  // An older post with no created_at (must still be listed).
  await db.doc('posts/post-sub-legacy').set({
    title: 'Legacy sub topic', subtitle: 'No created_at', type: 'article', category_id: 'cat-sub',
  });
  await db.doc('posts/post-other').set({ title: 'Unrelated topic', type: 'article', category_id: 'cat-other' });

  await db.doc('packages/pkg-monthly').set({ name: 'Monthly', price: 5000, durationDays: 30, active: true });

  console.log(JSON.stringify({ project: PROJECT, uids, password: PASSWORD }));
})().catch((e) => { console.error(e); process.exit(1); });
