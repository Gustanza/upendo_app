<template>
  <div class="posts-page">

    <!-- Orphaned posts banner -->
    <div v-if="!loading && orphanCount" class="orphan-banner" role="alert">
      <strong>{{ orphanCount }} post{{ orphanCount === 1 ? ' is' : 's are' }} not linked to any existing category and
        {{ orphanCount === 1 ? 'is' : 'are' }} hidden in the app.</strong>
      Their category was deleted. Select them and move them to a category.
      <button v-if="activeFilter !== 'orphans'" class="banner-btn" @click="setFilter('orphans')">Show them</button>
    </div>

    <!-- Toolbar -->
    <div class="toolbar">
      <div class="filters">
        <button
          v-for="f in typeFilters"
          :key="f.value"
          class="filter-btn"
          :class="{ active: activeFilter === f.value, warn: f.value === 'orphans' }"
          @click="setFilter(f.value)"
        >
          {{ f.label }}<template v-if="f.value === 'orphans'"> ({{ orphanCount }})</template>
        </button>
      </div>
      <div class="toolbar-right">
        <button class="btn-new" @click="openCreate">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="15" height="15"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          New Post
        </button>
      </div>
    </div>

    <!-- Bulk move -->
    <div v-if="selected.size" class="bulk-bar">
      <div class="bulk-info">
        <strong>{{ selected.size }} selected</strong>
        <button class="link-btn" @click="clearSelection">Clear</button>
      </div>
      <div class="bulk-move">
        <span class="bulk-label">Move to:</span>
        <CategoryPicker v-model="moveTarget" :categories="categories" :size="5" />
        <button class="btn-new" :disabled="moving || !moveTarget" @click="moveSelected">
          {{ moving ? `Moving… ${moveProgress.done}/${moveProgress.total}` : `Move ${selected.size} post${selected.size === 1 ? '' : 's'}` }}
        </button>
      </div>
    </div>
    <p v-if="moveMessage" class="move-msg" :class="{ error: moveError }">{{ moveMessage }}</p>

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
            <th class="check-cell">
              <input
                type="checkbox"
                :checked="allFilteredSelected"
                :indeterminate.prop="someFilteredSelected && !allFilteredSelected"
                :disabled="!filteredPosts.length"
                title="Select every post in this view"
                @change="toggleAllFiltered"
              />
            </th>
            <th>Thumbnail</th>
            <th>Title</th>
            <th>Category</th>
            <th>Type</th>
            <th>Featured</th>
            <th>Hot</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="pagePosts.length === 0">
            <td colspan="8" class="empty">No posts found.</td>
          </tr>
          <tr v-for="post in pagePosts" :key="post.id" class="clickable-row" @click="selectedPost = post">
            <td class="check-cell" @click.stop>
              <input type="checkbox" :checked="selected.has(post.id)" @change="toggleOne(post.id)" />
            </td>
            <td>
              <img v-if="post.thumbnail" :src="post.thumbnail" class="thumb" alt="" />
              <div v-else class="thumb-placeholder">?</div>
            </td>
            <td>
              <p class="post-title">{{ post.title }}</p>
              <p class="post-subtitle">{{ post.subtitle }}</p>
            </td>
            <td>
              <span v-if="isOrphan(post)" class="orphan-badge" :title="post.category_id ? `category_id ${post.category_id} does not exist` : 'No category set'">
                Category deleted — reassign
              </span>
              <span v-else class="cat-label">{{ labelOf(post.category_id) }}</span>
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
        <span class="page-info">Page {{ currentPage }} of {{ pageCount }} · {{ filteredPosts.length }} post{{ filteredPosts.length === 1 ? '' : 's' }}</span>
        <div class="page-btns">
          <button class="page-btn" :disabled="!hasPrev" @click="pageIndex--">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><polyline points="15 18 9 12 15 6"/></svg>
            Previous
          </button>
          <button class="page-btn" :disabled="!hasNext" @click="pageIndex++">
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
        <p v-if="deleteError" class="move-msg error">{{ deleteError }}</p>
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
// All posts and categories are loaded live (a few hundred docs at most) so
// orphaned posts — category_id pointing at a deleted category, which the
// app never shows — can be counted, filtered, selected and moved in bulk.
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { collection, onSnapshot, deleteDoc, doc, writeBatch, serverTimestamp } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import PostDetailModal from '../components/PostDetailModal.vue'
import PostFormModal   from '../components/PostFormModal.vue'
import CategoryPicker  from '../components/CategoryPicker.vue'
import { categoryOptions } from '../utils/categoryOptions.js'
import { categoryIdSet, isOrphanPost, reassignPosts } from '../utils/postCategories.js'
import { describeFirebaseError } from '../utils/firebaseErrors.js'

