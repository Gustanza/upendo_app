<template>
  <div class="categories-page">
    <div class="page-header">
      <div>
        <p class="subtitle">{{ categories.length }} categor{{ categories.length === 1 ? 'y' : 'ies' }}</p>
      </div>
      <button class="btn-primary" @click="openCreate">+ New Category</button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="empty-state">Loading…</div>

    <!-- Empty -->
    <div v-else-if="!categories.length" class="empty-state">
      <span class="mi empty-icon">category</span>
      <p>No categories yet. Create your first one!</p>
    </div>

    <!-- Table -->
    <div v-else class="table-card">
      <table class="cat-table">
        <thead>
          <tr>
            <th>Icon</th>
            <th>Name</th>
            <th>Parent</th>
            <th>Group</th>
            <th>Color</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="cat in paginated" :key="cat.id">
            <td>
              <div class="icon-badge" :style="{ background: cssColor(cat.colorHex) }">
                <span class="mi">{{ iconChar(cat.iconCode) }}</span>
              </div>
            </td>
            <td class="cat-name">
              {{ cat.name }}
              <span v-if="cat.isProtected" class="lock-badge mi" title="Password protected">lock</span>
            </td>
            <td class="cat-parent">{{ parentName(cat) }}</td>
            <td class="cat-parent">{{ groupName(cat) }}</td>
            <td>
              <span class="color-dot" :style="{ background: cssColor(cat.colorHex) }"></span>
            </td>
            <td class="actions">
              <button class="btn-edit" @click="openEdit(cat)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
                Edit
              </button>
              <button class="btn-delete" @click="confirmDelete(cat)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                  <path d="M10 11v6"/><path d="M14 11v6"/>
                  <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>
                </svg>
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div class="pagination">
        <span class="page-info">
          {{ (currentPage - 1) * PAGE_SIZE + 1 }}–{{ Math.min(currentPage * PAGE_SIZE, categories.length) }}
          of {{ categories.length }} categories
        </span>
        <div class="page-btns">
          <button class="page-btn" :disabled="currentPage === 1" @click="currentPage--">‹ Previous</button>
          <button class="page-btn" :disabled="currentPage === totalPages" @click="currentPage++">Next ›</button>
        </div>
      </div>
    </div>

    <!-- Delete confirmation -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="confirm-modal">
        <template v-if="deleteTargetChildren.length">
          <h3>Can't delete "{{ deleteTarget.name }}"</h3>
          <p>
            This category has {{ deleteTargetChildren.length }}
            subcategor{{ deleteTargetChildren.length === 1 ? 'y' : 'ies' }}
            ({{ deleteTargetChildren.map(c => c.name).join(', ') }})<template v-if="impact && impact.postCount">
            and {{ impact.postCount }} post{{ impact.postCount === 1 ? '' : 's' }} in it and its subcategories</template>.
            Delete or reassign the subcategories (and move their posts) first.
          </p>
          <div class="confirm-actions">
            <button class="btn-cancel" @click="deleteTarget = null">Close</button>
          </div>
        </template>
        <template v-else-if="checkingPosts">
          <h3>Delete "{{ deleteTarget.name }}"?</h3>
          <p>Checking whether any posts use this category…</p>
        </template>
        <template v-else-if="impact && impact.postCount">
          <h3>"{{ deleteTarget.name }}" still has posts</h3>
          <p>{{ deleteBlockMessage(deleteTarget.name, impact) }}</p>
          <div class="move-box">
            <label class="move-label">Move {{ impact.postCount === 1 ? 'it' : 'all ' + impact.postCount }} to:</label>
            <CategoryPicker v-model="moveTarget" :categories="categories" :exclude="[deleteTarget.id]" :size="6" />
            <button class="btn-move" :disabled="moving || !moveTarget" @click="movePostsOut">
              {{ moving ? 'Moving… ' + moveProgress.done + '/' + moveProgress.total : 'Move ' + impact.postCount + ' post' + (impact.postCount === 1 ? '' : 's') }}
            </button>
          </div>
          <label class="ack">
            <input v-model="acknowledged" type="checkbox" />
            Delete anyway — I understand {{ impact.postCount }} post{{ impact.postCount === 1 ? '' : 's' }} will be hidden in the app.
          </label>
          <p v-if="deleteError" class="delete-error">{{ deleteError }}</p>
          <div class="confirm-actions">
            <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
            <button class="btn-confirm-delete" :disabled="deleting || !acknowledged" @click="doDelete">
              {{ deleting ? 'Deleting…' : 'Delete anyway' }}
            </button>
          </div>
        </template>
        <template v-else>
          <h3>Delete "{{ deleteTarget.name }}"?</h3>
          <p v-if="impact">No posts use this category. This will remove it permanently.</p>
          <p v-if="deleteError" class="delete-error">{{ deleteError }}</p>
          <div class="confirm-actions">
            <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
            <button class="btn-confirm-delete" :disabled="deleting || !impact" @click="doDelete">
              {{ deleting ? 'Deleting…' : 'Delete' }}
            </button>
          </div>
        </template>
      </div>
    </div>

    <CategoryFormModal
      v-if="showModal"
      :category="editingCategory"
      :categories="categories"
      :groups="groups"
      @close="showModal = false"
      @saved="onSaved"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, deleteDoc, doc, getDocs, query, where, writeBatch, serverTimestamp } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { flutterColorToCss, iconChar } from '../utils/iconData.js'
