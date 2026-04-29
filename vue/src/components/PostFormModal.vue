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
            <label class="label" for="f-cat">Category ID</label>
            <input id="f-cat" v-model="form.category_id" class="input" type="text" placeholder="Firestore category document ID" />
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
import { ref, reactive, computed, watch } from 'vue'
import { collection, addDoc, doc, updateDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import FileUploader from './FileUploader.vue'

const props = defineProps({
  post: { type: Object, default: null },
})
const emit = defineEmits(['close', 'saved'])

const isEdit = computed(() => !!props.post)

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
</style>
