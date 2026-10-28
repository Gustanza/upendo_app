// firestore.rules tests (@firebase/rules-unit-testing + Firestore emulator).
// Run with:  npm run test:emulator   — skipped without FIRESTORE_EMULATOR_HOST.
const { test, describe, before, after, beforeEach } = require('node:test');
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, writeBatch,
  serverTimestamp, Timestamp,
} = require('firebase/firestore');

const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
let env;

const as = (uid, email) =>
  env.authenticatedContext(uid, email ? { email, email_verified: true } : {}).firestore();

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

describe('firestore.rules', { skip: !hasEmulator && 'FIRESTORE_EMULATOR_HOST not set' }, () => {
  before(async () => {
    const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
    env = await initializeTestEnvironment({
      projectId: 'demo-moyo-test',
      firestore: {
        host,
        port: Number(port),
        rules: fs.readFileSync(path.join(__dirname, '../../../firestore.rules'), 'utf8'),
      },
    });
  });
  after(async () => { await env?.cleanup(); });
  beforeEach(async () => { await env.clearFirestore(); });

  describe('delete chat for me', () => {
    beforeEach(() => seed((db) => setDoc(doc(db, 'conversations/alice_bob'), {
      participants: ['alice', 'bob'],
      participantNames: { alice: 'Alice', bob: 'Bob' },
      lastMessage: { text: 'hi', senderId: 'bob' },
      updatedAt: Timestamp.now(),
      deletedAt: { bob: Timestamp.fromDate(new Date('2026-01-01')) },
    })));

    test('a participant may stamp only their own deletedAt with the server time', async () => {
      await assertSucceeds(updateDoc(doc(as('alice'), 'conversations/alice_bob'), { 'deletedAt.alice': serverTimestamp() }));
    });

    test("cannot touch the other participant's marker, other fields, or use a client time", async () => {
      const db = as('alice');
      await assertFails(updateDoc(doc(db, 'conversations/alice_bob'), { 'deletedAt.bob': serverTimestamp() }));
      await assertFails(updateDoc(doc(db, 'conversations/alice_bob'), {
        'deletedAt.alice': serverTimestamp(), lastMessage: null,
      }));
      await assertFails(updateDoc(doc(db, 'conversations/alice_bob'), { 'deletedAt.alice': Timestamp.fromDate(new Date('2030-01-01')) }));
      await assertFails(updateDoc(doc(db, 'conversations/alice_bob'), { updatedAt: serverTimestamp() }));
      await assertFails(deleteDoc(doc(db, 'conversations/alice_bob')));
    });

    test('non-participants cannot', async () => {
      await assertFails(updateDoc(doc(as('mallory'), 'conversations/alice_bob'), { 'deletedAt.mallory': serverTimestamp() }));
    });
  });

  describe('1:1 chat attachments', () => {
    beforeEach(() => seed((db) => setDoc(doc(db, 'conversations/alice_bob'), {
      participants: ['alice', 'bob'], participantNames: {}, lastMessage: null, updatedAt: Timestamp.now(),
    })));
    const msg = (attachments, text = '') => ({ senderId: 'alice', text, createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null, attachments });
    const att = (p, type) => ({ type, url: 'https://x', path: p, name: 'n', size: 1 });

    test("images, video, PDF and audio in this message's folder are accepted (text may be empty)", async () => {
      const a = as('alice');
      await assertSucceeds(setDoc(doc(a, 'conversations/alice_bob/messages/m1'), msg([
        att('conversations/alice_bob/m1/0_a.jpg', 'image'), att('conversations/alice_bob/m1/1_v.mp4', 'video'),
        att('conversations/alice_bob/m1/2_d.pdf', 'pdf'), att('conversations/alice_bob/m1/3_a.m4a', 'audio'),
      ])));
      await assertSucceeds(setDoc(doc(a, 'conversations/alice_bob/messages/m2'), msg([], 'just text')));
    });

    test('files from another conversation/message, or a non-participant, are refused', async () => {
      const a = as('alice');
      await assertFails(setDoc(doc(a, 'conversations/alice_bob/messages/m3'), msg([att('conversations/alice_carol/m3/0_a.jpg', 'image')])));
      await assertFails(setDoc(doc(a, 'conversations/alice_bob/messages/m4'), msg([att('conversations/alice_bob/m1/0_a.jpg', 'image')])));
      await assertFails(setDoc(doc(a, 'conversations/alice_bob/messages/m5'), msg([], '')));
      await assertFails(setDoc(doc(as('mallory'), 'conversations/alice_bob/messages/m6'), { ...msg([att('conversations/alice_bob/m6/0_a.jpg', 'image')]), senderId: 'mallory' }));
    });
  });

  describe('referral fields and wallet are server-only', () => {
    beforeEach(() => seed(async (db) => {
      await setDoc(doc(db, 'users/alice'), { fullName: 'Alice', referredBy: 'carol', referralCode: 'AB2C' });
      await setDoc(doc(db, 'wallets/alice'), { balance: 100 });
      await setDoc(doc(db, 'wallets/alice/transactions/referral_x'), { amount: 100 });
      await setDoc(doc(db, 'withdrawalRequests/w1'), { uid: 'alice', amount: 10000, status: 'pending' });
    }));

    test('profile edits still work, referral fields cannot be set or changed', async () => {
      const db = as('alice');
      await assertSucceeds(updateDoc(doc(db, 'users/alice'), { fullName: 'Alice J.' }));
      await assertFails(updateDoc(doc(db, 'users/alice'), { referredBy: 'mallory' }));
      await assertFails(updateDoc(doc(db, 'users/alice'), { referralCode: 'ZZZZ' }));
      await assertFails(setDoc(doc(as('newbie'), 'users/newbie'), { fullName: 'N', referredBy: 'alice' }));
      await assertSucceeds(setDoc(doc(as('newbie'), 'users/newbie'), { fullName: 'N' }));
    });

    test('owners read their wallet/ledger/requests; nobody writes them', async () => {
      const alice = as('alice');
      await assertSucceeds(getDoc(doc(alice, 'wallets/alice')));
      await assertSucceeds(getDoc(doc(alice, 'wallets/alice/transactions/referral_x')));
      await assertSucceeds(getDoc(doc(alice, 'withdrawalRequests/w1')));
      await assertFails(setDoc(doc(alice, 'wallets/alice'), { balance: 1e9 }));
      await assertFails(updateDoc(doc(alice, 'wallets/alice'), { balance: 1e9 }));
      await assertFails(setDoc(doc(alice, 'wallets/alice/transactions/fake'), { amount: 1e9 }));
      await assertFails(addDoc(collection(alice, 'withdrawalRequests'), { uid: 'alice', amount: 1 }));
      await assertFails(updateDoc(doc(alice, 'withdrawalRequests/w1'), { status: 'paid' }));
      await assertFails(setDoc(doc(alice, 'referralCodes/ZZZZ'), { uid: 'alice' }));
      const bob = as('bob');
      await assertFails(getDoc(doc(bob, 'wallets/alice')));
      await assertFails(getDoc(doc(bob, 'withdrawalRequests/w1')));
    });

    test('admins (admins/{email} doc) can read wallets and requests, still not write', async () => {
      await seed((db) => setDoc(doc(db, 'admins/boss@example.com'), {}));
      const admin = as('boss', 'Boss@Example.com');
      await assertSucceeds(getDoc(doc(admin, 'wallets/alice')));
      await assertSucceeds(getDoc(doc(admin, 'withdrawalRequests/w1')));
      await assertFails(updateDoc(doc(admin, 'wallets/alice'), { balance: 0 }));
    });
  });

  describe('category groups', () => {
    test('readable by users, writable by admins only', async () => {
      await seed((db) => setDoc(doc(db, 'admins/boss@example.com'), {}));
      await assertFails(setDoc(doc(as('alice'), 'categoryGroups/g'), { name: 'X' }));
      await assertSucceeds(setDoc(doc(as('boss', 'boss@example.com'), 'categoryGroups/g'), { name: 'X' }));
      await assertSucceeds(getDoc(doc(as('alice'), 'categoryGroups/g')));
      // An unverified email isn't enough.
      const unverified = env.authenticatedContext('boss2', { email: 'boss@example.com', email_verified: false }).firestore();
      await assertFails(setDoc(doc(unverified, 'categoryGroups/h'), { name: 'Y' }));
    });
  });

  describe('subcategory feeds', () => {
    test('anyone signed in posts; links are group-only; authors delete', async () => {
      const db = as('alice');
      const post = { authorId: 'alice', authorName: 'A', text: 'hello', createdAt: serverTimestamp(), attachments: [] };
      await assertSucceeds(setDoc(doc(db, 'subcategoryFeeds/c1/posts/p1'), post));
      await assertFails(setDoc(doc(db, 'subcategoryFeeds/c1/posts/p2'), { ...post, links: ['https://x.y'] }));
      await assertFails(setDoc(doc(db, 'subcategoryFeeds/c1/posts/p3'), { ...post, authorId: 'bob' }));
      await assertFails(setDoc(doc(db, 'subcategoryFeeds/c1/posts/p4'), { ...post, likeCount: 99 }));
      await assertFails(deleteDoc(doc(as('bob'), 'subcategoryFeeds/c1/posts/p1')));
      await assertSucceeds(addDoc(collection(as('bob'), 'subcategoryFeeds/c1/messages'), {
        senderId: 'bob', senderName: 'B', text: 'hi all', createdAt: serverTimestamp(),
      }));
      await assertSucceeds(deleteDoc(doc(db, 'subcategoryFeeds/c1/posts/p1')));
    });
  });

  describe('user groups', () => {
    async function createGroup(ownerDb, ownerUid, id = 'g1') {
      const batch = writeBatch(ownerDb);
      batch.set(doc(ownerDb, `userGroups/${id}`), {
        subcategoryId: 'c1', name: 'Readers', description: '', ownerId: ownerUid, ownerName: 'O',
        createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
      });
      batch.set(doc(ownerDb, `userGroups/${id}/members/${ownerUid}`), {
        name: 'O', role: 'owner', joinedAt: serverTimestamp(),
      });
      return batch.commit();
    }
    const post = (uid) => ({ authorId: uid, authorName: uid, text: 'hi', createdAt: serverTimestamp(), links: ['https://example.com'] });

    test('create group with owner membership; no fake owners, no memberCount', async () => {
      await assertSucceeds(createGroup(as('owner'), 'owner'));
      // Claiming ownership of an existing group is refused.
      await assertFails(setDoc(doc(as('bob'), 'userGroups/g1/members/bob'), { name: 'B', role: 'owner', joinedAt: serverTimestamp() }));
      await assertFails(setDoc(doc(as('bob'), 'userGroups/g2'), {
        subcategoryId: 'c1', name: 'X', ownerId: 'bob', memberCount: 1000, createdAt: serverTimestamp(),
      }));
      await assertFails(setDoc(doc(as('bob'), 'userGroups/g3'), { subcategoryId: 'c1', name: 'X', ownerId: 'owner' }));
    });

    test('only members post and read; owner moderates; removed members cannot rejoin', async () => {
      const owner = as('owner');
      await createGroup(owner, 'owner');
      const bob = as('bob');
      const carol = as('carol');

      await assertFails(setDoc(doc(bob, 'userGroups/g1/posts/p1'), post('bob')));
      await assertFails(getDoc(doc(bob, 'userGroups/g1/posts/any')));

      await assertSucceeds(setDoc(doc(bob, 'userGroups/g1/members/bob'), { name: 'B', role: 'member', joinedAt: serverTimestamp() }));
      await assertSucceeds(setDoc(doc(bob, 'userGroups/g1/posts/p1'), post('bob')));
      await assertSucceeds(addDoc(collection(bob, 'userGroups/g1/messages'), { senderId: 'bob', text: 'yo', createdAt: serverTimestamp() }));
      // Joining for someone else is refused.
      await assertFails(setDoc(doc(bob, 'userGroups/g1/members/carol'), { name: 'C', role: 'member', joinedAt: serverTimestamp() }));

      await assertSucceeds(setDoc(doc(carol, 'userGroups/g1/members/carol'), { name: 'C', role: 'member', joinedAt: serverTimestamp() }));
      await assertFails(deleteDoc(doc(carol, 'userGroups/g1/posts/p1')));     // not author, not owner
      await assertFails(deleteDoc(doc(carol, 'userGroups/g1/members/bob')));  // not owner
      await assertSucceeds(deleteDoc(doc(owner, 'userGroups/g1/posts/p1')));  // owner removes post

      // Owner removes Bob (member delete + ban); Bob can't come back.
      const batch = writeBatch(owner);
      batch.delete(doc(owner, 'userGroups/g1/members/bob'));
      batch.set(doc(owner, 'userGroups/g1/bans/bob'), { bannedBy: 'owner', bannedAt: serverTimestamp() });
      await assertSucceeds(batch.commit());
      await assertFails(setDoc(doc(bob, 'userGroups/g1/members/bob'), { name: 'B', role: 'member', joinedAt: serverTimestamp() }));

      // Members leave; the owner can't leave (deletes the group instead).
      await assertSucceeds(deleteDoc(doc(carol, 'userGroups/g1/members/carol')));
      await assertFails(deleteDoc(doc(owner, 'userGroups/g1/members/owner')));
      await assertFails(updateDoc(doc(carol, 'userGroups/g1'), { name: 'Hijacked' }));
      await assertSucceeds(updateDoc(doc(owner, 'userGroups/g1'), { name: 'Renamed', updatedAt: serverTimestamp() }));
      await assertFails(deleteDoc(doc(carol, 'userGroups/g1')));
      await assertSucceeds(deleteDoc(doc(owner, 'userGroups/g1')));
    });

    // UserGroupService.createGroup now uploads the picture first and
    // writes photoUrl/photoPath in the same batch as the group.
    test("group picture: must be a file in the owner's own photo folder of THIS group", async () => {
      const db = as('owner');
      const make = (id, photoPath) => {
        const batch = writeBatch(db);
        batch.set(doc(db, `userGroups/${id}`), {
          subcategoryId: 'c1', name: 'Readers', description: '', ownerId: 'owner', ownerName: 'O',
          photoUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/y?alt=media&token=t', photoPath,
          createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
        });
        batch.set(doc(db, `userGroups/${id}/members/owner`), { name: 'O', role: 'owner', joinedAt: serverTimestamp() });
        return batch.commit();
      };
      await assertSucceeds(make('gp1', 'userGroups/gp1/photo/owner/1.jpg'));
      await assertFails(make('gp2', 'userGroups/gp2/photo/bob/1.jpg'));       // someone else's upload
      await assertFails(make('gp3', 'userGroups/other/photo/owner/1.jpg'));   // another group's folder
      await assertFails(make('gp4', 'userGroups/gp4/photo/owner/a/b.jpg'));
      // Editing: the owner swaps the picture; still has to be their folder.
      await assertSucceeds(updateDoc(doc(db, 'userGroups/gp1'), {
        name: 'Readers', description: '', photoUrl: 'https://x/2', photoPath: 'userGroups/gp1/photo/owner/2.jpg', updatedAt: serverTimestamp(),
      }));
      await assertFails(updateDoc(doc(db, 'userGroups/gp1'), { photoUrl: 'https://x/3', photoPath: 'userGroups/gp1/photo/bob/3.jpg' }));
      // A rename without touching the picture is unaffected.
      await assertSucceeds(updateDoc(doc(db, 'userGroups/gp1'), { name: 'R2', updatedAt: serverTimestamp() }));
    });

    test("group posts/messages: attachments must be in the author's folder for that doc", async () => {
      await createGroup(as('owner'), 'owner');
      const bob = as('bob');
      await assertSucceeds(setDoc(doc(bob, 'userGroups/g1/members/bob'), { name: 'B', role: 'member', joinedAt: serverTimestamp() }));
      const att = (p, type = 'image') => ({ type, url: 'https://x', path: p, name: 'a', size: 1 });
      const files = (kind, id, uid) => ['0_a.jpg', '1_v.mp4', '2_d.pdf', '3_a.mp3']
        .map((f, i) => att(`userGroups/g1/${kind}/${id}/${uid}/${f}`, ['image', 'video', 'pdf', 'audio'][i]));
      await assertSucceeds(setDoc(doc(bob, 'userGroups/g1/posts/p1'), { ...post('bob'), attachments: files('posts', 'p1', 'bob') }));
      await assertSucceeds(setDoc(doc(bob, 'userGroups/g1/messages/m1'), {
        senderId: 'bob', senderName: 'B', text: '', createdAt: serverTimestamp(), attachments: files('messages', 'm1', 'bob'),
      }));
      // Someone else's files, another doc's folder, the legacy flat path, or a missing path are refused.
      await assertFails(setDoc(doc(bob, 'userGroups/g1/posts/p2'), { ...post('bob'), attachments: files('posts', 'p2', 'owner') }));
      await assertFails(setDoc(doc(bob, 'userGroups/g1/posts/p3'), { ...post('bob'), attachments: files('posts', 'p1', 'bob') }));
      await assertFails(setDoc(doc(bob, 'userGroups/g1/posts/p4'), { ...post('bob'), attachments: [att('userGroups/g1/posts/p4/0_a.jpg')] }));
      await assertFails(setDoc(doc(bob, 'userGroups/g1/posts/p5'), { ...post('bob'), attachments: [{ type: 'image', url: 'https://x' }] }));
      await assertFails(setDoc(doc(bob, 'userGroups/g1/messages/m2'), {
        senderId: 'bob', text: 'x', createdAt: serverTimestamp(), attachments: [att('conversations/a_b/m2/0_a.jpg')],
      }));
      // Ten attachments (the cap) are all checked; one bad entry at the end is refused.
      const ten = Array.from({ length: 10 }, (_, i) => att(`userGroups/g1/posts/p6/bob/${i}_a.pdf`, 'pdf'));
      await assertSucceeds(setDoc(doc(bob, 'userGroups/g1/posts/p6'), { ...post('bob'), attachments: ten }));
      const badLast = [...ten.slice(0, 9).map((x) => ({ ...x, path: x.path.replace('/p6/', '/p7/') })), att('userGroups/g1/posts/p7/owner/9_a.pdf', 'pdf')];
      await assertFails(setDoc(doc(bob, 'userGroups/g1/posts/p7'), { ...post('bob'), attachments: badLast }));
      // Non-members still can't post even with correctly placed files.
      await assertFails(setDoc(doc(as('zed'), 'userGroups/g1/posts/p8'), { ...post('zed'), attachments: files('posts', 'p8', 'zed') }));
    });

    test('admins can read and delete any group content', async () => {
      await seed((db) => setDoc(doc(db, 'admins/boss@example.com'), {}));
      await createGroup(as('owner'), 'owner');
      await seed((db) => setDoc(doc(db, 'userGroups/g1/posts/p9'), { authorId: 'owner', text: 'x' }));
      const admin = as('boss', 'boss@example.com');
      await assertSucceeds(getDoc(doc(admin, 'userGroups/g1/posts/p9')));
      await assertSucceeds(deleteDoc(doc(admin, 'userGroups/g1/posts/p9')));
      await assertSucceeds(deleteDoc(doc(admin, 'userGroups/g1')));
    });
  });
});
