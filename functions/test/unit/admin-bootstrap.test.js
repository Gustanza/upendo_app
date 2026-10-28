// ensureAdmin allowlist logic — no emulator needed:  npm test
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { allowlistedEmail, normalizeAllowlist } = require('../../admin/ensureAdmin');

const auth = (email, verified = true, uid = 'u1') => ({ uid, token: { email, email_verified: verified } });
const LIST = ['moyoapptanzania@gmail.com'];

describe('ensureAdmin allowlist', () => {
  test('normalizes list values (array or comma string), case and whitespace', () => {
    assert.deepEqual(normalizeAllowlist([' A@x.com ', '', 'b@Y.com']), ['a@x.com', 'b@y.com']);
    assert.deepEqual(normalizeAllowlist('a@x.com, B@y.com,'), ['a@x.com', 'b@y.com']);
    assert.deepEqual(normalizeAllowlist(undefined), []);
  });

  test('accepts only a verified, allowlisted token email (case-insensitive)', () => {
    assert.equal(allowlistedEmail(auth('moyoapptanzania@gmail.com'), LIST), 'moyoapptanzania@gmail.com');
    assert.equal(allowlistedEmail(auth('MoyoAppTanzania@Gmail.com'), LIST), 'moyoapptanzania@gmail.com');
  });

  test('rejects unverified, missing, other emails and unauthenticated callers', () => {
    assert.equal(allowlistedEmail(auth('moyoapptanzania@gmail.com', false), LIST), null);
    assert.equal(allowlistedEmail(auth('someone@gmail.com'), LIST), null);
    assert.equal(allowlistedEmail({ uid: 'u1', token: {} }, LIST), null);
    assert.equal(allowlistedEmail(null, LIST), null);
    assert.equal(allowlistedEmail(auth('moyoapptanzania@gmail.com'), []), null);
  });
});

// ── ADMIN_EMAILS param formats (tester finding: defineList().value()
// JSON.parses the env var, so the documented comma form made the callable
// throw `internal` for every caller, before the auth check ran).
const { defineList } = require('firebase-functions/params');
const { readAllowlist, ensureAdminFor } = require('../../admin/ensureAdmin');

function withEnv(value, fn) {
  const prev = process.env.ADMIN_EMAILS;
  if (value === undefined) delete process.env.ADMIN_EMAILS; else process.env.ADMIN_EMAILS = value;
  try { return fn(); } finally {
    if (prev === undefined) delete process.env.ADMIN_EMAILS; else process.env.ADMIN_EMAILS = prev;
  }
}
const param = defineList('ADMIN_EMAILS', { default: ['moyoapptanzania@gmail.com'] });
const throwingParam = { value: () => { throw new SyntaxError('Unexpected token, not valid JSON'); } };
// A db that fails the test if touched.
const noDb = { collection: () => { throw new Error('db must not be used'); }, runTransaction: () => { throw new Error('db must not be used'); } };

describe('ADMIN_EMAILS formats', () => {
  test('BUG: the comma form makes defineList().value() throw', () => {
    withEnv('a@x.com,b@y.com', () => assert.throws(() => param.value()));
  });

  test('comma-separated env var is accepted', () => {
    withEnv('A@x.com, b@y.com', () => assert.deepEqual(readAllowlist({ param }), ['a@x.com', 'b@y.com']));
  });

  test('JSON-array env var is accepted', () => {
    withEnv('["A@x.com","b@y.com"]', () => assert.deepEqual(readAllowlist({ param }), ['a@x.com', 'b@y.com']));
    assert.deepEqual(normalizeAllowlist('["a@x.com", "b@y.com"]'), ['a@x.com', 'b@y.com']);
  });

  test('unset falls back to the default account', () => {
    withEnv(undefined, () => assert.deepEqual(readAllowlist({ param }), ['moyoapptanzania@gmail.com']));
  });

  test('a malformed param never throws; the raw env var is used', () => {
    assert.deepEqual(readAllowlist({ param: throwingParam, env: { ADMIN_EMAILS: 'x@y.com' } }), ['x@y.com']);
  });

  test('unauthenticated → unauthenticated error, even when the param is malformed', async () => {
    let read = 0;
    const badList = () => { read++; return throwingParam.value(); };
    await assert.rejects(ensureAdminFor(noDb, null, badList), (e) => e.code === 'unauthenticated');
    await assert.rejects(ensureAdminFor(noDb, { token: {} }, badList), (e) => e.code === 'unauthenticated');
    // unverified email: not an admin, list never read
    assert.deepEqual(await ensureAdminFor(noDb, auth('moyoapptanzania@gmail.com', false), badList), { admin: false, created: false });
    assert.equal(read, 0);
  });

  test('the callable path (comma env) recognises the admin instead of throwing', async () => {
    const writes = [];
    const fakeDb = {
      collection: () => ({ doc: (id) => ({ id }) }),
      runTransaction: async (fn) => fn({ get: async () => ({ exists: false }), set: (ref, data) => writes.push([ref.id, data]) }),
    };
    const res = await withEnv('someone@x.com, MoyoAppTanzania@gmail.com', () =>
      ensureAdminFor(fakeDb, auth('moyoapptanzania@gmail.com'), () => readAllowlist({ param })));
    assert.deepEqual(res, { admin: true, created: true });
    assert.equal(writes[0][0], 'moyoapptanzania@gmail.com');
  });
});