import CategoryFormModal from '../components/CategoryFormModal.vue'
import CategoryPicker from '../components/CategoryPicker.vue'
import { deleteImpact, deleteBlockMessage, reassignPosts, categoryIdSet } from '../utils/postCategories.js'
import { chunk } from '../utils/categoryGroups.js'
import { describeFirebaseError } from '../utils/firebaseErrors.js'

const PAGE_SIZE       = 5
const categories      = ref([])
const groups          = ref([])
const loading         = ref(true)
const currentPage     = ref(1)
const showModal       = ref(false)
const editingCategory = ref(null)
const deleteTarget    = ref(null)
const deleting        = ref(false)

const totalPages = computed(() => Math.max(1, Math.ceil(categories.value.length / PAGE_SIZE)))
const paginated  = computed(() =>
  categories.value.slice((currentPage.value - 1) * PAGE_SIZE, currentPage.value * PAGE_SIZE)
)

// If a deletion shrinks totalPages below currentPage, clamp back
watch(totalPages, (tp) => { if (currentPage.value > tp) currentPage.value = tp })

let unsub = null
let unsubGroups = null

onMounted(() => {
  unsub = onSnapshot(collection(db, 'categories'), snap => {
    categories.value = snap.docs.map(d => {
      const data = d.data()
      return {
        id: d.id,
        ...data,
        iconCode:    data.iconCode    ?? 0xe2cc,
        colorHex:    data.colorHex    ?? 0xFF1565C0,
        isProtected: data.isProtected ?? false,
      }
    })
    loading.value = false
  })
  // Category groups (top level) — for the Group column and the form's
  // group select. Fails quietly if the new rules aren't deployed yet.
  unsubGroups = onSnapshot(collection(db, 'categoryGroups'), snap => {
    groups.value = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || (a.name || '').localeCompare(b.name || ''))
  }, () => { groups.value = [] })
})

onUnmounted(() => { unsub?.(); unsubGroups?.() })

function cssColor(hex) { return flutterColorToCss(hex) }

function parentName(cat) {
  if (!cat.parentId) return '—'
  const parent = categories.value.find(c => c.id === cat.parentId)
  return parent ? parent.name : '—'
}

// Subcategories show their parent's group (they inherit its place).
function groupName(cat) {
  const main = cat.parentId ? categories.value.find(c => c.id === cat.parentId) : cat
  if (!main?.groupId) return '—'
  return groups.value.find(g => g.id === main.groupId)?.name ?? '—'
}

function childrenOf(cat) {
  return categories.value.filter(c => c.parentId === cat.id)
}

// Live off the same onSnapshot-synced `categories` list the table renders
// from, so this re-evaluates itself if a child is added/removed while the
// confirm dialog is open.
const deleteTargetChildren = computed(() =>
  deleteTarget.value ? childrenOf(deleteTarget.value) : []
)

function openCreate() {
  editingCategory.value = null
  showModal.value = true
}

function openEdit(cat) {
  editingCategory.value = cat
  showModal.value = true
}

// ── Delete guard ──
// Deleting a category that still had posts left them pointing at a missing
// id, which hides them in the app (this is how every Topics tab went
// empty). Count them first and offer to move them.
const impact        = ref(null)
const checkingPosts = ref(false)
const acknowledged  = ref(false)
const deleteError   = ref(null)
const moveTarget    = ref('')
const moving        = ref(false)
const moveProgress  = ref({ done: 0, total: 0 })

// Posts whose category_id is the category or one of its subcategories
// ('in' queries take at most 30 values).
async function postsUsing(cat) {
  const ids = [cat.id, ...childrenOf(cat).map(c => c.id)]
  const found = []
  for (const part of chunk(ids, 30)) {
    const snap = await getDocs(query(collection(db, 'posts'), where('category_id', 'in', part)))
    found.push(...snap.docs.map(d => ({ id: d.id, ...d.data() })))
  }
  return found
}

async function checkImpact(cat) {
  checkingPosts.value = true
  deleteError.value = null
  try {
    impact.value = deleteImpact(cat.id, categories.value, await postsUsing(cat))
  } catch (e) {
    impact.value = null
    deleteError.value = describeFirebaseError(e, 'Checking posts of this category')
  } finally {
    checkingPosts.value = false
  }
}

function confirmDelete(cat) {
  deleteTarget.value = cat
  impact.value = null
  acknowledged.value = false
  moveTarget.value = ''
  checkImpact(cat)
}

