// Every mobile app user signs in with Google on this same Firebase project,
// so being signed in is not enough to use the dashboard — the account's
// email must also be listed in VITE_ADMIN_EMAILS (comma-separated).
// NOTE: this only gates the UI; Firestore rules still accept any signed-in user.
const ADMIN_EMAILS = (import.meta.env.VITE_ADMIN_EMAILS || '')
  .split(',')
  .map((e) => e.trim().toLowerCase())
  .filter(Boolean)

export function isAdmin(user) {
  const email = user?.email?.toLowerCase()
  return !!email && user.emailVerified && ADMIN_EMAILS.includes(email)
}
