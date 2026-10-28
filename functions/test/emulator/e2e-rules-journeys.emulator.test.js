// Tester-added cross-feature user journeys against firestore.rules and
// storage.rules, issuing the SAME writes the Flutter app and the Vue admin
// dashboard perform. Needs the Firestore + Storage emulators:
//   npm run test:emulator
const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, addDoc, collection, writeBatch,
  serverTimestamp, Timestamp, deleteField, query, where, orderBy, arrayUnion,
} = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');

const hasEmulators = !!(process.env.FIREBASE_STORAGE_EMULATOR_HOST && process.env.FIRESTORE_EMULATOR_HOST);
let env;

const ADMIN_EMAIL = 'moyoapptanzania@gmail.com';
const ctxOf = (uid, email, verified = true) =>
  (email ? env.authenticatedContext(uid, { email, email_verified: verified }) : env.authenticatedContext(uid));
const as = (uid, email, verified) => ctxOf(uid, email, verified).firestore();
const storageAs = (uid, email, verified) => ctxOf(uid, email, verified).storage();
const admin = () => as('adminUid', ADMIN_EMAIL);
const seed = (fn) => env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
const put = (st, p, size, contentType) => uploadBytes(ref(st, p), new Uint8Array(size), { contentType });

// Server-side bump done by notifyConversationMessage (Admin SDK).
async function serverBumpConversation(convId, text, senderId) {
  await seed((db) => updateDoc(doc(db, 'conversations', convId), {
    lastMessage: { text, senderId }, updatedAt: serverTimestamp(),
  }));
}
// Same pure rules as lib/utils/chat_visibility.dart.
const isConversationVisible = (deletedAt, updatedAt) => !deletedAt || (!!updatedAt && updatedAt > deletedAt);
const isMessageVisible = (createdAt, deletedAt) => !deletedAt || !createdAt || createdAt > deletedAt;
const pause = (ms) => new Promise((r) => setTimeout(r, ms));

