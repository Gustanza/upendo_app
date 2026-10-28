const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineList } = require('firebase-functions/params');

// Server-side allowlist of dashboard admins. firestore.rules/storage.rules
// recognise an admin by a doc at admins/{lower-cased email}; nobody can
// write that collection from a client, so before this callable existed the
// doc had to be created by hand in the Firebase console — and when it was
// missing every admin-only write (e.g. creating a category group) failed
// with "Missing or insufficient permissions".
//
// Set it in functions/.env.<projectId> and redeploy, either as a comma list
//   ADMIN_EMAILS=a@x.com,b@y.com
// or as a JSON array
//   ADMIN_EMAILS=["a@x.com","b@y.com"]
// (defineList's .value() only understands JSON and throws on a comma list,
// so readAllowlist() below falls back to parsing the raw env var).
const DEFAULT_ADMIN_EMAILS = ['moyoapptanzania@gmail.com'];
const ADMIN_EMAILS = defineList('ADMIN_EMAILS', {
  default: DEFAULT_ADMIN_EMAILS,
  description: 'Google accounts allowed to use the admin dashboard (comma-separated or JSON array).',
});

// Accepts an array, a JSON-array string or a comma-separated string.
function normalizeAllowlist(list) {
  let items = list;
  if (typeof items === 'string') {
    const trimmed = items.trim();
    if (trimmed.startsWith('[')) {
      try { items = JSON.parse(trimmed); } catch { items = trimmed.replace(/^\[|\]$/g, '').split(','); }
    } else {
      items = trimmed.split(',');
    }
  }
  if (!Array.isArray(items)) return [];
  return items
    .map((e) => String(e).trim().replace(/^["']|["']$/g, '').trim().toLowerCase())
    .filter(Boolean);
}

// The configured allowlist. Never throws: a value defineList can't parse
// (e.g. the documented comma form) is read from the raw env var instead.
function readAllowlist({ param = ADMIN_EMAILS, env = process.env } = {}) {
  try {
    const value = param.value();
    const list = normalizeAllowlist(value);
    if (list.length) return list;
  } catch {
    // fall through to the raw env var
  }
  if (typeof env.ADMIN_EMAILS === 'string' && env.ADMIN_EMAILS.trim()) {
    return normalizeAllowlist(env.ADMIN_EMAILS);
  }
  return normalizeAllowlist(DEFAULT_ADMIN_EMAILS);
}

// The caller's verified email from the ID token — never from request.data.
function verifiedEmail(auth) {
  const token = auth && auth.token;
  if (!auth || !auth.uid || !token) return null;
  if (token.email_verified !== true || typeof token.email !== 'string') return null;
  const email = token.email.trim().toLowerCase();
  return email || null;
}

function allowlistedEmail(auth, allowlist) {
  const email = verifiedEmail(auth);
  return email && normalizeAllowlist(allowlist).includes(email) ? email : null;
}

// Creates admins/{email} for an allowlisted, verified caller (idempotent).
// Returns { admin, created }. A caller who isn't allowlisted but already has
// a hand-made admins doc is still reported as an admin.
// [allowlist] may be a list/string or a function returning one; it is only
// read after the auth checks, so a misconfigured param can never turn an
// unauthenticated call into an `internal` error.
async function ensureAdminFor(db, auth, allowlist) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const email = verifiedEmail(auth);
  if (!email) return { admin: false, created: false };

  const list = normalizeAllowlist(typeof allowlist === 'function' ? allowlist() : allowlist);
  if (!list.includes(email)) {
    const existing = await db.collection('admins').doc(email).get();
    return { admin: existing.exists, created: false };
  }
  const ref = db.collection('admins').doc(email);
  const created = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return false;
    tx.set(ref, {
      email,
      uid: auth.uid,
      addedBy: 'ensureAdmin',
      createdAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  return { admin: true, created };
}

// Called by the Vue dashboard right after Google sign-in.
const ensureAdmin = onCall(async (request) =>
  ensureAdminFor(getFirestore(), request.auth, () => readAllowlist()));

module.exports = {
  ensureAdmin, ensureAdminFor, allowlistedEmail, normalizeAllowlist, readAllowlist, verifiedEmail,
};
