import { ref } from 'vue'
import { onAuthStateChanged, signOut } from 'firebase/auth'
import { auth } from '../fireconfigs.js'

const user    = ref(null)
const ready   = ref(false)

onAuthStateChanged(auth, (u) => {
  user.value  = u
  ready.value = true
})

export function useAuth() {
  const logout = () => signOut(auth)
  return { user, ready, logout }
}
