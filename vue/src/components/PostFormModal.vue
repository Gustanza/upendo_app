<template>
  <Teleport to="body">
    <div class="overlay" @click.self="$emit('close')">
      <div class="drawer">

        <!-- Header -->
        <div class="drawer-header">
          <div>
            <p class="drawer-eyebrow">{{ isEdit ? 'Edit Post' : 'New Post' }}</p>
            <h2 class="drawer-title">{{ isEdit ? form.title || 'Untitled' : 'Create a post' }}</h2>
          </div>
          <button class="close-btn" @click="$emit('close')">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <!-- Form -->
        <form class="drawer-body" @submit.prevent="save">

          <!-- Type selector -->
          <div class="field">
            <label class="label">Content Type</label>
            <div class="type-tabs">
              <button
                v-for="t in types"
                :key="t.value"
                type="button"
                class="type-tab"
                :class="{ active: form.type === t.value }"
                @click="form.type = t.value"
              >
                <span class="type-tab-icon">{{ t.icon }}</span>
                {{ t.label }}
              </button>
            </div>
          </div>

          <!-- Title -->
          <div class="field">
            <label class="label" for="f-title">Title <span class="req">*</span></label>
            <input id="f-title" v-model="form.title" class="input" type="text" placeholder="e.g. Changamot za Kimaisha" required />
          </div>

          <!-- Subtitle -->
          <div class="field">
            <label class="label" for="f-subtitle">Subtitle</label>
            <input id="f-subtitle" v-model="form.subtitle" class="input" type="text" placeholder="Short description shown in the list" />
          </div>

          <!-- Description -->
          <div class="field">
            <label class="label" for="f-desc">Description</label>
            <textarea id="f-desc" v-model="form.description" class="input textarea" rows="3" placeholder="Full description of this post…"></textarea>
          </div>

          <!-- Category -->
          <div class="field">
            <label class="label">Category</label>
            <div v-if="categoriesLoading" class="cat-loading">Loading categories…</div>
            <div v-else class="cat-dropdown" v-click-outside="() => catOpen = false">
              <button type="button" class="cat-trigger" @click="catOpen = !catOpen">
                <template v-if="selectedCategory">
                  <span class="cat-trigger-icon" :style="{ background: catCssColor(selectedCategory.colorHex) }">
                    <span class="mi">{{ catIconChar(selectedCategory.iconCode) }}</span>
                  </span>
                  <span class="cat-trigger-name">{{ selectedCategory.name }}</span>
                </template>
                <template v-else>
                  <span class="cat-trigger-placeholder">Select a category…</span>
                </template>
                <svg class="cat-chevron" :class="{ open: catOpen }" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="6 9 12 15 18 9"/>
                </svg>
              </button>

              <div v-if="catOpen" class="cat-menu">
                <button type="button" class="cat-option" :class="{ active: form.category_id === '' }" @click="selectCat(null)">
                  <span class="cat-option-icon-none">—</span>
                  <span class="cat-option-name">None</span>
                </button>
                <button
                  v-for="cat in categories"
                  :key="cat.id"
                  type="button"
                  class="cat-option"
                  :class="{ active: form.category_id === cat.id }"
                  @click="selectCat(cat)"
                >
                  <span class="cat-option-icon" :style="{ background: catCssColor(cat.colorHex) }">
                    <span class="mi">{{ catIconChar(cat.iconCode) }}</span>
                  </span>
                  <span class="cat-option-name">{{ cat.name }}</span>
                  <svg v-if="form.category_id === cat.id" class="cat-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>

          <!-- Thumbnail upload -->
          <div class="field">
            <label class="label">
              Thumbnail
              <span class="label-hint">Image shown in lists and cards</span>
            </label>
            <FileUploader
              label="thumbnail"
              accept="image/*"
              hint="PNG, JPG, WEBP — any size"
              storage-path="thumbnails"
              :current-url="form.thumbnail"
              @uploaded="form.thumbnail = $event"
            />
          </div>

          <!-- File upload -->
          <div class="field">
            <label class="label">
              {{ fileLabel }} <span class="req">*</span>
              <span class="label-hint">{{ fileHint }}</span>
            </label>
            <FileUploader
              :key="form.type"
              :label="fileLabel"
              :accept="fileAccept"
              :hint="fileHint"
              :storage-path="fileStoragePath"
              :current-url="form.file_url"
              @uploaded="form.file_url = $event"
            />
          </div>

          <!-- Toggles -->
          <div class="toggles-row">
            <label class="toggle-label">
              <div class="toggle-wrap">
                <input type="checkbox" v-model="form.featured" class="toggle-input" />
                <div class="toggle-track"><div class="toggle-thumb"></div></div>
              </div>
              <span>
                <strong>Featured</strong>
                <em>Shows in "Somo la Leo!" carousel</em>
              </span>
            </label>

            <label class="toggle-label">
              <div class="toggle-wrap">
                <input type="checkbox" v-model="form.hot" class="toggle-input" />
                <div class="toggle-track"><div class="toggle-thumb"></div></div>
              </div>
              <span>
                <strong>Hot</strong>
                <em>Shows in "Mada za Moto!" strip</em>
              </span>
            </label>
          </div>

          <!-- Save error -->
          <p v-if="saveError" class="save-error">{{ saveError }}</p>

          <!-- Footer -->
          <div class="drawer-footer">
            <button type="button" class="btn-ghost" @click="$emit('close')" :disabled="saving">Cancel</button>
            <button type="submit" class="btn-primary" :disabled="saving || !form.file_url">
              <span v-if="saving" class="btn-spinner"></span>
              {{ saving ? 'Saving…' : isEdit ? 'Save changes' : 'Create post' }}
            </button>
          </div>

        </form>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { collection, addDoc, doc, updateDoc, getDocs, serverTimestamp } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { flutterColorToCss, iconChar } from '../utils/iconData.js'
