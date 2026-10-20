<template>
  <div class="posts-page">

    <!-- Toolbar -->
    <div class="toolbar">
      <div class="filters">
        <button
          v-for="f in typeFilters"
          :key="f.value"
          class="filter-btn"
          :class="{ active: activeFilter === f.value }"
          @click="setFilter(f.value)"
        >
          {{ f.label }}
        </button>
      </div>
      <div class="toolbar-right">
        <button class="btn-new" @click="openCreate">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="15" height="15"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          New Post
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="state-box">
      <div class="spinner"></div>
      <p>Loading posts…</p>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="state-box error">
      <p>{{ error }}</p>
    </div>

    <!-- Table -->
    <div v-else class="table-wrap">
      <table class="posts-table">
        <thead>
          <tr>
            <th>Thumbnail</th>
            <th>Title</th>
            <th>Type</th>
            <th>Featured</th>
            <th>Hot</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="posts.length === 0">
            <td colspan="6" class="empty">No posts found.</td>
          </tr>
          <tr v-for="post in posts" :key="post.id" class="clickable-row" @click="selectedPost = post">
            <td>
              <img v-if="post.thumbnail" :src="post.thumbnail" class="thumb" alt="" />
              <div v-else class="thumb-placeholder">?</div>
            </td>
            <td>
              <p class="post-title">{{ post.title }}</p>
              <p class="post-subtitle">{{ post.subtitle }}</p>
            </td>
            <td>
              <span class="type-badge" :class="post.type">{{ post.type || 'video' }}</span>
            </td>
            <td>
              <span class="dot" :class="post.featured ? 'yes' : 'no'">{{ post.featured ? 'Yes' : 'No' }}</span>
            </td>
            <td>
              <span class="dot" :class="post.hot ? 'yes' : 'no'">{{ post.hot ? 'Yes' : 'No' }}</span>
            </td>
            <td class="actions-cell" @click.stop>
              <button class="action-btn edit" @click="openEdit(post)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                Edit
              </button>
              <button class="action-btn delete" @click="confirmDelete(post)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination bar -->
      <div class="pagination">
        <span class="page-info">Page {{ currentPage }}</span>
        <div class="page-btns">
          <button class="page-btn" :disabled="!hasPrev || loading" @click="prevPage">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><polyline points="15 18 9 12 15 6"/></svg>
            Previous
          </button>
          <button class="page-btn" :disabled="!hasNext || loading" @click="nextPage">
            Next
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><polyline points="9 18 15 12 9 6"/></svg>
          </button>
        </div>
      </div>
    </div>

    <!-- View modal -->
    <PostDetailModal
      v-if="selectedPost"
      :post="selectedPost"
      @close="selectedPost = null"
    />

    <!-- Create / Edit form drawer -->
    <PostFormModal
      v-if="formPost !== undefined"
      :post="formPost"
      @close="formPost = undefined"
      @saved="onSaved"
    />

    <!-- Delete confirmation -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="confirm-modal">
        <h3>Delete "{{ deleteTarget.title }}"?</h3>
        <p>This will permanently remove the post. This can't be undone.</p>
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
import { ref, computed } from 'vue'
import { collection, getDocs, query, orderBy, where, startAfter, limit, deleteDoc, doc } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import PostDetailModal from '../components/PostDetailModal.vue'
import PostFormModal   from '../components/PostFormModal.vue'

const PAGE_SIZE = 10

const posts        = ref([])
const loading      = ref(true)
const error        = ref(null)
const activeFilter = ref('all')
const selectedPost = ref(null)
const formPost     = ref(undefined)
const deleteTarget = ref(null)
const deleting     = ref(false)

// Cursor stack: each entry is the Firestore DocumentSnapshot that starts that page.
// Index 0 = null (page 1 needs no startAfter cursor).
const pageStarts  = ref([null])
const pageIndex   = ref(0)
const hasNext     = ref(false)

const currentPage = computed(() => pageIndex.value + 1)
const hasPrev     = computed(() => pageIndex.value > 0)

