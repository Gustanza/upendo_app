<template>
  <div class="admin-page">
    <div class="page-header">
      <div>
        <p class="subtitle">{{ groups.length }} user group{{ groups.length === 1 ? '' : 's' }} created by app users inside subcategories</p>
        <p class="hint">Deleting a group also removes its posts, chat, members and files (cleanupUserGroup function).</p>
      </div>
      <input v-model="search" class="search-input" placeholder="Search by group, owner or subcategory…" style="min-width:280px" />
    </div>

    <p v-if="error" class="error-banner">{{ error }}</p>

    <div v-if="loading" class="empty-state">Loading…</div>
    <div v-else-if="!filtered.length" class="empty-state">No user groups found.</div>

    <div v-else class="table-card">
      <table>
        <thead>
          <tr><th></th><th>Group</th><th>Subcategory</th><th>Owner</th><th>Members</th><th>Created</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="g in filtered" :key="g.id">
            <td>
              <img v-if="g.photoUrl" :src="g.photoUrl" class="avatar" alt="" />
              <div v-else class="avatar">{{ (g.name || '?')[0].toUpperCase() }}</div>
            </td>
            <td>
              <strong>{{ g.name }}</strong>
              <div class="muted" style="max-width:320px">{{ g.description }}</div>
            </td>
            <td class="muted">{{ categoryName(g.subcategoryId) }}</td>
            <td class="muted">{{ g.ownerName || g.ownerId }}</td>
            <td class="muted">{{ g.memberCount ?? 0 }}</td>
            <td class="muted">{{ formatDate(g.createdAt) }}</td>
            <td class="actions">
              <button class="btn-sm" @click="openGroup(g)">View</button>
              <button class="btn-sm danger" @click="deleteTarget = g">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Group detail: posts, chat, members -->
    <div v-if="viewing" class="modal-overlay" @click.self="closeGroup">
      <div class="modal wide">
        <div class="modal-header">
          <h2>{{ viewing.name }}</h2>
          <div class="tabs">
            <button v-for="t in ['posts', 'chat', 'members']" :key="t" class="tab" :class="{ active: tab === t }" @click="tab = t">
              {{ t === 'posts' ? `Posts (${posts.length})` : t === 'chat' ? `Chat (${messages.length})` : `Members (${members.length})` }}
            </button>
          </div>
          <button class="close-btn" @click="closeGroup">×</button>
        </div>
        <div class="modal-body">
          <p v-if="detailError" class="error-banner">{{ detailError }}</p>
          <template v-if="tab === 'posts'">
            <p v-if="!posts.length" class="muted">No posts.</p>
            <div v-for="p in posts" :key="p.id" style="border:1px solid #e8eaf0;border-radius:10px;padding:12px">
              <div style="display:flex;justify-content:space-between;gap:10px">
                <div>
                  <strong>{{ p.authorName }}</strong> <span class="muted">· {{ formatDate(p.createdAt) }}</span>
                  <span v-if="p.type === 'poll'" class="badge pending" style="margin-left:6px">poll</span>
                </div>
                <button class="btn-sm danger" :disabled="busy" @click="deletePost(p)">Delete post</button>
              </div>
              <p style="white-space:pre-wrap;margin:8px 0 0">{{ p.text }}</p>
              <div v-if="(p.attachments || []).length" style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px">
                <a v-for="a in p.attachments" :key="a.path" :href="a.url" target="_blank" rel="noopener" class="btn-sm">
                  {{ a.type }}{{ a.name ? `: ${a.name}` : '' }}
                </a>
              </div>
              <div v-if="(p.links || []).length" style="margin-top:6px">
                <a v-for="l in p.links" :key="l" :href="l" target="_blank" rel="noopener noreferrer" class="muted" style="display:block">{{ l }}</a>
              </div>
            </div>
          </template>
          <template v-else-if="tab === 'chat'">
            <p v-if="!messages.length" class="muted">No messages.</p>
            <div v-for="m in messages" :key="m.id" style="display:flex;justify-content:space-between;gap:10px;border-bottom:1px solid #f3f4f6;padding:6px 0">
              <div>
                <strong>{{ m.senderName || m.senderId }}</strong> <span class="muted">· {{ formatDate(m.createdAt) }}</span>
                <div style="white-space:pre-wrap">{{ m.text || `(${(m.attachments || []).length} attachment(s))` }}</div>
              </div>
              <button class="btn-sm danger" :disabled="busy" @click="deleteMessage(m)">Delete</button>
            </div>
          </template>
          <template v-else>
            <div v-for="m in members" :key="m.id" style="display:flex;justify-content:space-between;border-bottom:1px solid #f3f4f6;padding:6px 0">
              <span>{{ m.name || m.id }} <span v-if="m.role === 'owner'" class="badge paid">owner</span></span>
              <span class="muted">{{ formatDate(m.joinedAt) }}</span>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- Delete group -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="modal" style="width:440px">
        <div class="modal-header"><h2>Delete "{{ deleteTarget.name }}"?</h2></div>
        <div class="modal-body">
          <p class="muted">All of its posts, chat messages, members and uploaded files will be permanently deleted.</p>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
          <button class="btn-danger" :disabled="busy" @click="deleteGroup">{{ busy ? 'Deleting…' : 'Delete group' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { adminReady } from '../utils/adminBootstrap.js'
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, doc, deleteDoc, query, orderBy, limit } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import '../styles/admin-page.css'

const groups       = ref([])
const categories   = ref(new Map())
const loading      = ref(true)
const error        = ref(null)
const search       = ref('')
const viewing      = ref(null)
const tab          = ref('posts')
const posts        = ref([])
const messages     = ref([])
const members      = ref([])
const detailError  = ref(null)
const deleteTarget = ref(null)
const busy         = ref(false)

let unsubs = []
let detailUnsubs = []

onMounted(() => {
  unsubs.push(onSnapshot(collection(db, 'userGroups'), snap => {
    groups.value = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => (b.createdAt?.seconds ?? 0) - (a.createdAt?.seconds ?? 0))
    loading.value = false
  }, err => { error.value = err.message; loading.value = false }))
  unsubs.push(onSnapshot(collection(db, 'categories'), snap => {
    categories.value = new Map(snap.docs.map(d => [d.id, d.data()]))
  }))
})
onUnmounted(() => { unsubs.forEach(u => u()); closeGroup() })

