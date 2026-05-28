<template>
  <div class="packages-page">

    <!-- Stats -->
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-value">{{ packages.length }}</div>
        <div class="stat-label">Total Packages</div>
      </div>
      <div class="stat-card active">
        <div class="stat-value">{{ activeCount }}</div>
        <div class="stat-label">Active</div>
      </div>
      <div class="stat-card inactive">
        <div class="stat-value">{{ packages.length - activeCount }}</div>
        <div class="stat-label">Inactive</div>
      </div>
    </div>

    <!-- Header -->
    <div class="page-header">
      <p class="subtitle">{{ packages.length }} package{{ packages.length === 1 ? '' : 's' }}</p>
      <button class="btn-primary" @click="openCreate">+ New Package</button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="empty-state">Loading…</div>

    <!-- Empty -->
    <div v-else-if="!packages.length" class="empty-state">
      <svg viewBox="0 0 24 24" fill="none" stroke="#d1d5db" stroke-width="1.5" style="width:48px;height:48px">
        <rect x="2" y="7" width="20" height="14" rx="2"/>
        <path d="M16 7V5a2 2 0 0 0-4 0v2"/>
        <path d="M8 7V5a2 2 0 0 0-4 0v2"/>
      </svg>
      <p>No packages yet. Create your first one!</p>
    </div>

    <!-- Table -->
    <div v-else class="table-card">
      <table class="pkg-table">
        <thead>
          <tr>
            <th>Package</th>
            <th>Price</th>
            <th>Duration</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="pkg in paginated" :key="pkg.id">
            <td>
              <div class="pkg-name-cell">
                <span class="pkg-name">{{ pkg.name }}</span>
                <span v-if="pkg.description" class="pkg-desc">{{ pkg.description }}</span>
              </div>
            </td>
            <td class="price-cell">
              <span class="price">{{ pkg.currency || 'TZS' }} {{ Number(pkg.price).toLocaleString() }}</span>
            </td>
            <td>
              <span class="duration-badge">{{ pkg.durationDays }} day{{ pkg.durationDays === 1 ? '' : 's' }}</span>
            </td>
            <td>
              <button
                class="status-badge"
                :class="pkg.isActive ? 'active' : 'inactive'"
                :title="pkg.isActive ? 'Click to deactivate' : 'Click to activate'"
                @click="toggleActive(pkg)"
              >
                <span class="status-dot"></span>
                {{ pkg.isActive ? 'Active' : 'Inactive' }}
              </button>
            </td>
            <td class="actions-cell">
              <button class="btn-action" title="Edit" @click="openEdit(pkg)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn-action danger" title="Delete" @click="confirmDelete(pkg)">
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
          {{ (currentPage - 1) * PAGE_SIZE + 1 }}–{{ Math.min(currentPage * PAGE_SIZE, packages.length) }}
          of {{ packages.length }} packages
        </span>
        <div class="page-btns">
          <button class="page-btn" :disabled="currentPage === 1" @click="currentPage--">‹ Previous</button>
          <button class="page-btn" :disabled="currentPage === totalPages" @click="currentPage++">Next ›</button>
        </div>
      </div>
    </div>

    <!-- Create / Edit modal -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h2 class="modal-title">{{ editingPackage ? 'Edit Package' : 'New Package' }}</h2>
          <button class="close-btn" @click="closeModal">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <div class="field">
            <label class="field-label">Package Name <span class="required">*</span></label>
            <input v-model="form.name" class="field-input" type="text" placeholder="e.g. Mwezi 1" />
          </div>

          <div class="fields-row">
            <div class="field">
              <label class="field-label">Price <span class="required">*</span></label>
              <input v-model.number="form.price" class="field-input" type="number" min="0" placeholder="3000" />
            </div>
            <div class="field">
              <label class="field-label">Currency</label>
              <select v-model="form.currency" class="field-input">
                <option value="TZS">TZS</option>
                <option value="KES">KES</option>
                <option value="USD">USD</option>
              </select>
            </div>
          </div>

          <div class="field">
            <label class="field-label">Duration (days) <span class="required">*</span></label>
            <input v-model.number="form.durationDays" class="field-input" type="number" min="1" placeholder="30" />
            <p class="field-hint">30 = 1 month, 90 = 3 months, 365 = 1 year</p>
          </div>

          <div class="field">
            <label class="field-label">Description</label>
            <textarea v-model="form.description" class="field-input textarea" rows="2" placeholder="Short description shown to user…"></textarea>
          </div>

          <!-- Active toggle -->
          <div class="toggle-row">
            <div>
              <p class="toggle-title">Available to users</p>
              <p class="toggle-sub">{{ form.isActive ? 'Visible and selectable in the app' : 'Hidden — users cannot select this package' }}</p>
            </div>
            <label class="toggle-wrap">
              <input type="checkbox" v-model="form.isActive" class="toggle-input" />
              <div class="toggle-track"><div class="toggle-thumb"></div></div>
            </label>
          </div>

          <p v-if="formError" class="form-error">{{ formError }}</p>
        </div>

        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">Cancel</button>
          <button class="btn-save" :disabled="saving" @click="savePackage">
            {{ saving ? 'Saving…' : (editingPackage ? 'Save Changes' : 'Create Package') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete confirmation -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="confirm-modal">
        <h3>Delete "{{ deleteTarget.name }}"?</h3>
        <p>This removes the package permanently. Users with an active subscription on this package will not be affected, but new subscriptions cannot use it.</p>
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
  doc, addDoc, updateDoc, deleteDoc, serverTimestamp,
} from 'firebase/firestore'
import { db } from '../fireconfigs.js'

const PAGE_SIZE      = 10
const packages       = ref([])
const loading        = ref(true)
const currentPage    = ref(1)
const showModal      = ref(false)
const editingPackage = ref(null)
const deleteTarget   = ref(null)
const saving         = ref(false)
const deleting       = ref(false)
const formError      = ref('')

const form = reactive({
  name: '',
  price: '',
  currency: 'TZS',
  durationDays: 30,
  description: '',
  isActive: true,
})

let unsub = null

onMounted(() => {
  unsub = onSnapshot(collection(db, 'packages'), snap => {
    packages.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    loading.value = false
  })
})
onUnmounted(() => unsub?.())

const activeCount = computed(() => packages.value.filter(p => p.isActive).length)
const totalPages  = computed(() => Math.max(1, Math.ceil(packages.value.length / PAGE_SIZE)))
const paginated   = computed(() =>
  packages.value.slice((currentPage.value - 1) * PAGE_SIZE, currentPage.value * PAGE_SIZE)
)

watch(totalPages, (tp) => { if (currentPage.value > tp) currentPage.value = tp })

function resetForm() {
  form.name        = ''
  form.price       = ''
  form.currency    = 'TZS'
  form.durationDays = 30
  form.description = ''
  form.isActive    = true
  formError.value  = ''
}

function openCreate() {
  editingPackage.value = null
  resetForm()
  showModal.value = true
}

function openEdit(pkg) {
  editingPackage.value = pkg
  form.name         = pkg.name
  form.price        = pkg.price
  form.currency     = pkg.currency || 'TZS'
  form.durationDays = pkg.durationDays
  form.description  = pkg.description || ''
  form.isActive     = pkg.isActive ?? true
  formError.value   = ''
  showModal.value   = true
}

function closeModal() {
  showModal.value = false
  editingPackage.value = null
}

function validate() {
  if (!form.name.trim())      return 'Package name is required.'
  if (!form.price || form.price <= 0) return 'Price must be greater than 0.'
  if (!form.durationDays || form.durationDays < 1) return 'Duration must be at least 1 day.'
  return ''
}

async function savePackage() {
  const err = validate()
  if (err) { formError.value = err; return }

  saving.value = true
  formError.value = ''
  try {
    const payload = {
      name: form.name.trim(),
      price: Number(form.price),
      currency: form.currency,
      durationDays: Number(form.durationDays),
      description: form.description.trim(),
      isActive: form.isActive,
    }

    if (editingPackage.value) {
      await updateDoc(doc(db, 'packages', editingPackage.value.id), {
        ...payload,
        updatedAt: serverTimestamp(),
      })
    } else {
      await addDoc(collection(db, 'packages'), {
        ...payload,
        createdAt: serverTimestamp(),
      })
    }
    closeModal()
  } catch (e) {
    formError.value = 'Failed to save. Please try again.'
    console.error(e)
  } finally {
    saving.value = false
  }
}

async function toggleActive(pkg) {
  await updateDoc(doc(db, 'packages', pkg.id), { isActive: !pkg.isActive })
}

function confirmDelete(pkg) { deleteTarget.value = pkg }

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await deleteDoc(doc(db, 'packages', deleteTarget.value.id))
    deleteTarget.value = null
  } finally {
    deleting.value = false
  }
}
</script>

