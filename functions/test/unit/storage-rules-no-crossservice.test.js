// Tester-added static guard (complements storage-rules-static.test.js).
//
// The upload paths the CURRENT app uses must be authorised without any
// cross-service firestore.get()/exists() call — production denies those
// unless the Storage service agent has an extra IAM role, and the emulator
// never enforces that. This version follows helper functions transitively
// (a firestore lookup hidden inside e.g. isConversationParticipant() is
// caught), checks reads for the paths the app reads directly, and proves it
// is meaningful by mutating the rules in memory and expecting a failure.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const RULES = fs.readFileSync(path.join(__dirname, '../../../storage.rules'), 'utf8');

function braceBody(src, openIdx) {
  let depth = 0;
  for (let i = openIdx; i < src.length; i++) {
    if (src[i] === '{') depth++;
    if (src[i] === '}' && --depth === 0) return src.slice(openIdx, i + 1);
  }
  throw new Error('unbalanced braces');
}

function stripComments(src) {
  return src.replace(/\/\/[^\n]*/g, '');
}

// name -> body of every `function name(...) { ... }`
function functions(src) {
  const out = {};
  const re = /function\s+(\w+)\s*\([^)]*\)\s*\{/g;
  let m;
  while ((m = re.exec(src))) out[m[1]] = braceBody(src, m.index + m[0].length - 1);
  return out;
}

// Functions that (directly or through other functions) call firestore.*
function tainted(src) {
  const fns = functions(src);
  const bad = new Set(Object.keys(fns).filter((n) => /firestore\.(get|exists)/.test(fns[n])));
  let changed = true;
  while (changed) {
    changed = false;
    for (const [n, body] of Object.entries(fns)) {
      if (bad.has(n)) continue;
      if ([...bad].some((b) => new RegExp(`\\b${b}\\s*\\(`).test(body))) { bad.add(n); changed = true; }
    }
  }
  return bad;
}

function matchBlock(src, pattern) {
  const idx = src.indexOf(`match ${pattern} {`);
  assert.notEqual(idx, -1, `storage.rules has no "match ${pattern}"`);
  return braceBody(src, idx + `match ${pattern} `.length);
}

// All `allow <ops>: if ...;` statements of a block that grant one of [ops].
function statementsFor(block, ops) {
  return [...block.matchAll(/allow\s+([a-z, ]+)\s*:\s*if([^;]*);/g)]
    .filter((m) => m[1].split(',').map((s) => s.trim()).some((o) => ops.includes(o)))
    .map((m) => m[2]);
}

function crossServiceProblems(src, pattern, ops) {
  const clean = stripComments(src);
  const bad = tainted(clean);
  const stmts = statementsFor(matchBlock(clean, pattern), ops);
  assert.ok(stmts.length > 0, `${pattern}: no allow ${ops.join('/')} statement`);
  const problems = [];
  for (const s of stmts) {
    if (/firestore\.(get|exists)/.test(s)) problems.push('direct firestore.* call');
    for (const fn of bad) if (new RegExp(`\\b${fn}\\s*\\(`).test(s)) problems.push(`calls ${fn}() which uses firestore.*`);
  }
  return problems;
}

// Paths written by the current app (lib/utils/storage_paths.dart,
// ChatChannel.storageFolder, ThreadScope.storageFolder, AttachmentService).
const APP_WRITE_PATHS = [
  '/conversations/{conversationId}/{messageId}/{fileName}',      // 1:1 DM files
  '/userGroups/{groupId}/photo/{uid}/{fileName}',                // group picture
  '/userGroups/{groupId}/{kind}/{itemId}/{uid}/{fileName}',      // group posts/messages
  '/subcategoryFeeds/{categoryId}/{kind}/{itemId}/{fileName}',   // subcategory feeds
  '/threadPosts/{postId}/{fileName}',                            // community wall
];
// Paths whose files the app may read via the SDK (getDownloadURL by the
// uploader right after upload, or directly by a participant).
const APP_READ_PATHS = [
  '/conversations/{conversationId}/{messageId}/{fileName}',
  '/userGroups/{groupId}/photo/{uid}/{fileName}',
];

for (const p of APP_WRITE_PATHS) {
  test(`[transitive] create on ${p} has no cross-service lookup`, () => {
    assert.deepEqual(crossServiceProblems(RULES, p, ['create', 'write']), []);
  });
}
for (const p of APP_READ_PATHS) {
  test(`[transitive] read on ${p} has no cross-service lookup`, () => {
    assert.deepEqual(crossServiceProblems(RULES, p, ['read']), []);
  });
}

test('the app\'s Dart storage folders match the rule paths above', () => {
  const dart = fs.readFileSync(path.join(__dirname, '../../../lib/utils/storage_paths.dart'), 'utf8');
  assert.match(dart, /'conversations\/\$conversationId\/\$messageId'/);
  assert.match(dart, /'userGroups\/\$groupId\/\$kind\/\$itemId\/\$uploaderUid'/);
  assert.match(dart, /'userGroups\/\$groupId\/photo\/\$uploaderUid\/\$fileName'/);
  const channel = fs.readFileSync(path.join(__dirname, '../../../lib/models/chat_channel.dart'), 'utf8');
  assert.match(channel, /uploaderFolders \? '\$storagePrefix\/\$messageId\/\$uploaderUid'/);
  const scope = fs.readFileSync(path.join(__dirname, '../../../lib/models/thread_scope.dart'), 'utf8');
  assert.match(scope, /uploaderFolders \? '\$postsPath\/\$postId\/\$uploaderUid'/);
});

// Meaningfulness: the guard must FAIL when a lookup is (re)introduced,
// including one hidden inside a helper function.
test('mutation: a firestore.get hidden in a helper is detected', () => {
  const mutated = RULES.replace(
    /function isConversationParticipant\(conversationId\) \{\s*return signedIn\(\)/,
    'function isConversationParticipant(conversationId) {\n      return signedIn() && firestore.exists(/databases/(default)/documents/conversations/$(conversationId))',
  );
  assert.notEqual(mutated, RULES, 'mutation did not apply');
  assert.notDeepEqual(
    crossServiceProblems(mutated, '/conversations/{conversationId}/{messageId}/{fileName}', ['create', 'write']), []);
});

test('mutation: restoring the old firestore.get DM rule is detected', () => {
  const block = matchBlock(RULES, '/conversations/{conversationId}/{messageId}/{fileName}');
  const old = `{
      allow read, write: if request.auth != null
        && request.auth.uid in firestore.get(
             /databases/(default)/documents/conversations/$(conversationId)).data.participants;
    }`;
  const mutated = RULES.replace(block, old);
  assert.notDeepEqual(
    crossServiceProblems(mutated, '/conversations/{conversationId}/{messageId}/{fileName}', ['create', 'write']), []);
});