const PAGE_SIZE = 10

const route = useRoute()
const posts        = ref([])
const categories   = ref([])
const loading      = ref(true)
const error        = ref(null)
const activeFilter = ref(route.query.filter === 'orphans' ? 'orphans' : 'all')
const selectedPost = ref(null)
const formPost     = ref(undefined)
const deleteTarget = ref(null)
const deleting     = ref(false)
const deleteError  = ref(null)
const pageIndex    = ref(0)

const selected     = ref(new Set())
const moveTarget   = ref('')
const moving       = ref(false)
const moveProgress = ref({ done: 0, total: 0 })
const moveMessage  = ref('')
const moveError    = ref(false)

const typeFilters = [
  { label: 'All',   value: 'all' },
  { label: 'Video', value: 'video' },
  { label: 'Audio', value: 'audio' },
  { label: 'PDF',   value: 'pdf' },
  { label: 'Poll',  value: 'poll' },
  { label: 'Posts without a valid category', value: 'orphans' },
]

let loaded = { posts: false, categories: false }
const unsubs = []
onMounted(() => {
  const fail = (what) => (e) => { error.value = describeFirebaseError(e, `Loading ${what}`); loading.value = false }
  const done = (what) => { loaded[what] = true; if (loaded.posts && loaded.categories) loading.value = false }
  unsubs.push(
    onSnapshot(collection(db, 'posts'), (snap) => {
      posts.value = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
        .sort((a, b) => (a.title || '').localeCompare(b.title || ''))
      done('posts')
    }, fail('posts')),
    onSnapshot(collection(db, 'categories'), (snap) => {
      categories.value = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      done('categories')
    }, fail('categories')),
  )
})
onUnmounted(() => unsubs.forEach((u) => u()))

const validIds   = computed(() => categoryIdSet(categories.value))
const labels     = computed(() => new Map(categoryOptions(categories.value).map((o) => [o.id, o.label])))
const isOrphan   = (p) => isOrphanPost(p, validIds.value)
const labelOf    = (id) => labels.value.get(id) ?? '—'
const orphanCount = computed(() => posts.value.filter(isOrphan).length)

const filteredPosts = computed(() => {
  const f = activeFilter.value
  if (f === 'all') return posts.value
  if (f === 'orphans') return posts.value.filter(isOrphan)
  return posts.value.filter((p) => (p.type || 'video') === f)
})
const pageCount   = computed(() => Math.max(1, Math.ceil(filteredPosts.value.length / PAGE_SIZE)))
const currentPage = computed(() => pageIndex.value + 1)
const hasPrev     = computed(() => pageIndex.value > 0)
const hasNext     = computed(() => pageIndex.value + 1 < pageCount.value)
const pagePosts   = computed(() => filteredPosts.value.slice(pageIndex.value * PAGE_SIZE, (pageIndex.value + 1) * PAGE_SIZE))
watch(pageCount, (n) => { if (pageIndex.value >= n) pageIndex.value = n - 1 })

function setFilter(val) {
  if (val === activeFilter.value) return
  activeFilter.value = val
  pageIndex.value = 0
  clearSelection()
}

// ── selection ──
const allFilteredSelected  = computed(() => filteredPosts.value.length > 0 && filteredPosts.value.every((p) => selected.value.has(p.id)))
const someFilteredSelected = computed(() => filteredPosts.value.some((p) => selected.value.has(p.id)))
function toggleOne(id) {
  const next = new Set(selected.value)
  next.has(id) ? next.delete(id) : next.add(id)
  selected.value = next
}
function toggleAllFiltered() {
  const next = new Set(selected.value)
  if (allFilteredSelected.value) filteredPosts.value.forEach((p) => next.delete(p.id))
  else filteredPosts.value.forEach((p) => next.add(p.id))
  selected.value = next
}
function clearSelection() { selected.value = new Set(); moveMessage.value = '' }

// ── bulk move ──
async function moveSelected() {
  moving.value = true
  moveMessage.value = ''
  moveError.value = false
  const target = moveTarget.value
  try {
    const res = await reassignPosts({
      postIds: [...selected.value],
      targetId: target,
      validIds: validIds.value,
      onProgress: (p) => { moveProgress.value = p },
      commitChunk: async (ids) => {
        const batch = writeBatch(db)
        ids.forEach((id) => batch.update(doc(db, 'posts', id), { category_id: target, updated_at: serverTimestamp() }))
        await batch.commit()
      },
    })
    if (res.error) {
      moveError.value = true
      moveMessage.value = `${res.done} of ${res.total} moved. ` + describeFirebaseError(res.error, 'Moving the rest')
      // keep only the ones that weren't moved selected
      selected.value = new Set([...selected.value].filter((id) => posts.value.find((p) => p.id === id)?.category_id !== target))
    } else {
      moveMessage.value = `Moved ${res.done} post${res.done === 1 ? '' : 's'} to "${labelOf(target)}". They now show in the app.`
      selected.value = new Set()
    }
  } catch (e) {
    moveError.value = true
    moveMessage.value = describeFirebaseError(e, 'Moving posts')
  } finally {
    moving.value = false
  }
}

