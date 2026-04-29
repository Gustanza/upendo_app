<template>
  <div class="uploader" :class="{ dragging, uploading, done: state === 'done', errored: state === 'error' }">

    <!-- Current file indicator (edit mode or after upload) -->
    <div v-if="currentUrl && state === 'idle'" class="current-file">
      <img v-if="isImage" :src="currentUrl" class="current-thumb" alt="" />
      <div v-else class="current-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
      </div>
      <div class="current-info">
        <p class="current-label">{{ label }} already set</p>
        <p class="current-url">{{ shortUrl }}</p>
      </div>
      <button type="button" class="replace-btn" @click="triggerPick">Replace</button>
    </div>

    <!-- Drop zone (no file yet or replace) -->
    <div
      v-else-if="state === 'idle' || state === 'error'"
      class="dropzone"
      @click="triggerPick"
      @dragover.prevent="dragging = true"
      @dragleave.prevent="dragging = false"
      @drop.prevent="onDrop"
    >
      <div class="dz-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><polyline points="16 16 12 12 8 16"/><line x1="12" y1="12" x2="12" y2="21"/><path d="M20.39 18.39A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.3"/></svg>
      </div>
      <p class="dz-main">Drop {{ label }} here or <span class="dz-link">browse</span></p>
      <p class="dz-hint">{{ hint }}</p>
      <p v-if="state === 'error'" class="dz-error">{{ errorMsg }}</p>
    </div>

    <!-- Uploading state -->
    <div v-else-if="state === 'uploading'" class="upload-progress">
      <div class="up-info">
        <span class="up-name">{{ fileName }}</span>
        <span class="up-pct">{{ progress }}%</span>
      </div>
      <div class="progress-track">
        <div class="progress-bar" :style="{ width: progress + '%' }"></div>
      </div>
    </div>

    <!-- Done state -->
    <div v-else-if="state === 'done'" class="upload-done">
      <div v-if="isImage && uploadedUrl" class="done-thumb-wrap">
        <img :src="uploadedUrl" class="done-thumb" alt="" />
      </div>
      <div class="done-info">
        <div class="done-check">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <div>
          <p class="done-name">{{ fileName }}</p>
          <p class="done-label">Uploaded successfully</p>
        </div>
      </div>
      <button type="button" class="replace-btn" @click="reset">Replace</button>
    </div>

    <!-- Hidden input -->
    <input
      ref="fileInput"
      type="file"
      :accept="accept"
      class="hidden-input"
      @change="onFileChange"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { getStorage, ref as storageRef, uploadBytesResumable, getDownloadURL } from 'firebase/storage'

const props = defineProps({
  label:      { type: String, default: 'file' },
  accept:     { type: String, default: '*/*' },
  hint:       { type: String, default: '' },
  storagePath:{ type: String, required: true },
  currentUrl: { type: String, default: '' },
})

const emit = defineEmits(['uploaded'])

const fileInput  = ref(null)
const dragging   = ref(false)
const state      = ref('idle')   // idle | uploading | done | error
const progress   = ref(0)
const fileName   = ref('')
const uploadedUrl = ref('')
const errorMsg   = ref('')

const isImage    = computed(() => props.accept.startsWith('image'))
const uploading  = computed(() => state.value === 'uploading')

const shortUrl = computed(() => {
  const url = props.currentUrl
  if (!url) return ''
  try {
    const u = new URL(url)
    const parts = u.pathname.split('/')
    return decodeURIComponent(parts[parts.length - 1].split('?')[0]).slice(-40)
  } catch {
    return url.slice(-40)
  }
})

function triggerPick() { fileInput.value?.click() }

function onFileChange(e) {
  const file = e.target.files?.[0]
  if (file) upload(file)
  e.target.value = ''
}

function onDrop(e) {
  dragging.value = false
  const file = e.dataTransfer.files?.[0]
  if (file) upload(file)
}

function reset() {
  state.value    = 'idle'
  progress.value = 0
  fileName.value = ''
  uploadedUrl.value = ''
  errorMsg.value = ''
}

