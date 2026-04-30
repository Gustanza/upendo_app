<template>
  <div class="users-page">

    <!-- Stats row -->
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-value">{{ users.length }}</div>
        <div class="stat-label">Total Users</div>
      </div>
      <div class="stat-card active">
        <div class="stat-value">{{ activeCount }}</div>
        <div class="stat-label">Active</div>
      </div>
      <div class="stat-card inactive">
        <div class="stat-value">{{ users.length - activeCount }}</div>
        <div class="stat-label">Inactive</div>
      </div>
    </div>

    <!-- Controls -->
    <div class="controls">
      <div class="search-wrap">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input
          v-model="search"
          class="search-input"
          type="text"
          placeholder="Search by name or email…"
        />
      </div>
      <div class="filter-tabs">
        <button
          v-for="f in filters"
          :key="f.value"
          class="filter-tab"
          :class="{ active: statusFilter === f.value }"
          @click="statusFilter = f.value"
        >{{ f.label }}</button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="empty-state">Loading users…</div>

    <!-- Empty -->
    <div v-else-if="!filtered.length" class="empty-state">
      <svg viewBox="0 0 24 24" fill="none" stroke="#d1d5db" stroke-width="1.5" style="width:48px;height:48px">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
      </svg>
      <p>No users found</p>
    </div>

    <!-- Table -->
    <div v-else class="table-card">
      <table class="users-table">
        <thead>
          <tr>
            <th>User</th>
            <th>Phone</th>
            <th>Location</th>
            <th>Status</th>
            <th>Joined</th>
            <th>Expires</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in paginated" :key="u.id">
            <!-- User -->
            <td>
              <div class="user-cell">
                <div class="avatar" :style="{ background: avatarColor(u.fullName) }">
                  {{ initials(u.fullName) }}
                </div>
                <div class="user-info">
                  <span class="user-name">{{ u.fullName || '—' }}</span>
                  <span class="user-email">{{ u.email }}</span>
                </div>
              </div>
            </td>
            <!-- Phone -->
            <td class="mono">{{ u.phone || '—' }}</td>
            <!-- Location -->
            <td>
              <span class="location">{{ [u.region, u.country].filter(Boolean).join(', ') || '—' }}</span>
            </td>
            <!-- Status -->
            <td>
              <button
                class="status-badge"
                :class="u.isActive ? 'active' : 'inactive'"
                :title="u.isActive ? 'Click to deactivate' : 'Click to activate'"
                @click="toggleActive(u)"
              >
                <span class="status-dot"></span>
                {{ u.isActive ? 'Active' : 'Inactive' }}
              </button>
            </td>
            <!-- Joined -->
            <td class="date-cell">{{ formatDate(u.createdAt) }}</td>
            <!-- Expires -->
            <td class="date-cell">{{ formatDate(u.expire_date) }}</td>
            <!-- Actions -->
            <td class="actions-cell">
              <button class="btn-action" title="Edit user" @click="openEdit(u)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn-action danger" title="Delete user" @click="confirmDelete(u)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="3 6 5 6 21 6"/>
                  <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                  <path d="M10 11v6"/><path d="M14 11v6"/>
                  <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
                </svg>
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div class="pagination">
        <span class="page-info">
          {{ (currentPage - 1) * PAGE_SIZE + 1 }}–{{ Math.min(currentPage * PAGE_SIZE, filtered.length) }}
          of {{ filtered.length }} users
        </span>
        <div class="page-btns">
          <button class="page-btn" :disabled="currentPage === 1" @click="currentPage--">‹ Previous</button>
          <button class="page-btn" :disabled="currentPage === totalPages" @click="currentPage++">Next ›</button>
        </div>
      </div>
    </div>

    <!-- Edit modal -->
    <div v-if="editingUser" class="modal-overlay" @click.self="editingUser = null">
      <div class="modal">
        <!-- Header -->
        <div class="modal-header">
          <div class="modal-avatar" :style="{ background: avatarColor(editingUser.fullName) }">
            {{ initials(editingUser.fullName) }}
          </div>
          <div>
            <h2 class="modal-name">{{ editingUser.fullName || 'Unknown' }}</h2>
            <p class="modal-email">{{ editingUser.email }}</p>
          </div>
          <button class="close-btn" @click="editingUser = null">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <!-- Info grid -->
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">Phone</span>
            <span class="info-value">{{ editingUser.phone || '—' }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Country</span>
            <span class="info-value">{{ editingUser.country || '—' }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Region</span>
            <span class="info-value">{{ editingUser.region || '—' }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Birth Date</span>
            <span class="info-value">{{ formatBirthDate(editingUser.birthDate) }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Joined</span>
            <span class="info-value">{{ formatDate(editingUser.createdAt) }}</span>
          </div>
        </div>

        <div class="modal-divider"></div>

        <!-- Editable fields -->
        <div class="edit-section">
          <!-- Active toggle -->
          <div class="toggle-row">
            <div>
              <p class="toggle-title">Account Status</p>
              <p class="toggle-sub">{{ editForm.isActive ? 'User can access the app' : 'User is blocked from the app' }}</p>
            </div>
            <label class="toggle-wrap">
              <input type="checkbox" v-model="editForm.isActive" class="toggle-input" />
              <div class="toggle-track"><div class="toggle-thumb"></div></div>
            </label>
          </div>

          <!-- Expiry date -->
          <div class="field">
            <label class="field-label">Expiry Date</label>
            <input
              v-model="editForm.expireDate"
              type="date"
              class="date-input"
            />
            <p class="field-hint">Leave blank to not set an expiry.</p>
          </div>
        </div>

        <!-- Footer -->
        <div class="modal-footer">
          <button class="btn-cancel" @click="editingUser = null">Cancel</button>
          <button class="btn-save" :disabled="saving" @click="saveUser">
            {{ saving ? 'Saving…' : 'Save Changes' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete confirmation -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="confirm-modal">
        <h3>Delete "{{ deleteTarget.fullName || deleteTarget.email }}"?</h3>
        <p>This removes the user record from Firestore. Their Firebase Auth account will remain unless deleted separately.</p>
        <div class="confirm-actions">
          <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
          <button class="btn-confirm-delete" :disabled="deleting" @click="doDelete">
            {{ deleting ? 'Deleting…' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted, reactive } from 'vue'
import {
  collection, onSnapshot,
  doc, updateDoc, deleteDoc, serverTimestamp, Timestamp,
} from 'firebase/firestore'
import { db } from '../fireconfigs.js'

const PAGE_SIZE    = 5
const users        = ref([])
const loading      = ref(true)
const search       = ref('')
const statusFilter = ref('all')
const currentPage  = ref(1)
const editingUser  = ref(null)
const deleteTarget = ref(null)
const saving       = ref(false)
const deleting     = ref(false)

const editForm = reactive({ isActive: false, expireDate: '' })

const filters = [
  { label: 'All',      value: 'all' },
  { label: 'Active',   value: 'active' },
  { label: 'Inactive', value: 'inactive' },
]

let unsub = null

onMounted(() => {
  unsub = onSnapshot(collection(db, 'users'), snap => {
    users.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    loading.value = false
  })
})
onUnmounted(() => unsub?.())

const activeCount = computed(() => users.value.filter(u => u.isActive).length)

const filtered = computed(() => {
  let list = users.value
  if (statusFilter.value === 'active')   list = list.filter(u => u.isActive)
  if (statusFilter.value === 'inactive') list = list.filter(u => !u.isActive)
  const q = search.value.trim().toLowerCase()
  if (q) list = list.filter(u =>
    (u.fullName || '').toLowerCase().includes(q) ||
    (u.email    || '').toLowerCase().includes(q)
  )
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(filtered.value.length / PAGE_SIZE)))
const paginated  = computed(() =>
  filtered.value.slice((currentPage.value - 1) * PAGE_SIZE, currentPage.value * PAGE_SIZE)
)

// Reset to page 1 whenever search or filter changes
watch([search, statusFilter], () => { currentPage.value = 1 })

// ── helpers ──────────────────────────────────────────────────────────────────

const AVATAR_COLORS = [
  '#3b4cca', '#6a1b9a', '#00695c', '#c62828',
  '#e65100', '#00838f', '#283593', '#4e342e',
]

function initials(name) {
  if (!name) return '?'
  return name.trim().split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase()
}

function avatarColor(name) {
  if (!name) return AVATAR_COLORS[0]
  let hash = 0
  for (const c of name) hash = (hash * 31 + c.charCodeAt(0)) & 0xffffffff
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}

function formatDate(val) {
  if (!val) return '—'
  // Firestore Timestamp
  const date = val?.toDate ? val.toDate() : (val?.seconds ? new Date(val.seconds * 1000) : new Date(val))
  if (isNaN(date)) return '—'
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

function formatBirthDate(val) {
  if (!val) return '—'
  const d = new Date(val)
  if (isNaN(d)) return val
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

function tsToInputDate(val) {
  if (!val) return ''
  const date = val?.toDate ? val.toDate() : (val?.seconds ? new Date(val.seconds * 1000) : new Date(val))
  if (isNaN(date)) return ''
  return date.toISOString().slice(0, 10)
}

// ── actions ───────────────────────────────────────────────────────────────────

async function toggleActive(user) {
  await updateDoc(doc(db, 'users', user.id), { isActive: !user.isActive })
}

function openEdit(user) {
  editingUser.value = user
  editForm.isActive   = user.isActive ?? false
  editForm.expireDate = tsToInputDate(user.expire_date)
}

async function saveUser() {
  if (!editingUser.value) return
  saving.value = true
  try {
    const payload = { isActive: editForm.isActive }
    if (editForm.expireDate) {
      payload.expire_date = Timestamp.fromDate(new Date(editForm.expireDate))
    } else {
      payload.expire_date = null
    }
    await updateDoc(doc(db, 'users', editingUser.value.id), payload)
    editingUser.value = null
  } finally {
    saving.value = false
  }
}

function confirmDelete(user) { deleteTarget.value = user }

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await deleteDoc(doc(db, 'users', deleteTarget.value.id))
    deleteTarget.value = null
  } finally {
    deleting.value = false
  }
}
</script>

<style scoped>
.users-page { display: flex; flex-direction: column; gap: 20px; }

/* ── Stats ── */
.stats-row { display: flex; gap: 14px; }

.stat-card {
  flex: 1;
  background: #fff;
  border: 1px solid #e8eaf0;
  border-radius: 12px;
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.stat-value { font-size: 28px; font-weight: 800; color: #1a1d2e; }
.stat-label { font-size: 12px; font-weight: 600; color: #9ca3af; text-transform: uppercase; letter-spacing: .5px; }
.stat-card.active  .stat-value { color: #16a34a; }
.stat-card.inactive .stat-value { color: #dc2626; }

/* ── Controls ── */
.controls { display: flex; align-items: center; justify-content: space-between; gap: 14px; flex-wrap: wrap; }

.search-wrap {
  position: relative;
  flex: 1;
  min-width: 200px;
}
.search-icon {
  position: absolute; left: 11px; top: 50%; transform: translateY(-50%);
  width: 16px; height: 16px; color: #9ca3af; pointer-events: none;
}
.search-input {
  width: 100%; padding: 9px 12px 9px 36px;
  border: 1.5px solid #e5e7eb; border-radius: 9px;
  font-size: 14px; color: #1a1d2e; background: #fff;
  outline: none; transition: border-color .15s; box-sizing: border-box;
}
.search-input:focus { border-color: #3b4cca; }
.search-input::placeholder { color: #9ca3af; }

.filter-tabs { display: flex; gap: 6px; }
.filter-tab {
  padding: 8px 16px; border-radius: 8px; border: 1.5px solid #e5e7eb;
  background: #fff; font-size: 13px; font-weight: 500; color: #6b7280; cursor: pointer;
  transition: all .12s;
}
.filter-tab:hover { border-color: #3b4cca; color: #3b4cca; }
.filter-tab.active { background: #3b4cca; border-color: #3b4cca; color: #fff; }

/* ── Empty ── */
.empty-state {
  display: flex; flex-direction: column; align-items: center;
  gap: 12px; padding: 60px 0; color: #9ca3af; font-size: 14px;
}

/* ── Table ── */
.table-card { background: #fff; border-radius: 12px; border: 1px solid #e8eaf0; overflow: hidden; }

.users-table { width: 100%; border-collapse: collapse; }

.users-table thead tr { background: #f8f9fc; border-bottom: 1px solid #e8eaf0; }
.users-table th {
  padding: 11px 16px; font-size: 11px; font-weight: 700;
  color: #6b7280; text-transform: uppercase; letter-spacing: .6px; text-align: left;
}
.users-table td { padding: 13px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.users-table tbody tr:last-child td { border-bottom: none; }
.users-table tbody tr:hover { background: #fafbff; }

.user-cell { display: flex; align-items: center; gap: 11px; }
.avatar {
  width: 38px; height: 38px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 13px; font-weight: 700; color: #fff; flex-shrink: 0;
}
.user-info { display: flex; flex-direction: column; gap: 2px; }
.user-name  { font-size: 14px; font-weight: 600; color: #1a1d2e; }
.user-email { font-size: 12px; color: #6b7280; }
.mono { font-size: 13px; color: #374151; font-family: monospace; }
.location { font-size: 13px; color: #374151; }
.date-cell { font-size: 13px; color: #6b7280; white-space: nowrap; }

.status-badge {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 4px 10px; border-radius: 999px; border: none;
  font-size: 12px; font-weight: 600; cursor: pointer; transition: all .15s;
}
.status-badge.active   { background: #dcfce7; color: #16a34a; }
.status-badge.inactive { background: #fee2e2; color: #dc2626; }
.status-badge:hover    { filter: brightness(0.93); }
.status-dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: currentColor;
}

.actions-cell { display: flex; gap: 6px; }
.btn-action {
  width: 32px; height: 32px; border-radius: 8px; border: 1.5px solid #e5e7eb;
  background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center;
  color: #6b7280; transition: all .12s;
}
.btn-action svg { width: 14px; height: 14px; }
.btn-action:hover { border-color: #3b4cca; color: #3b4cca; background: #eef0fd; }
.btn-action.danger:hover { border-color: #fca5a5; color: #dc2626; background: #fee2e2; }

/* ── Modal overlay ── */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.45);
  display: flex; align-items: center; justify-content: center; z-index: 1000;
}

/* ── Edit modal ── */
.modal {
  background: #fff; border-radius: 16px;
  width: 500px; max-width: calc(100vw - 32px);
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
  display: flex; flex-direction: column;
}

.modal-header {
  display: flex; align-items: center; gap: 14px;
  padding: 22px 24px 18px; border-bottom: 1px solid #e8eaf0;
}
.modal-avatar {
  width: 52px; height: 52px; border-radius: 50%; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; font-weight: 700; color: #fff;
}
.modal-name  { margin: 0 0 3px; font-size: 17px; font-weight: 700; color: #1a1d2e; }
.modal-email { margin: 0; font-size: 13px; color: #6b7280; }
.close-btn {
  margin-left: auto; width: 32px; height: 32px; border: none;
  background: none; cursor: pointer; border-radius: 8px; color: #6b7280;
  display: flex; align-items: center; justify-content: center;
}
.close-btn:hover { background: #f3f4f6; }
.close-btn svg { width: 16px; height: 16px; }

.info-grid {
  display: grid; grid-template-columns: 1fr 1fr;
  gap: 14px; padding: 18px 24px;
}
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 11px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: .5px; }
.info-value { font-size: 14px; color: #1a1d2e; font-weight: 500; }

.modal-divider { height: 1px; background: #e8eaf0; margin: 0 24px; }

.edit-section { padding: 18px 24px; display: flex; flex-direction: column; gap: 18px; }

.toggle-row {
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 16px; background: #f8f9fc; border-radius: 10px; border: 1px solid #e8eaf0;
}
.toggle-title { margin: 0 0 3px; font-size: 14px; font-weight: 600; color: #1a1d2e; }
.toggle-sub   { margin: 0; font-size: 12px; color: #6b7280; }

.toggle-wrap { position: relative; flex-shrink: 0; cursor: pointer; }
.toggle-input { position: absolute; opacity: 0; width: 0; height: 0; }
.toggle-track {
  width: 44px; height: 24px; border-radius: 12px;
  background: #d1d5db; transition: background .2s; position: relative;
}
.toggle-input:checked ~ .toggle-track { background: #3b4cca; }
.toggle-thumb {
  position: absolute; top: 4px; left: 4px; width: 16px; height: 16px;
  border-radius: 50%; background: #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,.2); transition: transform .2s;
}
.toggle-input:checked ~ .toggle-track .toggle-thumb { transform: translateX(20px); }

.field { display: flex; flex-direction: column; gap: 6px; }
.field-label { font-size: 13px; font-weight: 600; color: #374151; }
.field-hint  { margin: 4px 0 0; font-size: 12px; color: #9ca3af; }
.date-input {
  padding: 9px 12px; border: 1.5px solid #e5e7eb; border-radius: 8px;
  font-size: 14px; color: #1a1d2e; background: #fafbff; outline: none;
  transition: border-color .15s;
}
.date-input:focus { border-color: #3b4cca; }

.modal-footer {
  padding: 16px 24px; border-top: 1px solid #e8eaf0;
  display: flex; justify-content: flex-end; gap: 10px;
}
.btn-cancel {
  padding: 9px 18px; border: 1.5px solid #e5e7eb; border-radius: 8px;
  background: #fff; font-size: 14px; font-weight: 500; color: #374151; cursor: pointer;
}
.btn-cancel:hover { background: #f3f4f6; }
.btn-save {
  padding: 9px 22px; border: none; border-radius: 8px; background: #3b4cca;
  color: #fff; font-size: 14px; font-weight: 600; cursor: pointer; transition: background .15s;
}
.btn-save:hover:not(:disabled) { background: #2f3da0; }
.btn-save:disabled { opacity: .5; cursor: not-allowed; }

/* ── Pagination ── */
.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-top: 1px solid #e8eaf0;
  background: #fafbff;
}
.page-info { font-size: 13px; color: #6b7280; }
.page-btns { display: flex; gap: 6px; }
.page-btn {
  padding: 6px 14px;
  border: 1.5px solid #e5e7eb;
  border-radius: 7px;
  background: #fff;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  transition: all .12s;
}
.page-btn:hover:not(:disabled) { border-color: #3b4cca; color: #3b4cca; }
.page-btn:disabled { opacity: .4; cursor: not-allowed; }

/* ── Confirm delete ── */
.confirm-modal {
  background: #fff; border-radius: 14px; padding: 28px;
  width: 420px; max-width: calc(100vw - 32px);
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
}
.confirm-modal h3 { margin: 0 0 10px; font-size: 17px; color: #1a1d2e; }
.confirm-modal p  { margin: 0 0 22px; font-size: 14px; color: #6b7280; line-height: 1.5; }
.confirm-actions  { display: flex; justify-content: flex-end; gap: 10px; }
.btn-confirm-delete {
  padding: 9px 18px; border: none; border-radius: 8px; background: #dc2626;
  color: #fff; font-size: 14px; font-weight: 600; cursor: pointer;
}
.btn-confirm-delete:hover:not(:disabled) { background: #b91c1c; }
.btn-confirm-delete:disabled { opacity: .5; cursor: not-allowed; }
</style>