function openCreate()    { formPost.value = null }
function openEdit(post)  { formPost.value = post }
function onSaved()       { /* live listener refreshes the list */ }

function confirmDelete(post) { deleteTarget.value = post; deleteError.value = null }

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await deleteDoc(doc(db, 'posts', deleteTarget.value.id))
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = describeFirebaseError(e, 'Deleting the post')
  } finally {
    deleting.value = false
  }
}
</script>

<style scoped>
.orphan-banner {
  padding: 12px 16px; border-radius: 10px; background: #fff7ed; border: 1px solid #fdba74;
  color: #9a3412; font-size: 13px; line-height: 1.5; display: flex; flex-wrap: wrap; gap: 6px; align-items: center;
}
.banner-btn, .link-btn {
  border: 1px solid #fdba74; background: #fff; color: #9a3412; border-radius: 6px;
  padding: 3px 10px; font-size: 12px; font-weight: 600; cursor: pointer;
}
.link-btn { border-color: #dde0ee; color: #555; }
.filter-btn.warn { border-color: #fdba74; color: #9a3412; }
.filter-btn.warn.active { background: #c2410c; border-color: #c2410c; color: #fff; }
.bulk-bar {
  display: flex; flex-wrap: wrap; gap: 14px; align-items: flex-start; justify-content: space-between;
  padding: 12px 16px; background: #fff; border: 1px solid #e8eaf0; border-radius: 12px;
}
.bulk-info { display: flex; gap: 10px; align-items: center; font-size: 14px; }
.bulk-move { display: flex; gap: 10px; align-items: flex-start; flex-wrap: wrap; }
.bulk-label { font-size: 13px; color: #6b7280; padding-top: 8px; }
.btn-new:disabled { opacity: .5; cursor: not-allowed; }
.move-msg { margin: 0; font-size: 13px; color: #15803d; }
.move-msg.error { color: #c81e1e; }
.check-cell { width: 36px; }
.orphan-badge {
  display: inline-block; padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700;
  background: #ffedd5; color: #c2410c; white-space: nowrap;
}
.cat-label { font-size: 13px; color: #374151; }
.posts-page { display: flex; flex-direction: column; gap: 20px; }

.toolbar { display: flex; align-items: center; justify-content: space-between; }
.filters { display: flex; gap: 8px; }
.toolbar-right { display: flex; align-items: center; gap: 14px; }

.filter-btn {
  padding: 6px 14px; border-radius: 20px; border: 1px solid #dde0ee;
  background: #fff; color: #555; font-size: 13px; font-weight: 500;
  cursor: pointer; transition: all 0.15s;
}
.filter-btn:hover { border-color: #8b2942; color: #8b2942; }
.filter-btn.active { background: #8b2942; color: #fff; border-color: #8b2942; }

.btn-new {
  display: flex; align-items: center; gap: 7px; padding: 8px 16px;
  border-radius: 8px; border: none; background: #8b2942; color: #fff;
  font-size: 13px; font-weight: 600; cursor: pointer; transition: background 0.15s;
}
.btn-new:hover { background: #6e1f33; }

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
.clickable-row:hover .post-title { color: #8b2942; }

.actions-cell { width: 170px; text-align: right; white-space: nowrap; }
.action-btn {
  display: inline-flex; align-items: center; gap: 5px; padding: 5px 10px;
  border-radius: 6px; border: 1px solid; font-size: 12px; font-weight: 600;
  cursor: pointer; transition: all 0.15s;
}
.action-btn.edit { border-color: #dde0ee; background: #f8f9fc; color: #555; }
.action-btn.edit:hover { border-color: #8b2942; color: #8b2942; background: #f8eaed; }
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
.page-btn:hover:not(:disabled) { border-color: #8b2942; color: #8b2942; background: #f8eaed; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }

/* States */
.state-box { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 60px; color: #8b8fa8; gap: 12px; }
.state-box.error { color: #c81e1e; }

.spinner { width: 32px; height: 32px; border: 3px solid #e8eaf0; border-top-color: #8b2942; border-radius: 50%; animation: spin 0.7s linear infinite; }
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