async function upload(file) {
  state.value    = 'uploading'
  progress.value = 0
  fileName.value = file.name
  errorMsg.value = ''

  const storage = getStorage()
  const path    = `${props.storagePath}/${Date.now()}_${file.name}`
  const sRef    = storageRef(storage, path)
  const task    = uploadBytesResumable(sRef, file)

  task.on(
    'state_changed',
    (snap) => {
      progress.value = Math.round((snap.bytesTransferred / snap.totalBytes) * 100)
    },
    (err) => {
      state.value  = 'error'
      errorMsg.value = err.message
    },
    async () => {
      const url = await getDownloadURL(task.snapshot.ref)
      uploadedUrl.value = url
      state.value = 'done'
      emit('uploaded', url)
    }
  )
}
</script>

<style scoped>
.uploader { border-radius: 10px; overflow: hidden; }

/* Drop zone */
.dropzone {
  border: 2px dashed #dde0ee;
  border-radius: 10px;
  padding: 24px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  background: #fafbff;
  transition: all 0.15s;
  text-align: center;
}
.uploader.dragging .dropzone { border-color: #3b4cca; background: #eef0fd; }
.dropzone:hover { border-color: #3b4cca; background: #eef0fd; }

.dz-icon svg { width: 28px; height: 28px; color: #9ca3af; }
.dz-main { margin: 0; font-size: 13px; font-weight: 500; color: #4b5563; }
.dz-link { color: #3b4cca; font-weight: 600; }
.dz-hint { margin: 0; font-size: 11px; color: #9ca3af; }
.dz-error { margin: 4px 0 0; font-size: 12px; color: #c81e1e; }

/* Current file */
.current-file {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  border: 1.5px solid #e8eaf0;
  border-radius: 10px;
  background: #f8f9fc;
}
.current-thumb {
  width: 56px;
  height: 40px;
  object-fit: cover;
  border-radius: 6px;
  flex-shrink: 0;
}
.current-icon {
  width: 40px;
  height: 40px;
  background: #eef0fd;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.current-icon svg { width: 20px; height: 20px; color: #3b4cca; }
.current-info { flex: 1; min-width: 0; }
.current-label { margin: 0; font-size: 12px; font-weight: 600; color: #374151; }
.current-url { margin: 2px 0 0; font-size: 11px; color: #9ca3af; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

/* Progress */
.upload-progress {
  padding: 14px;
  border: 1.5px solid #e8eaf0;
  border-radius: 10px;
  background: #f8f9fc;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.up-info { display: flex; justify-content: space-between; align-items: center; }
.up-name { font-size: 12px; font-weight: 600; color: #374151; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 80%; }
.up-pct { font-size: 12px; font-weight: 700; color: #3b4cca; flex-shrink: 0; }

.progress-track { height: 5px; background: #dde0ee; border-radius: 99px; overflow: hidden; }
.progress-bar { height: 100%; background: #3b4cca; border-radius: 99px; transition: width 0.2s; }

/* Done */
.upload-done {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  border: 1.5px solid #bbf7d0;
  border-radius: 10px;
  background: #f0fdf4;
}
.done-thumb-wrap { flex-shrink: 0; }
.done-thumb { width: 56px; height: 40px; object-fit: cover; border-radius: 6px; display: block; }
.done-info { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
.done-check {
  width: 28px; height: 28px; border-radius: 50%;
  background: #22c55e; display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.done-check svg { width: 14px; height: 14px; color: #fff; }
.done-name { margin: 0; font-size: 12px; font-weight: 600; color: #15803d; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 220px; }
.done-label { margin: 2px 0 0; font-size: 11px; color: #4ade80; }

/* Replace btn */
.replace-btn {
  margin-left: auto;
  flex-shrink: 0;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid #dde0ee;
  background: #fff;
  font-size: 11px;
  font-weight: 600;
  color: #555;
  cursor: pointer;
  transition: all 0.15s;
}
.replace-btn:hover { border-color: #3b4cca; color: #3b4cca; }

.hidden-input { display: none; }
</style>