import FileUploader from './FileUploader.vue'

const catCssColor = (hex) => flutterColorToCss(hex ?? 0xFF1565C0)
const catIconChar  = (code) => iconChar(code ?? 0xe2cc)

const vClickOutside = {
  mounted(el, binding) {
    el._outside = (e) => { if (!el.contains(e.target)) binding.value(e) }
    document.addEventListener('mousedown', el._outside)
  },
  unmounted(el) { document.removeEventListener('mousedown', el._outside) },
}

const props = defineProps({
  post: { type: Object, default: null },
})
const emit = defineEmits(['close', 'saved'])

const isEdit = computed(() => !!props.post)

const categories        = ref([])
const categoriesLoading = ref(true)
const catOpen           = ref(false)

const selectedCategory = computed(() =>
  categories.value.find(c => c.id === form.category_id) ?? null
)

function selectCat(cat) {
  form.category_id = cat ? cat.id : ''
  catOpen.value = false
}

onMounted(async () => {
  const snap = await getDocs(collection(db, 'categories'))
  categories.value = snap.docs.map(d => ({
    id: d.id,
    ...d.data(),
    iconCode: d.data().iconCode ?? 0xe2cc,
    colorHex: d.data().colorHex ?? 0xFF1565C0,
  }))
  categoriesLoading.value = false
})

const types = [
  { label: 'Video', value: 'video', icon: '🎬' },
  { label: 'Audio', value: 'audio', icon: '🎵' },
  { label: 'PDF',   value: 'pdf',   icon: '📄' },
]

const form = reactive({
  title: '', subtitle: '', description: '',
  type: 'video', thumbnail: '', file_url: '',
  category_id: '', featured: false, hot: false,
})

watch(() => props.post, (p) => {
  if (p) {
    Object.assign(form, {
      title:       p.title       ?? '',
      subtitle:    p.subtitle    ?? '',
      description: p.description ?? '',
      type:        p.type        ?? 'video',
      thumbnail:   p.thumbnail   ?? '',
      file_url:    p.file_url    ?? '',
      category_id: p.category_id ?? '',
      featured:    p.featured    ?? false,
      hot:         p.hot         ?? false,
    })
  }
}, { immediate: true })

const fileAccept = computed(() => {
  if (form.type === 'video') return 'video/*'
  if (form.type === 'audio') return 'audio/*'
  return 'application/pdf'
})

const fileLabel = computed(() => {
  if (form.type === 'video') return 'Video file'
  if (form.type === 'audio') return 'Audio file'
  return 'PDF file'
})

