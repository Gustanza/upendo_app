<template>
  <div class="admin-page">
    <div class="page-header">
      <div class="tabs">
        <button class="tab" :class="{ active: view === 'requests' }" @click="view = 'requests'">
          Withdrawal requests <span v-if="pendingCount">({{ pendingCount }} pending)</span>
        </button>
        <button class="tab" :class="{ active: view === 'referrals' }" @click="view = 'referrals'">Referral stats</button>
      </div>
      <div v-if="view === 'requests'" class="tabs">
        <button v-for="f in statusFilters" :key="f" class="tab" :class="{ active: statusFilter === f }" @click="statusFilter = f">
          {{ f[0].toUpperCase() + f.slice(1) }}
        </button>
      </div>
      <input v-else v-model="search" class="search-input" placeholder="Search user, email or code…" style="min-width:260px" />
    </div>

    <p class="hint">
      Wallet balances change only through Cloud Functions. <strong>Approve</strong> = you have sent the money manually (marks the request paid);
      <strong>Reject</strong> refunds the amount to the user's wallet.
    </p>
    <p v-if="error" class="error-banner">{{ error }}</p>

    <!-- Requests -->
    <template v-if="view === 'requests'">
      <div v-if="loading" class="empty-state">Loading…</div>
      <div v-else-if="!filteredRequests.length" class="empty-state">No {{ statusFilter === 'all' ? '' : statusFilter }} withdrawal requests.</div>
      <div v-else class="table-card">
        <table>
          <thead>
            <tr><th>Requested</th><th>User</th><th>Amount</th><th>Pay to</th><th>ID</th><th>Notes</th><th>Status</th><th></th></tr>
          </thead>
          <tbody>
            <tr v-for="r in filteredRequests" :key="r.id">
              <td class="muted">{{ formatDate(r.createdAt) }}</td>
              <td>
                <strong>{{ r.fullName }}</strong>
                <div class="muted">{{ r.userName }} · {{ r.userEmail }}</div>
              </td>
              <td><strong>{{ formatTzs(r.amount) }}</strong></td>
              <td class="mono">{{ r.phone }}</td>
              <td>
                <div class="muted">{{ ID_LABELS[r.idType] || r.idType }}</div>
                <button class="btn-sm" @click="viewId(r)">View ID photo</button>
              </td>
              <td class="muted" style="max-width:220px;white-space:pre-wrap">{{ r.notes || '—' }}</td>
              <td>
                <span class="badge" :class="r.status">{{ r.status }}</span>
                <div v-if="r.adminNote" class="muted">{{ r.adminNote }}</div>
              </td>
              <td class="actions">
                <template v-if="r.status === 'pending'">
                  <button class="btn-sm success" :disabled="busyId === r.id" @click="resolve(r, 'approve')">Approve (paid)</button>
                  <button class="btn-sm danger" :disabled="busyId === r.id" @click="resolve(r, 'reject')">Reject</button>
                </template>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <!-- Referral stats -->
    <template v-else>
      <div v-if="!referralRows.length" class="empty-state">No referral activity yet.</div>
      <div v-else class="table-card">
        <table>
          <thead>
            <tr><th>User</th><th>Code</th><th>Referred users</th><th>Total earned</th><th>Balance</th><th>Pending</th><th>Withdrawn</th></tr>
          </thead>
          <tbody>
            <tr v-for="row in referralRows" :key="row.uid">
              <td><strong>{{ row.name }}</strong><div class="muted">{{ row.email }}</div></td>
              <td class="mono">{{ row.code || '—' }}</td>
              <td>{{ row.referred }}</td>
              <td>{{ formatTzs(row.totalEarned) }}</td>
              <td>{{ formatTzs(row.balance) }}</td>
              <td>{{ formatTzs(row.pending) }}</td>
              <td>{{ formatTzs(row.withdrawn) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <!-- ID photo -->
    <div v-if="idPhoto" class="modal-overlay" @click.self="idPhoto = null">
      <div class="modal wide">
        <div class="modal-header">
          <h2>{{ idPhoto.title }}</h2>
          <button class="close-btn" @click="idPhoto = null">×</button>
        </div>
        <div class="modal-body" style="align-items:center">
          <p v-if="idPhoto.error" class="error-banner">{{ idPhoto.error }}</p>
          <p v-else-if="!idPhoto.url" class="muted">Loading…</p>
          <a v-else :href="idPhoto.url" target="_blank" rel="noopener">
            <img :src="idPhoto.url" alt="ID document" style="max-width:100%;max-height:70vh;border-radius:10px" />
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore'
import { ref as storageRef, getDownloadURL } from 'firebase/storage'
import { httpsCallable } from 'firebase/functions'
import { db, storage, functions } from '../fireconfigs.js'
import '../styles/admin-page.css'

const ID_LABELS = { national_id: 'National ID', drivers_license: "Driver's licence", passport: 'Passport' }
const statusFilters = ['pending', 'paid', 'rejected', 'all']

const view         = ref('requests')
const statusFilter = ref('pending')
const search       = ref('')
const requests     = ref([])
const wallets      = ref([])
const users        = ref([])
const loading      = ref(true)
const error        = ref(null)
const busyId       = ref(null)
const idPhoto      = ref(null)

let unsubs = []

onMounted(() => {
  const onErr = (what) => (err) => {
    error.value = `Can't read ${what} (${err.code}). Deploy the new firestore.rules and make sure your email has a doc in the "admins" collection.`
    loading.value = false
  }
  unsubs.push(onSnapshot(query(collection(db, 'withdrawalRequests'), orderBy('createdAt', 'desc')), snap => {
    requests.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    loading.value = false
  }, onErr('withdrawal requests')))
  unsubs.push(onSnapshot(collection(db, 'wallets'), snap => {
    wallets.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
  }, onErr('wallets')))
  unsubs.push(onSnapshot(collection(db, 'users'), snap => {
    users.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
  }))
})
onUnmounted(() => unsubs.forEach(u => u()))

const pendingCount = computed(() => requests.value.filter(r => r.status === 'pending').length)
const filteredRequests = computed(() =>
  statusFilter.value === 'all' ? requests.value : requests.value.filter(r => r.status === statusFilter.value)
)

// One row per user with a referral code or a wallet; "referred users" is
// counted from users.referredBy (the permanent link written server-side).
const referralRows = computed(() => {
  const byUid = new Map(users.value.map(u => [u.id, u]))
  const referredCount = new Map()
  for (const u of users.value) {
    if (u.referredBy) referredCount.set(u.referredBy, (referredCount.get(u.referredBy) || 0) + 1)
  }
  const walletByUid = new Map(wallets.value.map(w => [w.id, w]))
  const uids = new Set([
    ...users.value.filter(u => u.referralCode).map(u => u.id),
    ...wallets.value.map(w => w.id),
  ])
  const q = search.value.trim().toLowerCase()
  return [...uids].map(uid => {
    const u = byUid.get(uid) || {}
    const w = walletByUid.get(uid) || {}
    return {
      uid,
      name: u.fullName || '—',
      email: u.email || uid,
      code: u.referralCode,
      referred: referredCount.get(uid) || 0,
      totalEarned: w.totalEarned || 0,
      balance: w.balance || 0,
      pending: w.pendingWithdrawal || 0,
      withdrawn: w.totalWithdrawn || 0,
    }
  })
    .filter(r => !q || [r.name, r.email, r.code].some(v => (v || '').toLowerCase().includes(q)))
    .sort((a, b) => b.referred - a.referred || b.totalEarned - a.totalEarned)
})

function formatTzs(n) {
  return `TZS ${Number(n || 0).toLocaleString('en-US', { maximumFractionDigits: 2 })}`
}

function formatDate(val) {
  if (!val) return '—'
  const date = val?.toDate ? val.toDate() : new Date(val)
  if (isNaN(date)) return '—'
  return date.toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

// ID photos live under withdrawals/{uid}/ — readable only by the user and
// admins (storage.rules), so the URL is fetched on demand.
async function viewId(r) {
  idPhoto.value = { title: `${r.fullName} — ${ID_LABELS[r.idType] || r.idType}`, url: null, error: null }
  try {
    idPhoto.value.url = await getDownloadURL(storageRef(storage, r.idPhotoPath))
  } catch (e) {
    idPhoto.value.error = e.message || String(e)
  }
}

async function resolve(r, action) {
  const verb = action === 'approve' ? 'Mark as PAID' : 'REJECT and refund'
  const note = window.prompt(`${verb} ${formatTzs(r.amount)} for ${r.fullName}?\nOptional note for the user:`, '')
  if (note === null) return
  busyId.value = r.id
  error.value = null
  try {
    await httpsCallable(functions, 'adminResolveWithdrawal')({ withdrawalId: r.id, action, note })
  } catch (e) {
    error.value = e.message || String(e)
  } finally {
    busyId.value = null
  }
}
</script>