function categoryName(id) {
  const c = categories.value.get(id)
  if (!c) return id || '—'
  const parent = c.parentId ? categories.value.get(c.parentId) : null
  return parent ? `${parent.name} › ${c.name}` : c.name
}

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return groups.value
  return groups.value.filter(g =>
    [g.name, g.ownerName, categoryName(g.subcategoryId)].some(v => (v || '').toLowerCase().includes(q))
  )
})

function formatDate(val) {
  if (!val) return '—'
  const date = val?.toDate ? val.toDate() : new Date(val)
  if (isNaN(date)) return '—'
  return date.toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

// Admins can read members-only content (see isAdmin() in firestore.rules).
function openGroup(g) {
  closeGroup()
  viewing.value = g
  tab.value = 'posts'
  detailError.value = null
  const base = ['userGroups', g.id]
  const onErr = err => { detailError.value = `${err.code}: ${err.message}` }
  detailUnsubs = [
    onSnapshot(query(collection(db, ...base, 'posts'), orderBy('createdAt', 'desc'), limit(100)),
      snap => { posts.value = snap.docs.map(d => ({ id: d.id, ...d.data() })) }, onErr),
    onSnapshot(query(collection(db, ...base, 'messages'), orderBy('createdAt', 'desc'), limit(100)),
      snap => { messages.value = snap.docs.map(d => ({ id: d.id, ...d.data() })) }, onErr),
    onSnapshot(collection(db, ...base, 'members'),
      snap => { members.value = snap.docs.map(d => ({ id: d.id, ...d.data() })) }, onErr),
  ]
}

function closeGroup() {
  detailUnsubs.forEach(u => u())
  detailUnsubs = []
  viewing.value = null
  posts.value = []
  messages.value = []
  members.value = []
}

async function run(action) {
  busy.value = true
  try { await adminReady(); await action() } catch (e) { detailError.value = error.value = e.message || String(e) } finally { busy.value = false }
}

function deletePost(p) {
  if (!confirm('Delete this post? Its replies, likes and files are removed too.')) return
  return run(() => deleteDoc(doc(db, 'userGroups', viewing.value.id, 'posts', p.id)))
}

function deleteMessage(m) {
  if (!confirm('Delete this chat message?')) return
  return run(() => deleteDoc(doc(db, 'userGroups', viewing.value.id, 'messages', m.id)))
}

function deleteGroup() {
  return run(async () => {
    await deleteDoc(doc(db, 'userGroups', deleteTarget.value.id))
    if (viewing.value?.id === deleteTarget.value.id) closeGroup()
    deleteTarget.value = null
  })
}
</script>