async function movePostsOut() {
  if (!impact.value || !deleteTarget.value) return
  moving.value = true
  deleteError.value = null
  const target = moveTarget.value
  const cat = deleteTarget.value
  try {
    const res = await reassignPosts({
      postIds: [...impact.value.ownPosts, ...impact.value.subPosts].map(p => p.id),
      targetId: target,
      validIds: categoryIdSet(categories.value.filter(c => c.id !== cat.id)),
      onProgress: (p) => { moveProgress.value = p },
      commitChunk: async (ids) => {
        const batch = writeBatch(db)
        ids.forEach(id => batch.update(doc(db, 'posts', id), { category_id: target, updated_at: serverTimestamp() }))
        await batch.commit()
      },
    })
    if (res.error) deleteError.value = res.done + ' of ' + res.total + ' moved. ' + describeFirebaseError(res.error, 'Moving the rest')
  } catch (e) {
    deleteError.value = describeFirebaseError(e, 'Moving posts')
  } finally {
    moving.value = false
  }
  const err = deleteError.value
  await checkImpact(cat)
  if (err) deleteError.value = err
}

async function doDelete() {
  if (!deleteTarget.value) return
  // Re-check right before deleting (not just when the dialog opened) — the
  // template already hides this button once deleteTargetChildren is
  // non-empty, but that's reactive to the same onSnapshot list this reads,
  // so this is a cheap belt-and-suspenders guard rather than a new read.
  if (childrenOf(deleteTarget.value).length > 0) return
  deleting.value = true
  deleteError.value = null
  try {
    // Re-count right before deleting: posts may have been added meanwhile.
    const fresh = deleteImpact(deleteTarget.value.id, categories.value, await postsUsing(deleteTarget.value))
    if (fresh.postCount && (!acknowledged.value || fresh.postCount > (impact.value?.postCount ?? 0))) {
      impact.value = fresh
      acknowledged.value = false
      return
    }
    await deleteDoc(doc(db, 'categories', deleteTarget.value.id))
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = describeFirebaseError(e, 'Deleting the category')
  } finally {
    deleting.value = false
  }
}

function onSaved() {
  showModal.value = false
}
</script>

<style scoped>
.categories-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.subtitle { margin: 4px 0 0; font-size: 13px; color: #6b7280; }

.btn-primary {
  padding: 10px 20px;
  background: #8b2942;
  color: #fff;
  border: none;
  border-radius: 9px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background .15s;
}
.btn-primary:hover { background: #6e1f33; }

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 60px 0;
  color: #9ca3af;
  font-size: 14px;
}
.empty-icon {
  font-size: 48px;
  color: #d1d5db;
}

.table-card {
  background: #fff;
  border-radius: 12px;
  border: 1px solid #e8eaf0;
  overflow: hidden;
}

.cat-table {
  width: 100%;
  border-collapse: collapse;
}

.cat-table thead tr {
  background: #f8f9fc;
  border-bottom: 1px solid #e8eaf0;
}

.cat-table th {
  padding: 12px 16px;
  font-size: 11px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: .6px;
  text-align: left;
}

.cat-table td {
  padding: 14px 16px;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}

.cat-table tbody tr:last-child td { border-bottom: none; }
.cat-table tbody tr:hover { background: #fafbff; }

.icon-badge {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.icon-badge .mi { color: #fff; font-size: 22px; }

.cat-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a1d2e;
  display: flex;
  align-items: center;
  gap: 8px;
}

.lock-badge {
  font-size: 16px;
  color: #6b7280;
}

.cat-parent {
  font-size: 13px;
  color: #6b7280;
}

.color-dot {
  display: inline-block;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  border: 2px solid rgba(0,0,0,.08);
}

.actions { display: flex; gap: 8px; }

.btn-edit, .btn-delete {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 6px 12px;
  border-radius: 7px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all .12s;
  border: 1.5px solid;
}

.btn-edit {
  border-color: #e5e7eb;
  background: #fff;
  color: #374151;
}
.btn-edit:hover { background: #f3f4f6; border-color: #d1d5db; }
.btn-edit svg { width: 13px; height: 13px; }

.btn-delete {
  border-color: #fecaca;
  background: #fff;
  color: #dc2626;
}
.btn-delete:hover { background: #fee2e2; border-color: #fca5a5; }
.btn-delete svg { width: 13px; height: 13px; }

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
.page-btn:hover:not(:disabled) { border-color: #8b2942; color: #8b2942; }
.page-btn:disabled { opacity: .4; cursor: not-allowed; }

/* Delete guard */
.move-box { display: flex; flex-direction: column; gap: 8px; margin: 0 0 14px; }
.move-label { font-size: 13px; font-weight: 600; color: #374151; }
.btn-move {
  align-self: flex-start; padding: 8px 14px; border: none; border-radius: 8px;
  background: #8b2942; color: #fff; font-size: 13px; font-weight: 600; cursor: pointer;
}
.btn-move:disabled { opacity: .5; cursor: not-allowed; }
.ack { display: flex; gap: 8px; align-items: flex-start; font-size: 13px; color: #9a3412; margin: 0 0 14px; }
.delete-error { color: #c81e1e !important; font-size: 13px; }

/* Delete confirmation modal */
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

.confirm-actions { display: flex; justify-content: flex-end; gap: 10px; }

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

.mi {
  font-family: 'Material Icons';
  font-style: normal;
  font-weight: normal;
  line-height: 1;
  display: inline-block;
}
</style>
