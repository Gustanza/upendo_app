// Makes sure the signed-in dashboard account is registered as an admin for
// the security rules (a doc at admins/{email}). The ensureAdmin Cloud
// Function creates it server-side, but only for verified emails in its own
// ADMIN_EMAILS allowlist — the client never supplies the email.
import { ref, computed } from 'vue'
import { httpsCallable } from 'firebase/functions'
import { auth, functions } from '../fireconfigs.js'
import { describeFirebaseError } from './firebaseErrors.js'
import { createAdminGate, bootstrapWarning } from './adminGate.js'

// null = not checked yet; { admin, created } on success; { error } on failure.
export const adminBootstrapStatus = ref(null)

// Banner text shown by DashboardLayout (null = all good).
export const adminBootstrapWarning = computed(() => bootstrapWarning(adminBootstrapStatus.value))

const gate = createAdminGate({
  call: async (user) => {
    const { data } = await httpsCallable(functions, 'ensureAdmin')()
    if (data?.created) console.info('ensureAdmin: registered', user.email, 'as admin')
    return data
  },
  onStatus: (s) => {
    if (s?.error) console.warn('ensureAdmin failed:', s.error)
    adminBootstrapStatus.value = s
  },
  describe: (e) => describeFirebaseError(e, 'Registering your admin access'),
  currentUser: () => auth.currentUser,
})

export const ensureAdminAccess = (user) => gate.ensure(user)

// Await before any admin-only write: resolves once the (possibly still
// running) ensureAdmin call has finished. Never rejects.
export const adminReady = () => gate.ready()
