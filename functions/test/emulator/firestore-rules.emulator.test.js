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