const fileHint = computed(() => {
  if (form.type === 'video') return 'MP4, MOV, WebM…'
  if (form.type === 'audio') return 'MP3, AAC, OGG…'
  return 'PDF document'
})

const fileStoragePath = computed(() => `posts/${form.type}s`)

const saving    = ref(false)
const saveError = ref(null)

async function save() {
  saving.value    = true
  saveError.value = null

  const payload = {
    title:       form.title.trim(),
    subtitle:    form.subtitle.trim(),
    description: form.description.trim(),
    type:        form.type,
    thumbnail:   form.thumbnail,
    file_url:    form.file_url,
    category_id: form.category_id.trim(),
    featured:    form.featured,
    hot:         form.hot,
  }

  try {
    if (isEdit.value) {
      await updateDoc(doc(db, 'posts', props.post.id), { ...payload, updated_at: serverTimestamp() })
    } else {
      await addDoc(collection(db, 'posts'), { ...payload, created_at: serverTimestamp() })
    }
    emit('saved')
    emit('close')
  } catch (e) {
    saveError.value = e.message
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 12, 24, 0.6);
  backdrop-filter: blur(3px);
  z-index: 1000;
  display: flex;
  justify-content: flex-end;
  animation: fade-in 0.15s ease;
}
@keyframes fade-in { from { opacity: 0 } to { opacity: 1 } }

.drawer {
  width: 100%;
  max-width: 520px;
  height: 100%;
  background: #fff;
  display: flex;
  flex-direction: column;
  box-shadow: -8px 0 40px rgba(0,0,0,0.2);
  animation: slide-in 0.2s ease;
  overflow: hidden;
}
@keyframes slide-in { from { transform: translateX(40px); opacity: 0 } to { transform: translateX(0); opacity: 1 } }

