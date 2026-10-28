// Static guard for storage.rules — no emulator needed:  npm test
//
// Why: in production a storage rule that calls firestore.get()/exists()
// only works if the Storage service agent has the "Firebase Rules
// Firestore Service Agent" IAM role. The emulator never enforces that, so
// the emulator suites passed while every 1:1-chat attachment, group photo
// and group post/chat file was denied in production. The upload paths the
// app uses today must therefore be authorised without any cross-service
// lookup — this test fails if someone reintroduces one on them.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const rules = fs.readFileSync(path.join(__dirname, '../../../storage.rules'), 'utf8');

// Body of `match <pattern> { ... }` (brace-matched).
function matchBody(pattern) {
  const start = rules.indexOf(`match ${pattern} {`);
  assert.notEqual(start, -1, `storage.rules has no "match ${pattern}"`);
  let depth = 0;
  for (let i = start + `match ${pattern} `.length; i < rules.length; i++) {
    if (rules[i] === '{') depth++;
    if (rules[i] === '}' && --depth === 0) return rules.slice(start, i + 1);
  }
  throw new Error('unbalanced braces');
}

// The allow-create/write statement of a match block.
function writeRule(body) {
  const m = body.match(/allow (create|write|read, write)[^;]*;/);
  assert.ok(m, 'no create/write rule');
  return m[0];
}

const FUNCTIONS_USING_FIRESTORE = ['isAdmin'];

for (const p of [
  '/conversations/{conversationId}/{messageId}/{fileName}',
  '/userGroups/{groupId}/photo/{uid}/{fileName}',
  '/userGroups/{groupId}/{kind}/{itemId}/{uid}/{fileName}',
  '/subcategoryFeeds/{categoryId}/{kind}/{itemId}/{fileName}',
  '/threadPosts/{postId}/{fileName}',
  '/withdrawals/{uid}/{fileName}',
]) {
  test(`uploads to ${p} need no cross-service Firestore lookup`, () => {
    const rule = writeRule(matchBody(p));
    assert.doesNotMatch(rule, /firestore\.(get|exists)/);
    for (const fn of FUNCTIONS_USING_FIRESTORE) assert.ok(!rule.includes(`${fn}(`), `${p} write uses ${fn}()`);
  });
}

test('1:1 chat files are readable by participants without a lookup', () => {
  const body = matchBody('/conversations/{conversationId}/{messageId}/{fileName}');
  assert.doesNotMatch(body, /firestore\./);
});