const typeFilters = [
  { label: 'All',   value: 'all' },
  { label: 'Video', value: 'video' },
  { label: 'Audio', value: 'audio' },
  { label: 'PDF',   value: 'pdf' },
  { label: 'Poll',  value: 'poll' },
]

function buildQuery(cursor) {
  const constraints = []
  if (activeFilter.value !== 'all') constraints.push(where('type', '==', activeFilter.value))
  constraints.push(orderBy('title'))
  if (cursor) constraints.push(startAfter(cursor))
  constraints.push(limit(PAGE_SIZE + 1)) // fetch one extra to know if next page exists
  return query(collection(db, 'posts'), ...constraints)
}

async function loadPage() {
  loading.value = true
  error.value   = null
  try {
    const cursor = pageStarts.value[pageIndex.value]
    const snap   = await getDocs(buildQuery(cursor))
    const docs   = snap.docs

    hasNext.value = docs.length > PAGE_SIZE
    const visible = hasNext.value ? docs.slice(0, PAGE_SIZE) : docs

    posts.value = visible.map(d => ({ id: d.id, ...d.data() }))

    // Cache the first doc of the next page so we can navigate forward
    if (hasNext.value && pageStarts.value.length === pageIndex.value + 1) {
      pageStarts.value.push(docs[PAGE_SIZE - 1]) // last visible doc is the cursor for next page
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function resetPagination() {
  pageStarts.value = [null]
  pageIndex.value  = 0
  hasNext.value    = false
}

function setFilter(val) {
  if (val === activeFilter.value) return
  activeFilter.value = val
  resetPagination()
  loadPage()
}

async function nextPage() {
  if (!hasNext.value) return
  pageIndex.value++
  await loadPage()
}

async function prevPage() {
  if (pageIndex.value === 0) return
  pageIndex.value--
  await loadPage()
}

function openCreate()    { formPost.value = null }
function openEdit(post)  { formPost.value = post }
function onSaved()       { resetPagination(); loadPage() }

function confirmDelete(post) { deleteTarget.value = post }

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await deleteDoc(doc(db, 'posts', deleteTarget.value.id))
    deleteTarget.value = null
    resetPagination()
    await loadPage()
  } finally {
    deleting.value = false
  }
}

loadPage()
</script>

<style scoped>
.posts-page { display: flex; flex-direction: column; gap: 20px; }

.toolbar { display: flex; align-items: center; justify-content: space-between; }
.filters { display: flex; gap: 8px; }
.toolbar-right { display: flex; align-items: center; gap: 14px; }

.filter-btn {
  padding: 6px 14px; border-radius: 20px; border: 1px solid #dde0ee;
  background: #fff; color: #555; font-size: 13px; font-weight: 500;
  cursor: pointer; transition: all 0.15s;
}
.filter-btn:hover { border-color: #3b4cca; color: #3b4cca; }
.filter-btn.active { background: #3b4cca; color: #fff; border-color: #3b4cca; }

.btn-new {
  display: flex; align-items: center; gap: 7px; padding: 8px 16px;
  border-radius: 8px; border: none; background: #3b4cca; color: #fff;
  font-size: 13px; font-weight: 600; cursor: pointer; transition: background 0.15s;
}
.btn-new:hover { background: #2d3ba8; }

/* Table */
.table-wrap { background: #fff; border-radius: 12px; border: 1px solid #e8eaf0; overflow: hidden; }

.posts-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.posts-table thead tr { background: #f8f9fc; border-bottom: 1px solid #e8eaf0; }
.posts-table th {
  padding: 12px 16px; text-align: left; font-weight: 600; color: #6b7280;
  font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;
}
.posts-table td { padding: 12px 16px; border-bottom: 1px solid #f0f2f8; vertical-align: middle; }
.posts-table tr:last-child td { border-bottom: none; }
.posts-table tbody tr:hover { background: #fafbff; }
.clickable-row { cursor: pointer; }
.clickable-row:hover .post-title { color: #3b4cca; }

.actions-cell { width: 170px; text-align: right; white-space: nowrap; }
.action-btn {
  display: inline-flex; align-items: center; gap: 5px; padding: 5px 10px;
  border-radius: 6px; border: 1px solid; font-size: 12px; font-weight: 600;
  cursor: pointer; transition: all 0.15s;
}
.action-btn.edit { border-color: #dde0ee; background: #f8f9fc; color: #555; }
.action-btn.edit:hover { border-color: #3b4cca; color: #3b4cca; background: #eef0fd; }
.action-btn.delete { border-color: #fecaca; background: #fff; color: #dc2626; margin-left: 6px; }
.action-btn.delete:hover { border-color: #fca5a5; background: #fee2e2; }

.thumb { width: 56px; height: 40px; object-fit: cover; border-radius: 6px; display: block; }
.thumb-placeholder {
  width: 56px; height: 40px; border-radius: 6px; background: #e8eaf0;
  display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 18px;
}

.post-title    { margin: 0; font-weight: 600; color: #1a1d2e; }
.post-subtitle { margin: 2px 0 0; color: #8b8fa8; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 300px; }

.type-badge { display: inline-block; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; }
.type-badge.video { background: #e8f0fe; color: #1a56db; }
.type-badge.audio { background: #f3e8ff; color: #7c3aed; }
.type-badge.pdf   { background: #fde8e8; color: #c81e1e; }
.type-badge.poll  { background: #fef3c7; color: #b45309; }

.dot { display: inline-flex; align-items: center; gap: 5px; font-size: 13px; font-weight: 500; }
.dot::before { content: ''; width: 7px; height: 7px; border-radius: 50%; display: inline-block; }
.dot.yes { color: #15803d; }
.dot.yes::before { background: #22c55e; }
.dot.no  { color: #9ca3af; }
.dot.no::before  { background: #d1d5db; }

/* Pagination */
.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-top: 1px solid #f0f2f8;
  background: #fafbff;
}

.page-info { font-size: 13px; color: #6b7280; font-weight: 500; }

.page-btns { display: flex; gap: 8px; }

.page-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 7px 14px;
  border-radius: 8px;
  border: 1px solid #dde0ee;
  background: #fff;
  color: #374151;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.page-btn:hover:not(:disabled) { border-color: #3b4cca; color: #3b4cca; background: #eef0fd; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }

/* States */
.state-box { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 60px; color: #8b8fa8; gap: 12px; }
.state-box.error { color: #c81e1e; }

.spinner { width: 32px; height: 32px; border: 3px solid #e8eaf0; border-top-color: #3b4cca; border-radius: 50%; animation: spin 0.7s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.empty { text-align: center; padding: 48px; color: #9ca3af; }

/* Delete confirmation */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.45);
  display: flex; align-items: center; justify-content: center; z-index: 1000;
}
.confirm-modal {
  background: #fff; border-radius: 14px; padding: 28px; width: 420px;
  max-width: calc(100vw - 32px); box-shadow: 0 20px 60px rgba(0,0,0,.2);
}
.confirm-modal h3 { margin: 0 0 10px; font-size: 17px; color: #1a1d2e; }
.confirm-modal p  { margin: 0 0 22px; font-size: 14px; color: #6b7280; line-height: 1.5; }
.confirm-actions { display: flex; justify-content: flex-end; gap: 10px; }
.btn-cancel {
  padding: 9px 18px; border: 1.5px solid #e5e7eb; border-radius: 8px; background: #fff;
  font-size: 14px; font-weight: 500; color: #374151; cursor: pointer;
}
.btn-cancel:hover { background: #f3f4f6; }
.btn-confirm-delete {
  padding: 9px 18px; border: none; border-radius: 8px; background: #dc2626; color: #fff;
  font-size: 14px; font-weight: 600; cursor: pointer;
}
.btn-confirm-delete:hover:not(:disabled) { background: #b91c1c; }
.btn-confirm-delete:disabled { opacity: .5; cursor: not-allowed; }
</style>
