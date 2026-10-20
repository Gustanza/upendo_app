// storage.rules tests — needs the Storage AND Firestore emulators (group
// membership is a cross-service firestore.exists() lookup). Run with:
//   npm run test:emulator
const { test, describe, before, after } = require('node:test');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { ref, uploadBytes, getBytes } = require('firebase/storage');
const { doc, setDoc } = require('firebase/firestore');

const hasEmulators = !!(process.env.FIREBASE_STORAGE_EMULATOR_HOST && process.env.FIRESTORE_EMULATOR_HOST);
let env;
const MB = 1024 * 1024;

const bytes = (n) => new Uint8Array(n);
const storageAs = (uid) => env.authenticatedContext(uid).storage();
const put = (uid, p, size, contentType) => uploadBytes(ref(storageAs(uid), p), bytes(size), { contentType });

describe('storage.rules', { skip: !hasEmulators && 'Storage/Firestore emulators not running' }, () => {
  before(async () => {
    const [sHost, sPort] = process.env.FIREBASE_STORAGE_EMULATOR_HOST.split(':');
    const [fHost, fPort] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
    env = await initializeTestEnvironment({
      projectId: 'demo-moyo-test',
      storage: {
        host: sHost,
        port: Number(sPort),
        rules: fs.readFileSync(path.join(__dirname, '../../../storage.rules'), 'utf8'),
      },
      firestore: {
        host: fHost,
        port: Number(fPort),
        rules: fs.readFileSync(path.join(__dirname, '../../../firestore.rules'), 'utf8'),
      },
    });
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'userGroups/g1'), { ownerId: 'owner', name: 'G', subcategoryId: 'c1' });
      await setDoc(doc(db, 'userGroups/g1/members/owner'), { role: 'owner' });
      await setDoc(doc(db, 'userGroups/g1/members/bob'), { role: 'member' });
    });
  });
  after(async () => { await env?.cleanup(); });

  test('subcategory feeds: PDF and audio up to 50 MB, other types refused', async () => {
    await assertSucceeds(put('alice', 'subcategoryFeeds/c1/posts/p1/0_doc.pdf', 2 * MB, 'application/pdf'));
    await assertSucceeds(put('alice', 'subcategoryFeeds/c1/messages/m1/0_a.mp3', MB, 'audio/mpeg'));
    await assertFails(put('alice', 'subcategoryFeeds/c1/posts/p1/1_big.pdf', 50 * MB + 1, 'application/pdf'));
    await assertFails(put('alice', 'subcategoryFeeds/c1/posts/p1/2_x.exe', 10, 'application/octet-stream'));
    await assertFails(put('alice', 'subcategoryFeeds/c1/other/p1/x.pdf', 10, 'application/pdf'));
  });

  test('group files: members only (the catch-all no longer overrides this)', async () => {
    await assertSucceeds(put('bob', 'userGroups/g1/posts/p1/0_a.jpg', 1000, 'image/jpeg'));
    await assertFails(put('mallory', 'userGroups/g1/posts/p1/0_a.jpg', 1000, 'image/jpeg'));
    await assertSucceeds(put('owner', 'userGroups/g1/photo/1.jpg', 1000, 'image/jpeg'));
    await assertFails(put('bob', 'userGroups/g1/photo/2.jpg', 1000, 'image/jpeg'));
    await assertFails(getBytes(ref(storageAs('mallory'), 'userGroups/g1/posts/p1/0_a.jpg')));
  });

  test('withdrawal ID photos: private to the user', async () => {
    await assertSucceeds(put('alice', 'withdrawals/alice/1_id.jpg', 1000, 'image/jpeg'));
    await assertFails(put('bob', 'withdrawals/alice/2_id.jpg', 1000, 'image/jpeg'));
    await assertFails(getBytes(ref(storageAs('bob'), 'withdrawals/alice/1_id.jpg')));
    await assertSucceeds(getBytes(ref(storageAs('alice'), 'withdrawals/alice/1_id.jpg')));
  });

  test('admin-uploaded folders keep the permissive signed-in posture', async () => {
    await assertSucceeds(put('admin', 'thumbnails/123_x.png', 1000, 'image/png'));
    await assertSucceeds(put('admin', 'posts/videos/123_x.mp4', 1000, 'video/mp4'));
    await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), 'thumbnails/y.png'), bytes(10)));
  });
});
