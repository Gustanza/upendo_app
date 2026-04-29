<template>
  <div class="login-page">
    <div class="login-card">

      <div class="login-brand">
        <span class="brand-icon">🌸</span>
        <h1 class="brand-name">Upendo Admin</h1>
        <p class="brand-sub">Sign in to manage content</p>
      </div>

      <form class="login-form" @submit.prevent="submit">

        <div class="field">
          <label class="label" for="email">Email</label>
          <div class="input-wrap">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
            <input
              id="email"
              v-model="email"
              type="email"
              class="input"
              placeholder="admin@example.com"
              autocomplete="email"
              required
            />
          </div>
        </div>

        <div class="field">
          <label class="label" for="password">Password</label>
          <div class="input-wrap">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
            <input
              id="password"
              v-model="password"
              :type="showPw ? 'text' : 'password'"
              class="input"
              placeholder="••••••••"
              autocomplete="current-password"
              required
            />
            <button type="button" class="pw-toggle" @click="showPw = !showPw" tabindex="-1">
              <svg v-if="!showPw" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
            </button>
          </div>
        </div>

        <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>

        <button type="submit" class="btn-submit" :disabled="loading">
          <span v-if="loading" class="btn-spinner"></span>
          {{ loading ? 'Signing in…' : 'Sign in' }}
        </button>

      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { useRouter } from 'vue-router'
import { auth } from '../fireconfigs.js'

const email    = ref('')
const password = ref('')
const showPw   = ref(false)
const loading  = ref(false)
const errorMsg = ref('')

const router = useRouter()

const friendlyError = (code) => {
  const map = {
    'auth/invalid-credential':      'Incorrect email or password.',
    'auth/user-not-found':          'No account found with that email.',
    'auth/wrong-password':          'Incorrect password.',
    'auth/too-many-requests':       'Too many attempts. Try again later.',
    'auth/invalid-email':           'Please enter a valid email address.',
    'auth/network-request-failed':  'Network error. Check your connection.',
  }
  return map[code] || 'Sign-in failed. Please try again.'
}

async function submit() {
  loading.value  = true
  errorMsg.value = ''
  try {
    await signInWithEmailAndPassword(auth, email.value.trim(), password.value)
    router.push('/')
  } catch (e) {
    errorMsg.value = friendlyError(e.code)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #1a1d2e 0%, #2d3ba8 100%);
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
.brand-icon  { font-size: 36px; display: block; margin-bottom: 8px; }
.brand-name  { margin: 0 0 4px; font-size: 22px; font-weight: 800; color: #1a1d2e; }
.brand-sub   { margin: 0; font-size: 13px; color: #8b8fa8; }

.login-form  { display: flex; flex-direction: column; gap: 16px; }

.field       { display: flex; flex-direction: column; gap: 6px; }
.label       { font-size: 13px; font-weight: 600; color: #374151; }

.input-wrap  { position: relative; display: flex; align-items: center; }

.input-icon {
  position: absolute;
  left: 12px;
  width: 16px;
  height: 16px;
  color: #9ca3af;
  pointer-events: none;
  flex-shrink: 0;
}

.input {
  width: 100%;
  padding: 10px 12px 10px 38px;
  border: 1.5px solid #dde0ee;
  border-radius: 10px;
  font-size: 14px;
  color: #1a1d2e;
  background: #fafbff;
  outline: none;
  transition: border-color 0.15s;
  box-sizing: border-box;
  font-family: inherit;
}
.input:focus { border-color: #3b4cca; background: #fff; }

.pw-toggle {
  position: absolute;
  right: 10px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px;
  color: #9ca3af;
  display: flex;
  align-items: center;
}
.pw-toggle:hover { color: #374151; }
.pw-toggle svg { width: 16px; height: 16px; }

.error-msg {
  font-size: 13px;
  color: #c81e1e;
  background: #fde8e8;
  padding: 10px 14px;
  border-radius: 8px;
  margin: 0;
}

.btn-submit {
  margin-top: 4px;
  padding: 12px;
  border-radius: 10px;
  border: none;
  background: #3b4cca;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: background 0.15s;
  letter-spacing: 0.3px;
}
.btn-submit:hover:not(:disabled) { background: #2d3ba8; }
.btn-submit:disabled { opacity: 0.65; cursor: not-allowed; }

.btn-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255,255,255,0.4);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
