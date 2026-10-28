<template>
  <div class="admin-page">
    <div class="page-header">
      <div>
        <p class="subtitle">
          {{ groups.length }} group{{ groups.length === 1 ? '' : 's' }} ·
          {{ ungroupedCount }} main categor{{ ungroupedCount === 1 ? 'y' : 'ies' }} not in any group
        </p>
        <p class="hint">App hierarchy: category group → main categories → subcategories. Main categories without a group still show directly on Explore.</p>
      </div>
      <button class="btn-primary" @click="openCreate">+ New Group</button>
    </div>

    <p v-if="error" class="error-banner">{{ error }}</p>

    <div v-if="loading" class="empty-state">Loading…</div>
    <div v-else-if="!groups.length" class="empty-state">
      <span class="mi" style="font-size:48px;color:#d1d5db">layers</span>
      <p>No category groups yet. Create one, then assign main categories to it.</p>
    </div>

    <div v-else class="table-card">
      <table>
        <thead>
          <tr><th>Icon</th><th>Name</th><th title="Lower numbers appear first in the app">Position</th><th>Main categories</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="g in groups" :key="g.id">
            <td>
              <div class="icon-badge" :style="{ background: flutterColorToCss(g.colorHex ?? 0xFF8B2942) }">
                <span class="mi">{{ iconChar(g.iconCode ?? 0xe574) }}</span>
              </div>
            </td>
            <td><strong>{{ g.name }}</strong></td>
            <td class="muted">{{ g.order ?? 0 }}</td>
            <td class="muted">
              {{ mainsIn(g.id).length }}
              <span v-if="mainsIn(g.id).length">— {{ mainsIn(g.id).slice(0, 4).map(c => c.name).join(', ') }}{{ mainsIn(g.id).length > 4 ? '…' : '' }}</span>
            </td>
            <td class="actions">
              <button class="btn-sm" @click="openEdit(g)">Edit</button>
              <button class="btn-sm danger" @click="deleteTarget = g">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Create / edit -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <div class="modal-header">
          <h2>{{ editing ? 'Edit Group' : 'New Group' }}</h2>
          <button class="close-btn" @click="showModal = false">×</button>
        </div>
        <div class="modal-body">
          <p v-if="saveError" class="error-banner">{{ saveError }}</p>
          <div class="field">
            <label>Name</label>
            <input v-model="form.name" class="text-input" placeholder="e.g. Faith & Family" />
          </div>
          <div class="field">
            <label for="group-position">Position (lower numbers appear first)</label>
            <input id="group-position" v-model.number="form.order" type="number" min="0" step="1" class="text-input" />
            <p class="hint">
              Where this group is listed on the app's Explore and Home screens: 1 is shown first, then 2, 3…
              Groups with the same number are sorted by name. New groups default to the end of the list.
            </p>
          </div>
          <div class="field">
            <label>Icon</label>
            <div style="display:flex;flex-wrap:wrap;gap:6px;max-height:150px;overflow:auto">
              <button
                v-for="icon in MATERIAL_ICONS" :key="icon.code" type="button" class="btn-sm"
                :style="form.iconCode === icon.code ? 'border-color:#8b2942;background:#f8eaed' : ''"
                :title="icon.label" @click="form.iconCode = icon.code"
              ><span class="mi">{{ iconChar(icon.code) }}</span></button>
            </div>
          </div>
          <div class="field">
            <label>Colour</label>
            <div style="display:flex;flex-wrap:wrap;gap:8px">
              <button
                v-for="c in COLOR_OPTIONS" :key="c.value" type="button" :title="c.label"
                :style="{ width: '30px', height: '30px', borderRadius: '50%', cursor: 'pointer',
                          background: flutterColorToCss(c.value),
                          border: form.colorHex === c.value ? '3px solid #1a1d2e' : '3px solid transparent' }"
                @click="form.colorHex = c.value"
              />
            </div>
          </div>
          <div class="field">
            <label>Main categories in this group ({{ form.memberIds.size }})</label>
            <input v-model="mainSearch" class="text-input" placeholder="Search main categories…" />
            <div style="max-height:220px;overflow:auto;border:1.5px solid #e5e7eb;border-radius:8px;padding:6px 10px">
              <label v-for="c in filteredMains" :key="c.id" style="display:flex;gap:8px;align-items:center;padding:4px 0;font-size:14px;cursor:pointer">
                <input type="checkbox" :checked="form.memberIds.has(c.id)" @change="toggleMember(c.id)" />
                {{ c.name }}
                <span v-if="c.groupId && c.groupId !== editing?.id" class="muted">(currently in {{ groupNameOf(c.groupId) }})</span>
              </label>
              <p v-if="!filteredMains.length" class="hint">No main categories match.</p>
            </div>
            <p class="hint">Ticking a category that's in another group moves it here.</p>
          </div>
        </div>
        <div class="modal-footer">
          <span v-if="saveError" class="error-banner" style="margin-right:auto;padding:6px 10px">Not saved — see the message above.</span>
          <button class="btn-cancel" @click="showModal = false">Cancel</button>
          <button class="btn-primary" :disabled="saving || !form.name.trim()" @click="save">
            {{ saving ? 'Saving…' : 'Save Group' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete -->
    <div v-if="deleteTarget" class="modal-overlay" @click.self="deleteTarget = null">
      <div class="modal" style="width:440px">
        <div class="modal-header"><h2>Delete "{{ deleteTarget.name }}"?</h2></div>
        <div class="modal-body">
          <p class="muted">Its {{ mainsIn(deleteTarget.id).length }} main categories are not deleted — they become ungrouped and show directly on Explore again.</p>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="deleteTarget = null">Cancel</button>
          <button class="btn-danger" :disabled="saving" @click="doDelete">{{ saving ? 'Deleting…' : 'Delete' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import {
  collection, onSnapshot, doc, addDoc, updateDoc, deleteDoc, writeBatch,
  serverTimestamp, deleteField,
} from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { MATERIAL_ICONS, COLOR_OPTIONS, flutterColorToCss, iconChar } from '../utils/iconData.js'
import { describeFirebaseError } from '../utils/firebaseErrors.js'
import { adminReady } from '../utils/adminBootstrap.js'
import { nextGroupOrder, normalizeOrder, groupMembershipChanges, chunk } from '../utils/categoryGroups.js'
import '../styles/admin-page.css'

const groups      = ref([])
const categories  = ref([])
const loading     = ref(true)
const error       = ref(null)
const showModal   = ref(false)
const editing     = ref(null)
const deleteTarget = ref(null)
const saving      = ref(false)
const saveError   = ref(null)
const mainSearch  = ref('')

const form = reactive({ name: '', order: 0, iconCode: 0xe574, colorHex: 0xFF8B2942, memberIds: new Set() })

let unsubGroups = null
let unsubCats   = null

onMounted(() => {
  unsubGroups = onSnapshot(collection(db, 'categoryGroups'), snap => {
    groups.value = snap.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || (a.name || '').localeCompare(b.name || ''))
    loading.value = false
  }, err => {
    error.value = describeFirebaseError(err, 'Loading category groups')
    loading.value = false
  })
  unsubCats = onSnapshot(collection(db, 'categories'), snap => {
    categories.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
  }, err => {
    error.value = describeFirebaseError(err, 'Loading categories')
  })
})
onUnmounted(() => { unsubGroups?.(); unsubCats?.() })

const mains = computed(() =>
  categories.value.filter(c => !c.parentId).sort((a, b) => (a.name || '').localeCompare(b.name || ''))
)
const groupIds = computed(() => new Set(groups.value.map(g => g.id)))
const ungroupedCount = computed(() => mains.value.filter(c => !c.groupId || !groupIds.value.has(c.groupId)).length)

function mainsIn(groupId) { return mains.value.filter(c => c.groupId === groupId) }
function groupNameOf(id) { return groups.value.find(g => g.id === id)?.name ?? 'another group' }

const filteredMains = computed(() => {
  const q = mainSearch.value.trim().toLowerCase()
  return q ? mains.value.filter(c => (c.name || '').toLowerCase().includes(q)) : mains.value
})

function toggleMember(id) {
  const next = new Set(form.memberIds)
  next.has(id) ? next.delete(id) : next.add(id)
  form.memberIds = next
}

function openCreate() {
  editing.value = null
  Object.assign(form, { name: '', order: nextGroupOrder(groups.value), iconCode: 0xe574, colorHex: 0xFF8B2942, memberIds: new Set() })
  saveError.value = null
  mainSearch.value = ''
  showModal.value = true
}

function openEdit(g) {
  editing.value = g
  Object.assign(form, {
    name: g.name ?? '', order: g.order ?? 0, iconCode: g.iconCode ?? 0xe574,
    colorHex: g.colorHex ?? 0xFF8B2942, memberIds: new Set(mainsIn(g.id).map(c => c.id)),
  })
  saveError.value = null
  mainSearch.value = ''
  showModal.value = true
}

// Firestore batches hold at most 500 writes — there are ~1000 categories.
async function commitInChunks(updates) {
  for (const part of chunk(updates, 450)) {
    const batch = writeBatch(db)
    part.forEach(([ref, data]) => batch.update(ref, data))
    await batch.commit()
  }
}

async function save() {
  saving.value = true
  saveError.value = null
  let step = 'Saving the group'
  try {
    // categoryGroups writes are admin-only: don't race the sign-in bootstrap.
    await adminReady()
    const payload = {
      name: form.name.trim(),
      order: normalizeOrder(form.order, nextGroupOrder(groups.value)),
      iconCode: form.iconCode,
      colorHex: form.colorHex,
      updatedAt: serverTimestamp(),
    }
    let groupId
    if (editing.value) {
      groupId = editing.value.id
      await updateDoc(doc(db, 'categoryGroups', groupId), payload)
    } else {
      const ref = await addDoc(collection(db, 'categoryGroups'), { ...payload, createdAt: serverTimestamp() })
      groupId = ref.id
      // From here on a retry must update this group, not create a second one.
      editing.value = { id: groupId, ...payload }
    }
    // Assign ticked main categories to this group; untick → ungrouped.
    step = 'The group was saved, but assigning its main categories'
    const updates = groupMembershipChanges(mains.value, groupId, form.memberIds).map(([id, kind]) => [
      doc(db, 'categories', id),
      kind === 'set' ? { groupId, updatedAt: serverTimestamp() } : { groupId: deleteField(), updatedAt: serverTimestamp() },
    ])
    await commitInChunks(updates)
    showModal.value = false
  } catch (e) {
    console.error('CategoryGroupsView.save', e)
    saveError.value = describeFirebaseError(e, step)
  } finally {
    saving.value = false
  }
}

async function doDelete() {
  const g = deleteTarget.value
  if (!g) return
  saving.value = true
  try {
    await adminReady()
    await commitInChunks(mainsIn(g.id).map(c => [doc(db, 'categories', c.id), { groupId: deleteField() }]))
    await deleteDoc(doc(db, 'categoryGroups', g.id))
    deleteTarget.value = null
  } catch (e) {
    console.error('CategoryGroupsView.doDelete', e)
    error.value = describeFirebaseError(e, 'Deleting the group')
    deleteTarget.value = null
  } finally {
    saving.value = false
  }
}
</script>