describe('E2E rules journeys', { skip: !hasEmulators && 'Storage/Firestore emulators not running' }, () => {
  before(async () => {
    const [sHost, sPort] = process.env.FIREBASE_STORAGE_EMULATOR_HOST.split(':');
    const [fHost, fPort] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
    env = await initializeTestEnvironment({
      projectId: 'demo-moyo-test',
      firestore: { host: fHost, port: Number(fPort), rules: fs.readFileSync(path.join(__dirname, '../../../firestore.rules'), 'utf8') },
      storage: { host: sHost, port: Number(sPort), rules: fs.readFileSync(path.join(__dirname, '../../../storage.rules'), 'utf8') },
    });
  });
  after(async () => { await env?.cleanup(); });
  beforeEach(async () => {
    await env.clearFirestore();
    await seed((db) => setDoc(doc(db, 'admins', ADMIN_EMAIL), { addedBy: 'console' }));
  });

  test('delete-chat-for-me journey: A deletes, B unaffected, B writes again → A sees only the new message', async () => {
    const A = as('aaa'); const B = as('bbb');
    const cid = 'aaa_bbb';
    // ConversationService.getOrCreateConversation
    assert.equal((await assertSucceeds(getDoc(doc(A, 'conversations', cid)))).exists(), false);
    await assertSucceeds(setDoc(doc(A, 'conversations', cid), {
      participants: ['aaa', 'bbb'], participantNames: { aaa: 'A', bbb: 'B' }, lastMessage: null, updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(collection(A, 'conversations', cid, 'messages')), { senderId: 'aaa', text: 'habari', createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null }));
    await serverBumpConversation(cid, 'habari', 'aaa');
    await assertSucceeds(setDoc(doc(collection(B, 'conversations', cid, 'messages')), { senderId: 'bbb', text: 'nzuri', createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null }));
    await serverBumpConversation(cid, 'nzuri', 'bbb');
    await pause(20);

    // A deletes for me (exact app write)
    await assertSucceeds(updateDoc(doc(A, 'conversations', cid), { 'deletedAt.aaa': serverTimestamp() }));
    // A can't hide it for B, nor delete it outright, nor rewrite lastMessage
    await assertFails(updateDoc(doc(A, 'conversations', cid), { 'deletedAt.bbb': serverTimestamp() }));
    await assertFails(deleteDoc(doc(A, 'conversations', cid)));
    await assertFails(updateDoc(doc(A, 'conversations', cid), { lastMessage: null }));
    // A non-participant can't stamp anything
    await assertFails(updateDoc(doc(as('ccc'), 'conversations', cid), { 'deletedAt.ccc': serverTimestamp() }));

    let convA = (await getDoc(doc(A, 'conversations', cid))).data();
    const delA = convA.deletedAt.aaa.toDate();
    assert.equal(isConversationVisible(delA, convA.updatedAt.toDate()), false, 'hidden for A');
    const convB = (await getDoc(doc(B, 'conversations', cid))).data();
    assert.equal(isConversationVisible(convB.deletedAt?.bbb?.toDate(), convB.updatedAt.toDate()), true, 'B unaffected');
    // B still reads every message
    assert.equal((await getDocs(query(collection(B, 'conversations', cid, 'messages'), orderBy('createdAt')))).size, 2);
    // ConversationService.getConversations for A still runs (query allowed; filtered client-side)
    await assertSucceeds(getDocs(query(collection(A, 'conversations'), where('participants', 'array-contains', 'aaa'), orderBy('updatedAt', 'desc'))));

    await pause(20);
    await assertSucceeds(setDoc(doc(collection(B, 'conversations', cid, 'messages')), { senderId: 'bbb', text: 'uko?', createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null }));
    await serverBumpConversation(cid, 'uko?', 'bbb');

    convA = (await getDoc(doc(A, 'conversations', cid))).data();
    assert.equal(isConversationVisible(delA, convA.updatedAt.toDate()), true, 'reappears for A');
    const msgs = (await getDocs(query(collection(A, 'conversations', cid, 'messages'), orderBy('createdAt')))).docs.map((d) => d.data());
    const visibleToA = msgs.filter((m) => isMessageVisible(m.createdAt.toDate(), delA)).map((m) => m.text);
    assert.deepEqual(visibleToA, ['uko?']);
    // A can delete again later (second stamp overwrites own key only)
    await assertSucceeds(updateDoc(doc(A, 'conversations', cid), { 'deletedAt.aaa': serverTimestamp() }));
    // B's chat attachments still upload (conversations storage path, catch-all removed)
    await assertSucceeds(put(storageAs('bbb'), `conversations/${cid}/m9/0_a.jpg`, 1000, 'image/jpeg'));
    await assertFails(put(storageAs('ccc'), `conversations/${cid}/m9/0_b.jpg`, 1000, 'image/jpeg'));
  });

  test('user group journey: create with photo → outsider blocked → joins → posts with links → owner bans → cannot rejoin/post', async () => {
    const owner = as('own'); const bob = as('bob');
    const gid = 'grp1';
    // UserGroupService.createGroup: picture uploaded FIRST (no group doc yet),
    // then group + photoUrl/photoPath + owner membership in one batch.
    await assertSucceeds(put(storageAs('own'), `userGroups/${gid}/photo/own/1.jpg`, 2000, 'image/jpeg'));
    const b = writeBatch(owner);
    b.set(doc(owner, 'userGroups', gid), {
      subcategoryId: 'sub1', name: 'Wapenzi wa Vitabu', description: 'd', ownerId: 'own', ownerName: 'Own',
      photoUrl: 'https://x', photoPath: `userGroups/${gid}/photo/own/1.jpg`,
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    b.set(doc(owner, 'userGroups', gid, 'members', 'own'), { name: 'Own', role: 'owner', joinedAt: serverTimestamp() });
    await assertSucceeds(b.commit());
    assert.equal((await getDoc(doc(bob, 'userGroups', gid))).data().photoUrl, 'https://x');
    // updateGroup with a new picture
    await assertSucceeds(put(storageAs('own'), `userGroups/${gid}/photo/own/2.jpg`, 2000, 'image/jpeg'));
    await assertSucceeds(updateDoc(doc(owner, 'userGroups', gid), { name: 'Wapenzi wa Vitabu', description: 'd', photoUrl: 'https://y', photoPath: `userGroups/${gid}/photo/own/2.jpg`, updatedAt: serverTimestamp() }));

    // bob not yet a member: cannot post, read, chat, or upload
    const post = (uid, extra = {}) => ({ authorId: uid, authorName: uid, text: 'soma hii', imageUrl: null, createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null, ...extra });
    await assertFails(setDoc(doc(collection(bob, 'userGroups', gid, 'posts')), post('bob')));
    await assertFails(getDocs(collection(bob, 'userGroups', gid, 'posts')));
    await assertFails(setDoc(doc(collection(bob, 'userGroups', gid, 'messages')), { senderId: 'bob', senderName: 'bob', text: 'hi', createdAt: serverTimestamp(), type: 'text' }));
    await assertFails(put(storageAs('bob'), `userGroups/${gid}/posts/p1/0_a.jpg`, 1000, 'image/jpeg'));
    // cannot join as owner / for someone else
    await assertFails(setDoc(doc(bob, 'userGroups', gid, 'members', 'bob'), { name: 'bob', role: 'owner', joinedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(bob, 'userGroups', gid, 'members', 'zed'), { name: 'zed', role: 'member', joinedAt: serverTimestamp() }));

    // join (UserGroupService.join)
    await assertSucceeds(setDoc(doc(bob, 'userGroups', gid, 'members', 'bob'), { name: 'bob', role: 'member', joinedAt: serverTimestamp() }));
    const pRef = doc(collection(bob, 'userGroups', gid, 'posts'));
    await assertSucceeds(setDoc(pRef, post('bob', { links: ['https://example.com/a'] })));
    await assertSucceeds(setDoc(doc(collection(bob, 'userGroups', gid, 'messages')), { senderId: 'bob', senderName: 'bob', text: 'hi', createdAt: serverTimestamp(), type: 'text' }));
    // ThreadPostService.createPost in a group: upload to posts/{id}/{uid}/ then write the doc
    const p2 = doc(collection(bob, 'userGroups', gid, 'posts'));
    const files = [['0_a.jpg', 'image/jpeg', 'image'], ['1_v.mp4', 'video/mp4', 'video'], ['2_d.pdf', 'application/pdf', 'pdf'], ['3_s.mp3', 'audio/mpeg', 'audio']];
    for (const [name, ct] of files) {
      await assertSucceeds(put(storageAs('bob'), `userGroups/${gid}/posts/${p2.id}/bob/${name}`, 1000, ct));
    }
    await assertSucceeds(setDoc(p2, post('bob', {
      attachments: files.map(([name, , type]) => ({ type, url: 'https://x', path: `userGroups/${gid}/posts/${p2.id}/bob/${name}`, name, size: 1000 })),
    })));
    // ConversationService.sendTo in the group chat
    const m2 = doc(collection(bob, 'userGroups', gid, 'messages'));
    await assertSucceeds(put(storageAs('bob'), `userGroups/${gid}/messages/${m2.id}/bob/0_a.pdf`, 1000, 'application/pdf'));
    await assertSucceeds(setDoc(m2, { senderId: 'bob', senderName: 'bob', text: '', createdAt: serverTimestamp(), type: 'text',
      attachments: [{ type: 'pdf', url: 'https://x', path: `userGroups/${gid}/messages/${m2.id}/bob/0_a.pdf` }] }));
    await assertSucceeds(setDoc(doc(bob, 'userGroups', gid, 'posts', pRef.id, 'likes', 'bob'), { createdAt: serverTimestamp() }));
    // bob cannot remove the owner or ban anyone, cannot edit the group
    await assertFails(deleteDoc(doc(bob, 'userGroups', gid, 'members', 'own')));
    await assertFails(setDoc(doc(bob, 'userGroups', gid, 'bans', 'own'), { bannedBy: 'bob', bannedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(bob, 'userGroups', gid), { name: 'hijack' }));
    // owner cannot leave (must delete group)
    await assertFails(deleteDoc(doc(owner, 'userGroups', gid, 'members', 'own')));

    // owner deletes bob's post and bans him (UserGroupService.removeMember batch)
    await assertSucceeds(deleteDoc(doc(owner, 'userGroups', gid, 'posts', pRef.id)));
    const rb = writeBatch(owner);
    rb.delete(doc(owner, 'userGroups', gid, 'members', 'bob'));
    rb.set(doc(owner, 'userGroups', gid, 'bans', 'bob'), { bannedBy: 'own', bannedAt: serverTimestamp() });
    await assertSucceeds(rb.commit());

    await assertFails(setDoc(doc(bob, 'userGroups', gid, 'members', 'bob'), { name: 'bob', role: 'member', joinedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(collection(bob, 'userGroups', gid, 'posts')), post('bob')));
    await assertFails(getDocs(collection(bob, 'userGroups', gid, 'messages')));
    await assertFails(put(storageAs('bob'), `userGroups/${gid}/messages/m2/0_a.jpg`, 1000, 'image/jpeg'));
    // banned user can see that he is banned (for a friendly message), others can't read bans
    await assertSucceeds(getDoc(doc(bob, 'userGroups', gid, 'bans', 'bob')));
    await assertFails(getDoc(doc(as('zed'), 'userGroups', gid, 'bans', 'bob')));
    // bob can't lift his own ban
    await assertFails(deleteDoc(doc(bob, 'userGroups', gid, 'bans', 'bob')));
  });

  test('subcategory feed/chat: any signed-in user posts; no links; deletes only by author or admin', async () => {
    const u = as('u1'); const v = as('v1');
    const pRef = doc(collection(u, 'subcategoryFeeds', 'sub1', 'posts'));
    const body = { authorId: 'u1', authorName: 'u1', text: 'swali', imageUrl: null, createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null };
    await assertSucceeds(setDoc(pRef, body));
    await assertFails(setDoc(doc(collection(u, 'subcategoryFeeds', 'sub1', 'posts')), { ...body, links: ['https://x'] }));
    await assertSucceeds(setDoc(doc(collection(v, 'subcategoryFeeds', 'sub1', 'posts', pRef.id, 'replies')), { authorId: 'v1', authorName: 'v1', text: 'jibu', createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(v, 'subcategoryFeeds', 'sub1', 'posts', pRef.id, 'pollResponses', 'v1'), { optionIndex: 0 }));
    await assertFails(deleteDoc(doc(v, 'subcategoryFeeds', 'sub1', 'posts', pRef.id)));
    await assertFails(updateDoc(doc(u, 'subcategoryFeeds', 'sub1', 'posts', pRef.id), { likeCount: 999 }));
    await assertSucceeds(deleteDoc(doc(admin(), 'subcategoryFeeds', 'sub1', 'posts', pRef.id)));
    const mRef = doc(collection(v, 'subcategoryFeeds', 'sub1', 'messages'));
    await assertSucceeds(setDoc(mRef, { senderId: 'v1', senderName: 'v1', text: 'habari', createdAt: serverTimestamp(), type: 'text' }));
    await assertFails(setDoc(doc(collection(v, 'subcategoryFeeds', 'sub1', 'messages')), { senderId: 'u1', text: 'spoof', createdAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(u, 'subcategoryFeeds', 'sub1', 'messages', mRef.id)));
    await assertSucceeds(put(storageAs('u1'), 'subcategoryFeeds/sub1/posts/p1/0_v.mp4', 5000, 'video/mp4'));
  });

  test('existing flows still work: wall posts + uploads, admin posts comments/likes, notifications, profile setup', async () => {
    const u = as('u1');
    const tRef = doc(collection(u, 'threadPosts'));
    await assertSucceeds(put(storageAs('u1'), `threadPosts/${tRef.id}/0_a.jpg`, 1000, 'image/jpeg'));
    await assertSucceeds(put(storageAs('u1'), `threadPosts/${tRef.id}/1_v.mp4`, 1000, 'video/mp4'));
    await assertSucceeds(setDoc(tRef, { authorId: 'u1', authorName: 'u1', text: 'ukuta', imageUrl: null, createdAt: serverTimestamp(), type: 'text', pollType: null, pollOptions: null, attachments: [{ type: 'image', url: 'x' }] }));
    await assertSucceeds(setDoc(doc(collection(u, 'threadPosts', tRef.id, 'replies')), { authorId: 'u1', authorName: 'u1', text: 'r', createdAt: serverTimestamp() }));
    await seed((db) => setDoc(doc(db, 'posts/p1'), { title: 't' }));
    await assertSucceeds(setDoc(doc(collection(u, 'posts', 'p1', 'comments')), { userId: 'u1', userName: 'u1', text: 'nice', createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(u, 'posts', 'p1', 'likes', 'u1'), { createdAt: serverTimestamp() }));
    await assertSucceeds(getDocs(query(collection(u, 'notifications'), where('recipientId', '==', 'u1'))));
    // ProfileSetupScreen._save on a brand-new account, then a later edit
    await assertSucceeds(setDoc(doc(u, 'users', 'u1'), { fullName: 'U', email: 'u@x', country: 'Tanzania', region: 'Arusha', phone: '+255', isActive: false, createdAt: serverTimestamp() }, { merge: true }));
    await assertSucceeds(setDoc(doc(u, 'users', 'u1'), { fullName: 'U2', email: 'u@x', country: 'Tanzania', region: 'Arusha', phone: '+255' }, { merge: true }));
    // reads used by the payment flow
    await seed((db) => setDoc(doc(db, 'subscriptions/s1'), { userId: 'u1', status: 'PROCESSING' }));
    await assertSucceeds(getDoc(doc(u, 'subscriptions', 's1')));
    await assertFails(setDoc(doc(u, 'subscriptions', 's2'), { userId: 'u1', status: 'Completed', amount: 1e9 }));
    await assertFails(updateDoc(doc(u, 'subscriptions', 's1'), { status: 'Completed' }));
    // wallet is read-only for the owner, invisible to others
    await seed((db) => setDoc(doc(db, 'wallets/u1'), { balance: 5 }));
    await assertSucceeds(getDoc(doc(u, 'wallets', 'u1')));
    await assertFails(getDoc(doc(as('v1'), 'wallets', 'u1')));
    await assertFails(setDoc(doc(u, 'wallets', 'u1'), { balance: 1e9 }));
    await assertSucceeds(getDocs(query(collection(u, 'withdrawalRequests'), where('uid', '==', 'u1'), orderBy('createdAt', 'desc'))));
    await assertFails(getDocs(collection(u, 'withdrawalRequests')));
  });

  test('vue admin: every dashboard write/read is still permitted for an admin', async () => {
    const a = admin();
    await seed(async (db) => {
      await setDoc(doc(db, 'categories/main1'), { name: 'M', iconCode: 1, colorHex: 1, parentId: null });
      await setDoc(doc(db, 'categories/sub1'), { name: 'S', parentId: 'main1' });
      await setDoc(doc(db, 'users/u1'), { fullName: 'U', isActive: false, referredBy: 'zz' });
      await setDoc(doc(db, 'userGroups/g1'), { ownerId: 'own', name: 'G', subcategoryId: 'sub1' });
      await setDoc(doc(db, 'userGroups/g1/posts/p1'), { authorId: 'own', text: 'x' });
      await setDoc(doc(db, 'userGroups/g1/messages/m1'), { senderId: 'own', text: 'x' });
      await setDoc(doc(db, 'userGroups/g1/members/own'), { role: 'owner' });
      await setDoc(doc(db, 'withdrawalRequests/w1'), { uid: 'u1', status: 'pending', amount: 10000, createdAt: Timestamp.now(), idPhotoPath: 'withdrawals/u1/1.jpg' });
      await setDoc(doc(db, 'wallets/u1'), { balance: 1 });
      await setDoc(doc(db, 'notifications/n0'), { title: 't', recipientId: null, notify: false });
    });
    // CategoryFormModal add/update (with groupId set/removed) + CategoriesView delete
    const cRef = await assertSucceeds(addDoc(collection(a, 'categories'), { name: 'N', iconCode: 1, colorHex: 1, isProtected: false, parentId: null, updatedAt: serverTimestamp(), createdAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(a, 'categories', 'main1'), { name: 'M2', parentId: null, groupId: 'cg', passwordHash: deleteField(), updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(a, 'categories', 'main1'), { groupId: deleteField() }));
    await assertSucceeds(deleteDoc(doc(a, 'categories', cRef.id)));
    // CategoryGroupsView add/update/batch-assign/delete
    const gRef = await assertSucceeds(addDoc(collection(a, 'categoryGroups'), { name: 'Elimu', order: 1, iconCode: 1, colorHex: 1, updatedAt: serverTimestamp(), createdAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(a, 'categoryGroups', gRef.id), { name: 'Elimu 2', order: 2, iconCode: 1, colorHex: 1, updatedAt: serverTimestamp() }));
    const wb = writeBatch(a);
    wb.update(doc(a, 'categories', 'main1'), { groupId: gRef.id, updatedAt: serverTimestamp() });
    await assertSucceeds(wb.commit());
    const wb2 = writeBatch(a);
    wb2.update(doc(a, 'categories', 'main1'), { groupId: deleteField() });
    await assertSucceeds(wb2.commit());
    await assertSucceeds(deleteDoc(doc(a, 'categoryGroups', gRef.id)));
    // PostFormModal / PostsView
    const pRef = await assertSucceeds(addDoc(collection(a, 'posts'), { title: 'T', created_at: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(a, 'posts', pRef.id), { title: 'T2', updated_at: serverTimestamp() }));
    await assertSucceeds(getDocs(collection(a, 'posts', pRef.id, 'pollResponses')));
    await assertSucceeds(deleteDoc(doc(a, 'posts', pRef.id)));
    // NotificationsView
    await assertSucceeds(getDocs(query(collection(a, 'notifications'), where('recipientId', '==', null))));
    const nRef = await assertSucceeds(addDoc(collection(a, 'notifications'), { title: 't', body: 'b', notify: false, recipientId: null, createdAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(a, 'notifications', nRef.id), { notify: true }));
    await assertSucceeds(deleteDoc(doc(a, 'notifications', nRef.id)));
    // PackagesView
    const kRef = await assertSucceeds(addDoc(collection(a, 'packages'), { name: 'P', price: 1000, isActive: true, createdAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(a, 'packages', kRef.id), { isActive: false }));
    await assertSucceeds(deleteDoc(doc(a, 'packages', kRef.id)));
    // UsersView (users with referral fields: toggling isActive must not trip the referral guard)
    await assertSucceeds(getDocs(collection(a, 'users')));
    await assertSucceeds(updateDoc(doc(a, 'users', 'u1'), { isActive: true }));
    await assertSucceeds(updateDoc(doc(a, 'users', 'u1'), { isActive: true, expire_date: Timestamp.now() }));
    await assertSucceeds(updateDoc(doc(a, 'users', 'u1'), { isActive: false, expire_date: null }));
    // UserGroupsView (admin is NOT a member)
    await assertSucceeds(getDocs(query(collection(a, 'userGroups', 'g1', 'posts'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(query(collection(a, 'userGroups', 'g1', 'messages'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(collection(a, 'userGroups', 'g1', 'members')));
    await assertSucceeds(deleteDoc(doc(a, 'userGroups', 'g1', 'posts', 'p1')));
    await assertSucceeds(deleteDoc(doc(a, 'userGroups', 'g1', 'messages', 'm1')));
    await assertSucceeds(deleteDoc(doc(a, 'userGroups', 'g1')));
    // WithdrawalsView reads + ID photo
    await assertSucceeds(getDocs(query(collection(a, 'withdrawalRequests'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(collection(a, 'wallets')));
    await env.withSecurityRulesDisabled(async (ctx) => { await uploadBytes(ref(ctx.storage(), 'withdrawals/u1/1.jpg'), new Uint8Array(10), { contentType: 'image/jpeg' }); });
    await assertSucceeds(getBytes(ref(storageAs('adminUid', ADMIN_EMAIL), 'withdrawals/u1/1.jpg')));
    await assertSucceeds(getDocs(collection(a, 'referralCodes')));
    // UsersView delete (last)
    await assertSucceeds(deleteDoc(doc(a, 'users', 'u1')));

    // A dashboard-capable account WITHOUT the admins doc / verified email is refused the admin-only bits
    await assertFails(addDoc(collection(as('x', 'other@gmail.com'), 'categoryGroups'), { name: 'x' }));
    await assertFails(addDoc(collection(as('x', ADMIN_EMAIL, false), 'categoryGroups'), { name: 'x' }));
    await assertFails(getDocs(collection(as('x', 'other@gmail.com'), 'wallets')));
    // mixed-case token email still resolves to the lower-cased admins doc id
    await assertSucceeds(addDoc(collection(as('y', 'MoyoAppTanzania@Gmail.com'), 'categoryGroups'), { name: 'y' }));
  });

  // ---- Former holes (were `todo`), now fixed -------------------------------

  test('FIXED: user cannot rewrite own users.createdAt (it can only be set once, to the server time)', async () => {
    await seed((db) => setDoc(doc(db, 'users/old'), { fullName: 'Old', createdAt: Timestamp.fromDate(new Date('2024-01-01')) }));
    await assertFails(updateDoc(doc(as('old'), 'users', 'old'), { createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(admin(), 'users', 'old'), { createdAt: serverTimestamp() }));
    // A doc that has no createdAt yet (e.g. created by registerFcmToken)
    // may get it once, from the server clock only.
    await seed((db) => setDoc(doc(db, 'users/nu'), { fcmTokens: ['t'] }));
    await assertFails(updateDoc(doc(as('nu'), 'users', 'nu'), { createdAt: Timestamp.fromDate(new Date('2030-01-01')) }));
    await assertSucceeds(updateDoc(doc(as('nu'), 'users', 'nu'), { createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as('x2'), 'users', 'x2'), { fullName: 'X', createdAt: Timestamp.fromDate(new Date('2020-01-01')) }));
  });

  test('FIXED: user cannot delete own profile (to drop referredBy); admins still can', async () => {
    await seed((db) => setDoc(doc(db, 'users/bob'), { fullName: 'Bob', createdAt: Timestamp.now(), referredBy: 'alice', referredByCode: 'AAAA' }));
    await assertFails(deleteDoc(doc(as('bob'), 'users', 'bob')));
    await assertFails(deleteDoc(doc(as('mallory'), 'users', 'bob')));
    // referralClaims is server-only and survives anyway.
    await assertFails(setDoc(doc(as('bob'), 'referralClaims', 'bob'), { referrerUid: 'mallory' }));
    await seed((db) => setDoc(doc(db, 'referralClaims/bob'), { referrerUid: 'alice' }));
    await assertSucceeds(getDoc(doc(as('bob'), 'referralClaims', 'bob')));
    await assertFails(getDoc(doc(as('mallory'), 'referralClaims', 'bob')));
    await assertFails(deleteDoc(doc(as('bob'), 'referralClaims', 'bob')));
    await assertSucceeds(deleteDoc(doc(admin(), 'users', 'bob')));
  });

  test("FIXED: nobody but the owner (or an admin) writes a user's doc, and the owner can't grant themselves a subscription", async () => {
    await seed((db) => setDoc(doc(db, 'users/victim'), { fullName: 'V', isActive: false }));
    const mallory = as('mallory');
    await assertFails(updateDoc(doc(mallory, 'users', 'victim'), { isActive: true }));
    await assertFails(updateDoc(doc(mallory, 'users', 'victim'), { fullName: 'pwned' }));
    await assertFails(setDoc(doc(mallory, 'users', 'someoneElse'), { fullName: 'x' }));

    const v = as('victim');
    await assertSucceeds(updateDoc(doc(v, 'users', 'victim'), { fullName: 'Victor', phone: '+255' }));
    for (const patch of [
      { isActive: true },
      { subscriptionExpiry: Timestamp.fromDate(new Date('2030-01-01')) },
      { activePackageId: 'pkg' },
      { activeSubscriptionId: 'sub' },
      { expire_date: Timestamp.now() },
      { fcmTokens: ['t'] },
      { referredBy: 'x' },
      { referralCode: 'ZZZZ' },
    ]) {
      await assertFails(updateDoc(doc(v, 'users', 'victim'), patch));
    }
    // Brand-new profile can't start active either.
    await assertFails(setDoc(doc(as('n1'), 'users', 'n1'), { fullName: 'N', isActive: true }));
    // Profile setup writing isActive:false onto a doc registerFcmToken just
    // created (no isActive yet) is still fine.
    await seed((db) => setDoc(doc(db, 'users/n2'), { fcmTokens: ['t'] }));
    await assertSucceeds(setDoc(doc(as('n2'), 'users', 'n2'), { fullName: 'N2', isActive: false, createdAt: serverTimestamp() }, { merge: true }));
    // ...but can't use that path to switch an active subscription off/on.
    await seed((db) => setDoc(doc(db, 'users/n3'), { isActive: true }));
    await assertFails(updateDoc(doc(as('n3'), 'users', 'n3'), { isActive: false }));

    // Admin (UsersView) can still toggle subscription state.
    await assertSucceeds(updateDoc(doc(admin(), 'users', 'victim'), { isActive: true, expire_date: Timestamp.now() }));
    // User subcollections: owner/admin only.
    await assertFails(setDoc(doc(mallory, 'users', 'victim', 'private', 'x'), { a: 1 }));
    await assertSucceeds(setDoc(doc(v, 'users', 'victim', 'private', 'x'), { a: 1 }));
  });

  test('profile setup on a doc registerFcmToken created first (fcmTokens only) backfills isActive:false + createdAt', async () => {
    await seed((db) => setDoc(doc(db, 'users/fresh'), { fcmTokens: ['tok'] }));
    const u = as('fresh');
    // Exactly what ProfileSetupScreen._save sends when isActive/createdAt are missing.
    await assertSucceeds(setDoc(doc(u, 'users', 'fresh'), {
      fullName: 'Fresh', email: 'f@x', country: 'Tanzania', region: 'Arusha', phone: '+255700',
      isActive: false, createdAt: serverTimestamp(),
    }, { merge: true }));
    const saved = (await getDoc(doc(u, 'users', 'fresh'))).data();
    assert.equal(saved.isActive, false);
    assert.ok(saved.createdAt);
    assert.deepEqual(saved.fcmTokens, ['tok']);
    // Saving again (fields now present → not re-sent) still works; re-sending createdAt doesn't.
    await assertSucceeds(setDoc(doc(u, 'users', 'fresh'), { fullName: 'Fresh 2' }, { merge: true }));
    await assertFails(setDoc(doc(u, 'users', 'fresh'), { createdAt: serverTimestamp() }, { merge: true }));
  });

  // Still open by design (client + storage enforce per-type counts):
  test('BUG: subcategory/group rules allow more than 5 images / more than one video per post',
    { todo: 'validPost only caps attachments at 10, not per type' }, async () => {
      const imgs = Array.from({ length: 10 }, (_, i) => ({ type: 'image', url: `u${i}` }));
      await assertFails(setDoc(doc(collection(as('u1'), 'subcategoryFeeds', 'sub1', 'posts')), {
        authorId: 'u1', text: 'x', attachments: imgs, createdAt: serverTimestamp(),
      }));
    });
  // ---- Tester re-verification (round 2): exact ProfileSetupScreen._save payloads
  const profile = (name = 'U') => ({ fullName: name, email: 'u@x.test', country: 'Tanzania', region: 'Arusha', phone: '+255712345678' });

  test('RETEST: profile setup payloads pass for every pre-existing doc shape', async () => {
    // a) doc created by registerFcmToken before setup → existing.exists, no isActive/createdAt sent
    await seed((db) => setDoc(doc(db, 'users/a'), { fcmTokens: ['tok'] }));
    await assertSucceeds(setDoc(doc(as('a'), 'users', 'a'), profile(), { merge: true }));
    // b) legacy doc lacking createdAt and isActive, partial profile
    await seed((db) => setDoc(doc(db, 'users/b'), { fullName: 'B', email: 'b@x' }));
    await assertSucceeds(setDoc(doc(as('b'), 'users', 'b'), profile('B'), { merge: true }));
    // c) fully paid + referred user re-running setup (incomplete phone) — every protected field present
    await seed((db) => setDoc(doc(db, 'users/c'), {
      fullName: 'C', isActive: true, subscriptionExpiry: Timestamp.now(), activePackageId: 'p', activeSubscriptionId: 's',
      expire_date: null, fcmTokens: ['t1', 't2'], referralCode: 'ABCD', referralCodeCreatedAt: Timestamp.now(),
      referredBy: 'z', referredByCode: 'ZZZZ', referredAt: Timestamp.now(), createdAt: Timestamp.fromDate(new Date('2024-01-01')),
    }));
    await assertSucceeds(setDoc(doc(as('c'), 'users', 'c'), profile('C'), { merge: true }));
    // d) race: client saw no doc, registerFcmToken created it in between → new-account payload lands as an update
    await seed((db) => setDoc(doc(db, 'users/d'), { fcmTokens: ['tok'] }));
    await assertSucceeds(setDoc(doc(as('d'), 'users', 'd'), { ...profile(), isActive: false, createdAt: serverTimestamp() }, { merge: true }));
    // e) brand-new
    await assertSucceeds(setDoc(doc(as('e'), 'users', 'e'), { ...profile(), isActive: false, createdAt: serverTimestamp() }, { merge: true }));
    // f) race the other way: client saw no doc but an admin activated meanwhile → isActive:false is refused (acceptable, retry works)
    await seed((db) => setDoc(doc(db, 'users/f'), { isActive: true }));
    await assertFails(setDoc(doc(as('f'), 'users', 'f'), { ...profile(), isActive: false, createdAt: serverTimestamp() }, { merge: true }));
    await assertSucceeds(setDoc(doc(as('f'), 'users', 'f'), profile(), { merge: true }));
  });

  test('RETEST: client never needs to write fcmTokens (server callable does); a client write is refused', async () => {
    await seed((db) => setDoc(doc(db, 'users/a'), { fullName: 'A' }));
    await assertFails(updateDoc(doc(as('a'), 'users', 'a'), { fcmTokens: arrayUnion('t') }));
    await assertFails(setDoc(doc(as('n'), 'users', 'n'), { fcmTokens: ['t'] }, { merge: true }));
  });

  test('RETEST: Vue UsersView writes on docs missing fields; reads used by app screens', async () => {
    await seed((db) => setDoc(doc(db, 'users/v'), { fullName: 'V' }));
    await assertSucceeds(updateDoc(doc(admin(), 'users', 'v'), { isActive: true }));
    await assertSucceeds(updateDoc(doc(admin(), 'users', 'v'), { isActive: false, expire_date: null }));
    await assertSucceeds(updateDoc(doc(admin(), 'users', 'v'), { isActive: true, expire_date: Timestamp.now() }));
    await assertFails(updateDoc(doc(admin(), 'users', 'v'), { referredBy: 'x' }));
    // user search / conversation lookups read other users
    await assertSucceeds(getDoc(doc(as('other'), 'users', 'v')));
    await assertSucceeds(getDocs(query(collection(as('other'), 'users'), orderBy('fullName'))));
    // admin-but-unverified email is not admin
    await assertFails(updateDoc(doc(as('x', ADMIN_EMAIL, false), 'users', 'v'), { isActive: true }));
  });
  // Round 3: ProfileSetupScreen._save now adds isActive:false / createdAt whenever the key is missing.
  test('RETEST3: new _save payload logic passes on all doc shapes', async () => {
    const save = (uid, existing) => setDoc(doc(as(uid), 'users', uid), {
      ...profile(),
      ...(!('isActive' in existing) ? { isActive: false } : {}),
      ...(!('createdAt' in existing) ? { createdAt: serverTimestamp() } : {}),
    }, { merge: true });
    const shapes = {
      none: null,
      fcmOnly: { fcmTokens: ['t'] },
      legacyNoFields: { fullName: 'L', email: 'l@x' },
      activeNoCreatedAt: { fullName: 'A', isActive: true, subscriptionExpiry: Timestamp.now(), fcmTokens: ['t'] },
      inactiveNoCreatedAt: { isActive: false },
      hasCreatedAtNoIsActive: { createdAt: Timestamp.fromDate(new Date('2024-01-01')) },
      complete: { fullName: 'C', isActive: true, createdAt: Timestamp.now(), referredBy: 'z', referralCode: 'ABCD', activePackageId: 'p' },
    };
    for (const [uid, data] of Object.entries(shapes)) {
      if (data) await seed((db) => setDoc(doc(db, 'users', uid), data));
      await assertSucceeds(save(uid, data || {}));
      // second save (e.g. after a rejected referral code) also passes
      const now = (await seed((db) => getDoc(doc(db, 'users', uid)))) ;
      void now;
      await seed(async (db) => { const d = (await getDoc(doc(db, 'users', uid))).data(); assert.ok('createdAt' in d && 'isActive' in d, uid); });
    }
    for (const uid of Object.keys(shapes)) {
      const d = await getDoc(doc(as(uid), 'users', uid));
      await assertSucceeds(save(uid, d.data()));
    }
    // legacy active user keeps isActive true
    assert.equal((await getDoc(doc(as('activeNoCreatedAt'), 'users', 'activeNoCreatedAt'))).data().isActive, true);
  });
});
