<template>
  <div class="login-page">
    <div class="login-card">

      <div class="login-brand">
        <img src="/moyo-logo.png" alt="Moyo" class="brand-logo" />
        <h1 class="brand-name">Moyo App Admin</h1>
        <p class="brand-sub">Sign in to manage content</p>
      </div>

      <div class="login-form">

        <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>

        <button type="button" class="btn-google" :disabled="loading" @click="signInWithGoogle">
          <span v-if="loading" class="btn-spinner"></span>
          <svg v-else class="google-icon" viewBox="0 0 48 48"><path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34.1 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"/><path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34.1 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/><path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.5 39.6 16.2 44 24 44z"/><path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z"/></svg>
          {{ loading ? 'Signing in…' : 'Sign in with Google' }}
        </button>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { GoogleAuthProvider, signInWithPopup, signOut } from 'firebase/auth'
import { useRouter } from 'vue-router'
import { auth } from '../fireconfigs.js'
import { isAdmin } from '../utils/adminAccess.js'

const loading  = ref(false)
const errorMsg = ref('')

const router = useRouter()

const friendlyError = (code) => {
  const map = {
    'auth/popup-blocked':                         'Pop-up blocked. Allow pop-ups for this site and try again.',
    'auth/unauthorized-domain':                   'This domain is not authorised for sign-in in Firebase.',
    'auth/account-exists-with-different-credential': 'This email is linked to a different sign-in method.',
    'auth/too-many-requests':                     'Too many attempts. Try again later.',
    'auth/network-request-failed':                'Network error. Check your connection.',
  }
  return map[code] || 'Sign-in failed. Please try again.'
}

// Closing the popup is a deliberate cancel, not an error worth showing
const CANCEL_CODES = ['auth/popup-closed-by-user', 'auth/cancelled-popup-request']

async function signInWithGoogle() {
  loading.value  = true
  errorMsg.value = ''
  try {
    const provider = new GoogleAuthProvider()
    provider.setCustomParameters({ prompt: 'select_account' })
    const { user } = await signInWithPopup(auth, provider)
    if (!isAdmin(user)) {
      await signOut(auth)
      errorMsg.value = `${user.email} is not authorised to access the admin dashboard.`
      return
    }
    router.push('/')
  } catch (e) {
    if (!CANCEL_CODES.includes(e.code)) errorMsg.value = friendlyError(e.code)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #2a0f17 0%, #8b2942 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.login-card {
  background: #fff;
  border-radius: 20px;
  padding: 40px 36px;
  width: 100%;
  max-width: 400px;
  box-shadow: 0 24px 60px rgba(0,0,0,0.3);
}

.login-brand {
  text-align: center;
  margin-bottom: 32px;
}
.brand-logo  { height: 64px; width: auto; display: block; margin: 0 auto 12px; }
.brand-name  { margin: 0 0 4px; font-size: 22px; font-weight: 800; color: #1a1d2e; }
.brand-sub   { margin: 0; font-size: 13px; color: #8b8fa8; }

.login-form  { display: flex; flex-direction: column; gap: 16px; }

.error-msg {
  font-size: 13px;
  color: #c81e1e;
  background: #fde8e8;
  padding: 10px 14px;
  border-radius: 8px;
  margin: 0;
}

.btn-google {
  padding: 12px;
  border-radius: 10px;
  border: 1.5px solid #dde0ee;
  background: #fff;
  color: #1a1d2e;
  font-size: 15px;
  font-weight: 700;
  font-family: inherit;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  transition: background 0.15s, border-color 0.15s;
}
.btn-google:hover:not(:disabled) { background: #fafbff; border-color: #8b2942; }
.btn-google:disabled { opacity: 0.65; cursor: not-allowed; }

.google-icon { width: 20px; height: 20px; }

.btn-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(139,41,66,0.25);
  border-top-color: #8b2942;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