<style scoped>
.packages-page { display: flex; flex-direction: column; gap: 20px; }

/* ── Stats ── */
.stats-row { display: flex; gap: 14px; }
.stat-card {
  flex: 1; background: #fff; border: 1px solid #e8eaf0; border-radius: 12px;
  padding: 18px 20px; display: flex; flex-direction: column; gap: 4px;
}
.stat-value { font-size: 28px; font-weight: 800; color: #1a1d2e; }
.stat-label { font-size: 12px; font-weight: 600; color: #9ca3af; text-transform: uppercase; letter-spacing: .5px; }
.stat-card.active   .stat-value { color: #16a34a; }
.stat-card.inactive .stat-value { color: #dc2626; }

/* ── Header ── */
.page-header { display: flex; align-items: center; justify-content: space-between; }
.subtitle { margin: 0; font-size: 13px; color: #6b7280; }
.btn-primary {
  padding: 10px 20px; background: #3b4cca; color: #fff; border: none;
  border-radius: 9px; font-size: 14px; font-weight: 600; cursor: pointer; transition: background .15s;
}
.btn-primary:hover { background: #2f3da0; }

/* ── Empty ── */
.empty-state {
  display: flex; flex-direction: column; align-items: center;
  gap: 12px; padding: 60px 0; color: #9ca3af; font-size: 14px;
}

/* ── Table ── */
.table-card { background: #fff; border-radius: 12px; border: 1px solid #e8eaf0; overflow: hidden; }

.pkg-table { width: 100%; border-collapse: collapse; }
.pkg-table thead tr { background: #f8f9fc; border-bottom: 1px solid #e8eaf0; }
.pkg-table th {
  padding: 11px 16px; font-size: 11px; font-weight: 700;
  color: #6b7280; text-transform: uppercase; letter-spacing: .6px; text-align: left;
}
.pkg-table td { padding: 14px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.pkg-table tbody tr:last-child td { border-bottom: none; }
.pkg-table tbody tr:hover { background: #fafbff; }

.pkg-name-cell { display: flex; flex-direction: column; gap: 2px; }
.pkg-name { font-size: 15px; font-weight: 600; color: #1a1d2e; }
.pkg-desc { font-size: 12px; color: #6b7280; }

.price-cell .price { font-size: 14px; font-weight: 700; color: #1a1d2e; font-family: monospace; }

.duration-badge {
  display: inline-block; padding: 3px 10px; border-radius: 6px;
  background: #eef0fd; color: #3b4cca; font-size: 12px; font-weight: 600;
}

.status-badge {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 4px 10px; border-radius: 999px; border: none;
  font-size: 12px; font-weight: 600; cursor: pointer; transition: all .15s;
}
.status-badge.active   { background: #dcfce7; color: #16a34a; }
.status-badge.inactive { background: #fee2e2; color: #dc2626; }
.status-badge:hover    { filter: brightness(0.93); }
.status-dot { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }

.actions-cell { display: flex; gap: 6px; }
.btn-action {
  width: 32px; height: 32px; border-radius: 8px; border: 1.5px solid #e5e7eb;
  background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center;
  color: #6b7280; transition: all .12s;
}
.btn-action svg { width: 14px; height: 14px; }
.btn-action:hover { border-color: #3b4cca; color: #3b4cca; background: #eef0fd; }
.btn-action.danger:hover { border-color: #fca5a5; color: #dc2626; background: #fee2e2; }

/* ── Pagination ── */
.pagination {
  display: flex; align-items: center; justify-content: space-between;
  padding: 12px 16px; border-top: 1px solid #e8eaf0; background: #fafbff;
}
.page-info { font-size: 13px; color: #6b7280; }
.page-btns { display: flex; gap: 6px; }
.page-btn {
  padding: 6px 14px; border: 1.5px solid #e5e7eb; border-radius: 7px;
  background: #fff; font-size: 13px; font-weight: 500; color: #374151; cursor: pointer; transition: all .12s;
}
.page-btn:hover:not(:disabled) { border-color: #3b4cca; color: #3b4cca; }
.page-btn:disabled { opacity: .4; cursor: not-allowed; }

/* ── Modal overlay ── */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.45);
  display: flex; align-items: center; justify-content: center; z-index: 1000;
}

/* ── Form modal ── */
.modal {
  background: #fff; border-radius: 16px;
  width: 500px; max-width: calc(100vw - 32px);
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
  display: flex; flex-direction: column; max-height: 90vh; overflow: hidden;
}
.modal-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 20px 24px 16px; border-bottom: 1px solid #e8eaf0;
}
.modal-title { margin: 0; font-size: 17px; font-weight: 700; color: #1a1d2e; }
.close-btn {
  width: 32px; height: 32px; border: none; background: none; cursor: pointer;
  border-radius: 8px; color: #6b7280; display: flex; align-items: center; justify-content: center;
}
.close-btn:hover { background: #f3f4f6; }
.close-btn svg { width: 16px; height: 16px; }

.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 16px; overflow-y: auto; }

.field { display: flex; flex-direction: column; gap: 6px; }
.field-label { font-size: 13px; font-weight: 600; color: #374151; }
.required { color: #dc2626; }
.field-hint { margin: 2px 0 0; font-size: 12px; color: #9ca3af; }
.field-input {
  padding: 9px 12px; border: 1.5px solid #e5e7eb; border-radius: 8px;
  font-size: 14px; color: #1a1d2e; background: #fff; outline: none; transition: border-color .15s;
  font-family: inherit;
}
.field-input:focus { border-color: #3b4cca; }
.field-input.textarea { resize: vertical; min-height: 60px; }
select.field-input { cursor: pointer; }

.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

.toggle-row {
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 16px; background: #f8f9fc; border-radius: 10px; border: 1px solid #e8eaf0;
}
.toggle-title { margin: 0 0 3px; font-size: 14px; font-weight: 600; color: #1a1d2e; }
.toggle-sub   { margin: 0; font-size: 12px; color: #6b7280; }
.toggle-wrap  { position: relative; flex-shrink: 0; cursor: pointer; }
.toggle-input { position: absolute; opacity: 0; width: 0; height: 0; }
.toggle-track {
  width: 44px; height: 24px; border-radius: 12px;
  background: #d1d5db; transition: background .2s; position: relative;
}
.toggle-input:checked ~ .toggle-track { background: #3b4cca; }
.toggle-thumb {
  position: absolute; top: 4px; left: 4px; width: 16px; height: 16px;
  border-radius: 50%; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.2); transition: transform .2s;
}
.toggle-input:checked ~ .toggle-track .toggle-thumb { transform: translateX(20px); }

.form-error { margin: 0; font-size: 13px; color: #dc2626; font-weight: 500; }

.modal-footer {
  padding: 16px 24px; border-top: 1px solid #e8eaf0;
  display: flex; justify-content: flex-end; gap: 10px; flex-shrink: 0;
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

/* ── Delete confirm ── */
.confirm-modal {
  background: #fff; border-radius: 14px; padding: 28px;
  width: 420px; max-width: calc(100vw - 32px); box-shadow: 0 20px 60px rgba(0,0,0,.2);
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
