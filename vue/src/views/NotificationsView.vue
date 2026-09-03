<template>
  <div class="notif-page">

    <div class="page-header">
      <p class="subtitle">{{ notifications.length }} notification{{ notifications.length === 1 ? '' : 's' }}</p>
      <button class="btn-primary" @click="openCompose">+ New Notification</button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="empty-state">Loading…</div>

    <!-- Empty -->
    <div v-else-if="!notifications.length" class="empty-state">
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#d1d5db" stroke-width="1.5">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
      </svg>
      <p>No notifications yet. Compose your first one!</p>
    </div>

    <!-- Table -->
    <div v-else class="table-card">
      <table class="notif-table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Body</th>
            <th>Status</th>
            <th>Created</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="n in notifications" :key="n.id">
            <td class="notif-title">{{ n.title }}</td>
            <td class="notif-body">{{ truncate(n.body) }}</td>
            <td>
              <span v-if="n.sentAt" class="badge sent">Sent {{ formatDate(n.sentAt) }}</span>
              <span v-else-if="n.notify" class="badge sending">Sending…</span>
              <template v-else>
                <span class="badge draft">Draft</span>
              </template>
            </td>
            <td class="muted">{{ formatDate(n.createdAt) }}</td>
            <td class="actions">
              <button
                v-if="!n.notify && !n.sentAt"
                class="btn-send"
                :disabled="sending === n.id"
                @click="sendNow(n)"
              >
                {{ sending === n.id ? 'Sending…' : 'Send Now' }}
              </button>
              <button class="btn-delete" @click="confirmDelete(n)">
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
    </div>

    <!-- Delete confirm -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="confirm-modal">
        <h3>Delete "{{ deleteTarget.title }}"?</h3>
        <p>This will remove the notification permanently.</p>
        <div class="confirm-actions">
          <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
          <button class="btn-confirm-delete" :disabled="deleting" @click="doDelete">
            {{ deleting ? 'Deleting…' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Compose modal -->
    <div v-if="showCompose" class="modal-overlay" @click.self="showCompose = false">
      <div class="modal">
        <div class="modal-header">
          <h2>New Notification</h2>
          <button class="close-btn" @click="showCompose = false">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <div class="modal-body">
          <div class="field">
            <label>Title <span class="required">*</span></label>
            <input v-model="form.title" type="text" placeholder="e.g. New content available" class="text-input" />
          </div>
          <div class="field">
            <label>Body <span class="required">*</span></label>
            <textarea v-model="form.body" rows="3" placeholder="Write your message here…" class="text-input textarea" />
          </div>
          <div class="field">
            <label>Image URL <span class="optional">(optional)</span></label>
            <input v-model="form.imageUrl" type="url" placeholder="https://…" class="text-input" />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showCompose = false">Cancel</button>
          <button class="btn-draft" :disabled="!canSubmit || saving" @click="compose(false)">
            {{ saving === 'draft' ? 'Saving…' : 'Save as Draft' }}
          </button>
          <button class="btn-publish" :disabled="!canSubmit || saving" @click="compose(true)">
            {{ saving === 'publish' ? 'Publishing…' : 'Publish & Notify' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore'
import { db } from '../fireconfigs.js'

const notifications = ref([])
const loading       = ref(true)
const showCompose   = ref(false)
const deleteTarget  = ref(null)
const deleting      = ref(false)
const sending       = ref(null)
const saving        = ref(null)

const form = ref({ title: '', body: '', imageUrl: '' })

const canSubmit = computed(() => form.value.title.trim() && form.value.body.trim())

function openCompose() {
  form.value = { title: '', body: '', imageUrl: '' }
  showCompose.value = true
}

function truncate(str) {
  return str?.length > 60 ? str.slice(0, 60) + '…' : (str ?? '')
}

function formatDate(ts) {
  if (!ts) return '—'
  const d = ts.toDate ? ts.toDate() : new Date(ts)
  return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
    + ' ' + d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })
}

async function compose(notify) {
  saving.value = notify ? 'publish' : 'draft'
  try {
    const payload = {
      title:     form.value.title.trim(),
      body:      form.value.body.trim(),
      notify,
      createdAt: serverTimestamp(),
    }
    if (form.value.imageUrl.trim()) payload.imageUrl = form.value.imageUrl.trim()
    await addDoc(collection(db, 'notifications'), payload)
    showCompose.value = false
  } finally {
    saving.value = null
  }
}

async function sendNow(n) {
  sending.value = n.id
  try {
    await updateDoc(doc(db, 'notifications', n.id), { notify: true })
  } finally {
    sending.value = null
  }
}

function confirmDelete(n) { deleteTarget.value = n }

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await deleteDoc(doc(db, 'notifications', deleteTarget.value.id))
    deleteTarget.value = null
  } finally {
    deleting.value = false
  }
}

let unsub = null

onMounted(() => {
  unsub = onSnapshot(collection(db, 'notifications'), snap => {
    notifications.value = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => (b.createdAt?.seconds ?? 0) - (a.createdAt?.seconds ?? 0))
    loading.value = false
  })
})

onUnmounted(() => unsub?.())
</script>

