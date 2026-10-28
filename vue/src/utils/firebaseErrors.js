// Turns a Firebase (Firestore / Storage / Functions) error into a message an
// admin can act on, always keeping the original code and text so the real
// cause is visible instead of a generic "failed".
// Pure (no Firebase imports) so it's unit-tested: npm test.

const HINTS = {
  'permission-denied':
    'Firebase refused this write. Your account is not recognised as an admin by the security rules ' +
    '(it needs a document at admins/<your email>). Sign out and sign in again so the dashboard can ' +
    'register it; if this keeps happening, make sure the ensureAdmin Cloud Function is deployed and ' +
    'your email is in its ADMIN_EMAILS list.',
  'unauthenticated': 'You are signed out. Sign in again and retry.',
  'unavailable': 'Firebase could not be reached. Check the internet connection and retry.',
  'deadline-exceeded': 'Firebase took too long to answer. Check the connection and retry.',
  'resource-exhausted': 'Firebase quota exceeded. Wait a moment and retry.',
  'invalid-argument': 'Firebase rejected one of the values in the form.',
  'not-found': 'The item no longer exists — it may have been deleted in another tab.',
  'storage/unauthorized': 'Storage refused the upload (security rules).',
}

export function errorCode(e) {
  const raw = (e && e.code) || ''
  // Firestore: "permission-denied"; Functions: "functions/permission-denied";
  // Storage: "storage/unauthorized".
  return String(raw).replace(/^(firestore|functions)\//, '')
}

export function describeFirebaseError(e, action = 'Saving') {
  const code = errorCode(e)
  const message = (e && e.message) || String(e)
  const hint = HINTS[code]
  const detail = code ? `[${code}] ${message}` : message
  return hint ? `${action} failed: ${hint} (${detail})` : `${action} failed: ${detail}`
}