.drawer-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 24px 24px 20px;
  border-bottom: 1px solid #f0f2f8;
  flex-shrink: 0;
}
.drawer-eyebrow { margin: 0 0 2px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.8px; color: #3b4cca; }
.drawer-title { margin: 0; font-size: 18px; font-weight: 700; color: #1a1d2e; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 380px; }

.close-btn {
  flex-shrink: 0; width: 34px; height: 34px; border-radius: 8px;
  border: 1px solid #e8eaf0; background: #f8f9fc; cursor: pointer;
  display: flex; align-items: center; justify-content: center; color: #555; transition: all 0.15s;
}
.close-btn:hover { background: #fee2e2; border-color: #fca5a5; color: #c81e1e; }
.close-btn svg { width: 16px; height: 16px; }

.drawer-body {
  flex: 1; overflow-y: auto; padding: 20px 24px;
  display: flex; flex-direction: column; gap: 18px;
}

.field { display: flex; flex-direction: column; gap: 6px; }

.label { font-size: 13px; font-weight: 600; color: #374151; display: flex; align-items: center; gap: 6px; }
.req { color: #e53e3e; }
.label-hint { font-weight: 400; color: #9ca3af; font-size: 12px; }

.input {
  padding: 9px 12px; border: 1.5px solid #dde0ee; border-radius: 8px;
  font-size: 14px; color: #1a1d2e; background: #fafbff; outline: none;
  transition: border-color 0.15s; font-family: inherit; width: 100%; box-sizing: border-box;
}
.input:focus { border-color: #3b4cca; background: #fff; }
.textarea { resize: vertical; min-height: 72px; }

.type-tabs { display: flex; gap: 8px; }
.type-tab {
  flex: 1; padding: 10px 8px; border: 1.5px solid #dde0ee; border-radius: 10px;
  background: #fafbff; cursor: pointer; font-size: 13px; font-weight: 600; color: #6b7280;
  display: flex; flex-direction: column; align-items: center; gap: 4px; transition: all 0.15s;
}
.type-tab:hover { border-color: #3b4cca; color: #3b4cca; }
.type-tab.active { border-color: #3b4cca; background: #eef0fd; color: #3b4cca; }
.type-tab-icon { font-size: 20px; }

.toggles-row {
  display: flex; flex-direction: column; gap: 14px;
  padding: 16px; background: #f8f9fc; border-radius: 10px; border: 1px solid #e8eaf0;
}
.toggle-label { display: flex; align-items: center; gap: 14px; cursor: pointer; }
.toggle-label span { display: flex; flex-direction: column; }
.toggle-label strong { font-size: 13px; font-weight: 600; color: #1a1d2e; }
.toggle-label em { font-size: 11px; color: #8b8fa8; font-style: normal; }

.toggle-wrap { position: relative; flex-shrink: 0; }
.toggle-input { position: absolute; opacity: 0; width: 0; height: 0; }
.toggle-track { width: 40px; height: 22px; border-radius: 11px; background: #d1d5db; transition: background 0.2s; position: relative; }
.toggle-input:checked ~ .toggle-track { background: #3b4cca; }
.toggle-thumb { position: absolute; top: 3px; left: 3px; width: 16px; height: 16px; border-radius: 50%; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.2); transition: transform 0.2s; }
.toggle-input:checked ~ .toggle-track .toggle-thumb { transform: translateX(18px); }

.drawer-footer { display: flex; gap: 10px; justify-content: flex-end; margin-top: 8px; padding-top: 16px; border-top: 1px solid #f0f2f8; flex-shrink: 0; }

.btn-ghost {
  padding: 9px 18px; border-radius: 8px; border: 1.5px solid #dde0ee;
  background: #fff; color: #555; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.15s;
}
.btn-ghost:hover:not(:disabled) { border-color: #9ca3af; }
.btn-ghost:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-primary {
  padding: 9px 22px; border-radius: 8px; border: none; background: #3b4cca; color: #fff;
  font-size: 14px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: background 0.15s;
}
.btn-primary:hover:not(:disabled) { background: #2d3ba8; }
.btn-primary:disabled { opacity: 0.6; cursor: not-allowed; }

.btn-spinner {
  width: 14px; height: 14px; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff;
  border-radius: 50%; animation: spin 0.6s linear infinite; flex-shrink: 0;
}
@keyframes spin { to { transform: rotate(360deg); } }

.save-error { font-size: 13px; color: #c81e1e; background: #fde8e8; padding: 10px 14px; border-radius: 8px; }

.cat-loading { font-size: 13px; color: #9ca3af; }

.cat-dropdown { position: relative; }

.cat-trigger {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 8px 10px;
  border: 1.5px solid #dde0ee;
  border-radius: 8px;
  background: #fafbff;
  font-size: 14px;
  color: #1a1d2e;
  cursor: pointer;
  text-align: left;
  transition: border-color 0.15s;
}
.cat-trigger:hover, .cat-trigger:focus { border-color: #3b4cca; outline: none; }

.cat-trigger-icon {
  width: 26px; height: 26px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.cat-trigger-icon .mi { font-family: 'Material Icons'; font-style: normal; font-weight: normal; font-size: 14px; color: #fff; line-height: 1; }

.cat-trigger-name { flex: 1; font-weight: 500; }
.cat-trigger-placeholder { flex: 1; color: #9ca3af; }

.cat-chevron {
  width: 16px; height: 16px;
  color: #9ca3af; flex-shrink: 0;
  transition: transform 0.15s;
}
.cat-chevron.open { transform: rotate(180deg); }

.cat-menu {
  position: absolute;
  top: calc(100% + 4px);
  left: 0; right: 0;
  background: #fff;
  border: 1.5px solid #dde0ee;
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
  z-index: 200;
  overflow: hidden;
  max-height: 240px;
  overflow-y: auto;
}

.cat-option {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 12px;
  border: none;
  background: none;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  cursor: pointer;
  text-align: left;
  transition: background 0.1s;
}
.cat-option:hover { background: #f5f6ff; }
.cat-option.active { background: #eef0fd; color: #3b4cca; }

.cat-option-icon {
  width: 26px; height: 26px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.cat-option-icon .mi { font-family: 'Material Icons'; font-style: normal; font-weight: normal; font-size: 14px; color: #fff; line-height: 1; }

.cat-option-icon-none {
  width: 26px; height: 26px;
  border-radius: 50%;
  background: #e5e7eb;
  display: flex; align-items: center; justify-content: center;
  font-size: 13px; color: #9ca3af; flex-shrink: 0;
}

.cat-option-name { flex: 1; }

.cat-check { width: 14px; height: 14px; color: #3b4cca; flex-shrink: 0; }
</style>
