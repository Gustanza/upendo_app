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

  // The paths below are the ones the app uploads to now (lib/utils/
  // storage_paths.dart). None of them may depend on Firestore docs: in
  // production storage.rules' firestore.get/exists are denied unless an
  // extra IAM role is granted, which the emulator never checks. Using a
  // conversation / group that has NO Firestore docs proves that.
  test('1:1 chat: participants upload images/video/PDF/audio with no conversation doc; limits enforced', async () => {
    const cid = 'alice_bob'; // never written to Firestore in this suite
    await assertSucceeds(put('alice', `conversations/${cid}/m1/0_a.jpg`, MB, 'image/jpeg'));
    await assertSucceeds(put('bob', `conversations/${cid}/m2/0_v.mp4`, 5 * MB, 'video/mp4'));
    await assertSucceeds(put('alice', `conversations/${cid}/m3/0_doc.pdf`, 50 * MB, 'application/pdf'));
    await assertSucceeds(put('bob', `conversations/${cid}/m4/0_a.m4a`, MB, 'audio/mp4'));
    await assertSucceeds(getBytes(ref(storageAs('bob'), `conversations/${cid}/m1/0_a.jpg`)));
    // outsiders, malformed ids, oversized/odd files
    await assertFails(put('mallory', `conversations/${cid}/m5/0_a.jpg`, 1000, 'image/jpeg'));
    await assertFails(getBytes(ref(storageAs('mallory'), `conversations/${cid}/m1/0_a.jpg`)));
    await assertFails(put('alice', 'conversations/alice_bob_mallory/m1/0_a.jpg', 1000, 'image/jpeg'));
    await assertFails(put('alice', 'conversations/alice/m1/0_a.jpg', 1000, 'image/jpeg'));
    await assertFails(put('alice', `conversations/${cid}/m6/0_big.pdf`, 50 * MB + 1, 'application/pdf'));
    await assertFails(put('alice', `conversations/${cid}/m6/1_x.exe`, 10, 'application/octet-stream'));
  });

  test("group photo: uploaded into the creator's own folder before the group exists", async () => {
    await assertSucceeds(put('carol', 'userGroups/brandNew/photo/carol/1.jpg', 2000, 'image/jpeg'));
    await assertSucceeds(getBytes(ref(storageAs('dave'), 'userGroups/brandNew/photo/carol/1.jpg')));
    await assertFails(put('dave', 'userGroups/brandNew/photo/carol/2.jpg', 2000, 'image/jpeg'));
    await assertFails(put('carol', 'userGroups/brandNew/photo/carol/3.pdf', 2000, 'application/pdf'));
    await assertFails(put('carol', 'userGroups/brandNew/photo/carol/4.jpg', 5 * MB, 'image/jpeg'));
  });

  test('group post/chat files: uploader folder only, community limits, no membership lookup needed', async () => {
    await assertSucceeds(put('bob', 'userGroups/noDocs/posts/p1/bob/0_a.jpg', 1000, 'image/jpeg'));
    await assertSucceeds(put('bob', 'userGroups/noDocs/posts/p1/bob/1_v.mp4', 2 * MB, 'video/mp4'));
    await assertSucceeds(put('bob', 'userGroups/noDocs/messages/m1/bob/0_d.pdf', 2 * MB, 'application/pdf'));
    await assertSucceeds(put('bob', 'userGroups/noDocs/messages/m1/bob/1_a.mp3', MB, 'audio/mpeg'));
    await assertSucceeds(getBytes(ref(storageAs('bob'), 'userGroups/noDocs/posts/p1/bob/0_a.jpg')));
    await assertFails(put('mallory', 'userGroups/noDocs/posts/p1/bob/2_a.jpg', 1000, 'image/jpeg'));
    await assertFails(put('bob', 'userGroups/noDocs/other/p1/bob/0_a.jpg', 1000, 'image/jpeg'));
    await assertFails(put('bob', 'userGroups/noDocs/posts/p1/bob/3_big.pdf', 50 * MB + 1, 'application/pdf'));
    // a member of g1 can read another member's file (lookup branch, needs the IAM grant in prod)
    await assertSucceeds(put('bob', 'userGroups/g1/posts/p9/bob/0_a.jpg', 1000, 'image/jpeg'));
    await assertSucceeds(getBytes(ref(storageAs('owner'), 'userGroups/g1/posts/p9/bob/0_a.jpg')));
    await assertFails(getBytes(ref(storageAs('mallory'), 'userGroups/g1/posts/p9/bob/0_a.jpg')));
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