<style scoped>
.notif-page { display: flex; flex-direction: column; gap: 20px; }

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.subtitle { margin: 0; font-size: 13px; color: #6b7280; }

.btn-primary {
  padding: 10px 20px;
  background: #3b4cca;
  color: #fff;
  border: none;
  border-radius: 9px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background .15s;
}
.btn-primary:hover { background: #2f3da0; }

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 60px 0;
  color: #9ca3af;
  font-size: 14px;
}

.table-card {
  background: #fff;
  border-radius: 12px;
  border: 1px solid #e8eaf0;
  overflow: hidden;
}

.notif-table { width: 100%; border-collapse: collapse; }
.notif-table thead tr { background: #f8f9fc; border-bottom: 1px solid #e8eaf0; }
.notif-table th {
  padding: 12px 16px;
  font-size: 11px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: .6px;
  text-align: left;
}
.notif-table td { padding: 14px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.notif-table tbody tr:last-child td { border-bottom: none; }
.notif-table tbody tr:hover { background: #fafbff; }

.notif-title { font-size: 14px; font-weight: 600; color: #1a1d2e; max-width: 180px; }
.notif-body  { font-size: 13px; color: #6b7280; max-width: 260px; }
.muted       { font-size: 13px; color: #9ca3af; white-space: nowrap; }

.badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 99px;
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}
.badge.sent    { background: #f0fdf4; color: #16a34a; }
.badge.sending { background: #fefce8; color: #ca8a04; }
.badge.draft   { background: #f3f4f6; color: #6b7280; }

.actions { display: flex; align-items: center; gap: 8px; }

.btn-send {
  padding: 6px 14px;
  border-radius: 7px;
  border: 1.5px solid #3b4cca;
  background: #eef0fb;
  color: #3b4cca;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all .12s;
}
.btn-send:hover:not(:disabled) { background: #3b4cca; color: #fff; }
.btn-send:disabled { opacity: .5; cursor: not-allowed; }

.btn-delete {
  width: 30px;
  height: 30px;
  border-radius: 7px;
  border: 1.5px solid #fecaca;
  background: #fff;
  color: #dc2626;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all .12s;
}
.btn-delete:hover { background: #fee2e2; border-color: #fca5a5; }
.btn-delete svg { width: 13px; height: 13px; }

/* Modals */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.confirm-modal {
  background: #fff;
  border-radius: 14px;
  padding: 28px;
  width: 420px;
  max-width: calc(100vw - 32px);
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
}
.confirm-modal h3 { margin: 0 0 10px; font-size: 17px; color: #1a1d2e; }
.confirm-modal p  { margin: 0 0 22px; font-size: 14px; color: #6b7280; line-height: 1.5; }
.confirm-actions  { display: flex; justify-content: flex-end; gap: 10px; }

.modal {
  background: #fff;
  border-radius: 14px;
  width: 520px;
  max-width: calc(100vw - 32px);
  max-height: calc(100vh - 48px);
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 16px;
  border-bottom: 1px solid #e8eaf0;
}
.modal-header h2 { margin: 0; font-size: 17px; font-weight: 700; color: #1a1d2e; }

.close-btn {
  width: 32px; height: 32px;
  border: none; background: none; cursor: pointer;
  border-radius: 8px; color: #6b7280;
  display: flex; align-items: center; justify-content: center;
}
.close-btn:hover { background: #f3f4f6; }
.close-btn svg { width: 16px; height: 16px; }

.modal-body {
  padding: 20px 24px;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.field { display: flex; flex-direction: column; gap: 7px; }
.field > label { font-size: 13px; font-weight: 600; color: #374151; }
.required { color: #dc2626; }
.optional  { font-weight: 400; color: #9ca3af; }

.text-input {
  border: 1.5px solid #e5e7eb;
  border-radius: 8px;
  padding: 9px 12px;
  font-size: 14px;
  outline: none;
  transition: border-color .15s;
  color: #1a1d2e;
  font-family: inherit;
  width: 100%;
  box-sizing: border-box;
}
.text-input:focus { border-color: #3b4cca; }
.textarea { resize: vertical; min-height: 80px; }

.modal-footer {
  padding: 16px 24px;
  border-top: 1px solid #e8eaf0;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-cancel {
  padding: 9px 18px;
  border: 1.5px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
}
.btn-cancel:hover { background: #f3f4f6; }

.btn-draft {
  padding: 9px 18px;
  border: 1.5px solid #3b4cca;
  border-radius: 8px;
  background: #eef0fb;
  color: #3b4cca;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all .15s;
}
.btn-draft:hover:not(:disabled) { background: #dde0f8; }
.btn-draft:disabled { opacity: .5; cursor: not-allowed; }

.btn-publish {
  padding: 9px 22px;
  border: none;
  border-radius: 8px;
  background: #3b4cca;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background .15s;
}
.btn-publish:hover:not(:disabled) { background: #2f3da0; }
.btn-publish:disabled { opacity: .5; cursor: not-allowed; }

.btn-confirm-delete {
  padding: 9px 18px;
  border: none;
  border-radius: 8px;
  background: #dc2626;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.btn-confirm-delete:hover:not(:disabled) { background: #b91c1c; }
.btn-confirm-delete:disabled { opacity: .5; cursor: not-allowed; }
</style>
