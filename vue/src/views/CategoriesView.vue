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
            <td class="cat-name">{{ cat.name }}</td>
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
        <h3>Delete "{{ deleteTarget.name }}"?</h3>
        <p>This will remove the category. Posts linked to it will keep their category ID but the category won't exist anymore.</p>
        <div class="confirm-actions">
          <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
          <button class="btn-confirm-delete" :disabled="deleting" @click="doDelete">
            {{ deleting ? 'Deleting…' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>

    <CategoryFormModal
      v-if="showModal"
      :category="editingCategory"
      @close="showModal = false"
      @saved="onSaved"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, deleteDoc, doc } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { flutterColorToCss, iconChar } from '../utils/iconData.js'
import CategoryFormModal from '../components/CategoryFormModal.vue'

const PAGE_SIZE       = 5
const categories      = ref([])
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

onMounted(() => {
  unsub = onSnapshot(collection(db, 'categories'), snap => {
    categories.value = snap.docs.map(d => {
      const data = d.data()
      return {
        id: d.id,
        ...data,
        iconCode: data.iconCode  ?? 0xe2cc,
        colorHex: data.colorHex  ?? 0xFF1565C0,
      }
    })
    loading.value = false
  })
})

onUnmounted(() => unsub?.())

function cssColor(hex) { return flutterColorToCss(hex) }

function openCreate() {
  editingCategory.value = null
  showModal.value = true
}

function openEdit(cat) {
  editingCategory.value = cat
  showModal.value = true
}

function confirmDelete(cat) { deleteTarget.value = cat }

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await deleteDoc(doc(db, 'categories', deleteTarget.value.id))
    deleteTarget.value = null
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

.cat-name { font-size: 15px; font-weight: 600; color: #1a1d2e; }

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
.page-btn:hover:not(:disabled) { border-color: #3b4cca; color: #3b4cca; }
.page-btn:disabled { opacity: .4; cursor: not-allowed; }

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
