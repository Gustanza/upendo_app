const { getFirestore } = require('firebase-admin/firestore');

// Admins are identified the same way in firestore.rules, storage.rules and
// here: a verified Google sign-in whose (lower-cased) email has a doc in
// the `admins` collection. No client can write them: they're created by the
// ensureAdmin callable (admin/ensureAdmin.js) for accounts in the
// server-side ADMIN_EMAILS param — called by the dashboard after sign-in —
// or by hand in the Firebase console. Keep ADMIN_EMAILS in line with the
// Vue dashboard's VITE_ADMIN_EMAILS.
async function isAdminAuth(auth, db = getFirestore()) {
  const token = auth && auth.token;
  if (!token || token.email_verified !== true || !token.email) return false;
  const snap = await db.collection('admins').doc(String(token.email).toLowerCase()).get();
  return snap.exists;
}

module.exports = { isAdminAuth };
