// Pure core of the admin bootstrap (no Firebase/Vue imports, so it's
// unit-tested: npm test). adminBootstrap.js wires it to the ensureAdmin
// callable and a reactive status for the dashboard banner.

// The banner text for a bootstrap result, or null when nothing's wrong.
export function bootstrapWarning(status) {
  if (!status) return null
  if (status.error) return status.error
  if (status.admin === false) {
    return 'Your admin access is not registered on the server. This account is allowed into the ' +
      'dashboard (VITE_ADMIN_EMAILS) but is not in the Cloud Functions ADMIN_EMAILS list and has no ' +
      'admins/<email> document, so every admin-only change (category groups, users, withdrawals…) ' +
      'will be refused. Add this email to ADMIN_EMAILS in functions/.env.<project> and redeploy ' +
      'the functions, then sign out and back in.'
  }
  return null
}

// One ensureAdmin call per uid. `ready()` resolves (never rejects) once the
// current call settles, so admin-only writes can `await ready()` and never
// race the background call the router starts. A failed call is retried by
// the next ensure()/ready().
//   call(user)    → Promise<{ admin, created }>
//   onStatus(s)   → receives { admin, created } or { error }
//   describe(e)   → message for a failed call
//   currentUser() → the signed-in user (for ready() without an ensure())
export function createAdminGate({ call, onStatus = () => {}, describe = (e) => String(e?.message || e), currentUser = () => null }) {
  let pending = null
  let pendingUid = null

  function ensure(user) {
    if (!user) return Promise.resolve(null)
    if (pending && pendingUid === user.uid) return pending
    pendingUid = user.uid
    const p = Promise.resolve()
      .then(() => call(user))
      .then((data) => {
        onStatus(data)
        return data
      })
      .catch((e) => {
        const status = { error: describe(e) }
        onStatus(status)
        if (pending === p) pending = null // let the next call retry
        return status
      })
    pending = p
    return p
  }

  function ready() {
    if (pending) return pending
    return ensure(currentUser())
  }

  return { ensure, ready }
}
