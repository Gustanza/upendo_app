<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal">
      <div class="modal-header">
        <h2>{{ isEdit ? 'Edit Category' : 'New Category' }}</h2>
        <button class="close-btn" @click="$emit('close')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>

      <div class="modal-body">
        <!-- Name -->
        <div class="field">
          <label>Name</label>
          <input v-model="form.name" type="text" placeholder="e.g. Health & Wellness" class="text-input" />
        </div>

        <!-- Icon preview -->
        <div class="field">
          <label>Icon</label>
          <div class="icon-search-row">
            <input v-model="iconSearch" type="text" placeholder="Search icons…" class="text-input search-input" />
            <div class="selected-preview" :style="{ background: selectedCssColor }">
              <span class="mi">{{ iconChar(form.iconCode) }}</span>
            </div>
          </div>

          <div class="icon-grid">
            <button
              v-for="icon in filteredIcons"
              :key="icon.code"
              class="icon-tile"
              :class="{ selected: form.iconCode === icon.code }"
              :title="icon.label"
              type="button"
              @click="form.iconCode = icon.code"
            >
              <span class="mi">{{ iconChar(icon.code) }}</span>
              <span class="icon-label">{{ icon.label }}</span>
            </button>
          </div>
        </div>

        <!-- Color -->
        <div class="field">
          <label>Color</label>
          <div class="color-grid">
            <button
              v-for="color in COLOR_OPTIONS"
              :key="color.value"
              class="color-swatch"
              :class="{ selected: form.colorHex === color.value }"
              :style="{ background: flutterColorToCss(color.value) }"
              :title="color.label"
              type="button"
              @click="form.colorHex = color.value"
            />
          </div>
        </div>

        <!-- Password Protection -->
        <div class="field">
          <label class="toggle-row">
            <span>Protect with password</span>
            <button
              type="button"
              class="toggle-track"
              :class="{ active: form.isProtected }"
              @click="form.isProtected = !form.isProtected"
              role="switch"
              :aria-checked="form.isProtected"
            >
              <span class="toggle-thumb" />
            </button>
          </label>
        </div>

        <div class="field">
          <label>Password</label>
          <p v-if="isEdit && wasProtected" class="field-hint">
            Leave blank to keep the current password.
          </p>
          <div class="password-row">
            <input
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="Enter password"
              class="text-input"
            />
            <button type="button" class="eye-btn" @click="showPassword = !showPassword">
              <svg v-if="showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                <line x1="1" y1="1" x2="23" y2="23"/>
              </svg>
              <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
            </button>
          </div>
        </div>

        <div v-if="form.password" class="field">
          <label>Confirm Password</label>
          <input
            v-model="form.confirmPassword"
            :type="showPassword ? 'text' : 'password'"
            placeholder="Confirm password"
            class="text-input"
            :class="{ 'input-error': form.confirmPassword && form.password !== form.confirmPassword }"
          />
          <span v-if="form.confirmPassword && form.password !== form.confirmPassword" class="field-error">
            Passwords don't match
          </span>
        </div>
      </div>

      <div class="modal-footer">
        <button class="btn-cancel" @click="$emit('close')">Cancel</button>
        <button class="btn-save" :disabled="!canSave" @click="save">
          {{ saving ? 'Saving…' : 'Save Category' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue'
import { collection, addDoc, doc, updateDoc, serverTimestamp, deleteField } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { MATERIAL_ICONS, COLOR_OPTIONS, flutterColorToCss, iconChar } from '../utils/iconData.js'

const props = defineProps({
  category: { type: Object, default: null },
})
const emit = defineEmits(['close', 'saved'])

const isEdit     = computed(() => !!props.category?.id)
const wasProtected = computed(() => !!props.category?.isProtected)

const form = reactive({
  name:            props.category?.name      ?? '',
  iconCode:        props.category?.iconCode  ?? 0xe574,
  colorHex:        props.category?.colorHex  ?? 0xFF1565C0,
  isProtected:     props.category?.isProtected ?? false,
  password:        '',
  confirmPassword: '',
})

const iconSearch  = ref('')
const saving      = ref(false)
const showPassword = ref(false)

const filteredIcons = computed(() => {
  const q = iconSearch.value.trim().toLowerCase()
  return q ? MATERIAL_ICONS.filter(i => i.label.toLowerCase().includes(q)) : MATERIAL_ICONS
})

const selectedCssColor = computed(() => flutterColorToCss(form.colorHex))

// Password is required when turning on protection for the first time (new or previously unprotected)
const passwordRequired = computed(() =>
  form.isProtected && (!isEdit.value || !wasProtected.value)
)

const canSave = computed(() => {
  if (!form.name.trim() || saving.value) return false
  if (passwordRequired.value && !form.password) return false
  if (form.password && form.password !== form.confirmPassword) return false
  return true
})

async function sha256(message) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(message))
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('')
}

async function save() {
  saving.value = true
  try {
    const payload = {
      name:      form.name.trim(),
      iconCode:  form.iconCode,
      colorHex:  form.colorHex,
      isProtected: form.isProtected,
      updatedAt: serverTimestamp(),
    }

    if (form.isProtected && form.password) {
      payload.passwordHash = await sha256(form.password)
    } else if (!form.isProtected && isEdit.value) {
      payload.passwordHash = deleteField()
    }

    if (isEdit.value) {
      await updateDoc(doc(db, 'categories', props.category.id), payload)
    } else {
      payload.createdAt = serverTimestamp()
      await addDoc(collection(db, 'categories'), payload)
    }
    emit('saved')
    emit('close')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #fff;
  border-radius: 14px;
  width: 560px;
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
  gap: 20px;
}

.field { display: flex; flex-direction: column; gap: 8px; }
.field > label { font-size: 13px; font-weight: 600; color: #374151; }

.text-input {
  border: 1.5px solid #e5e7eb;
  border-radius: 8px;
  padding: 9px 12px;
  font-size: 14px;
  outline: none;
  transition: border-color .15s;
  color: #1a1d2e;
  width: 100%;
  box-sizing: border-box;
}
.text-input:focus { border-color: #3b4cca; }
.input-error { border-color: #dc2626 !important; }

.field-hint {
  margin: 0;
  font-size: 12px;
  color: #6b7280;
}

.field-error {
  font-size: 12px;
  color: #dc2626;
}

/* Toggle */
.toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  cursor: default;
}

.toggle-track {
  position: relative;
  width: 44px;
  height: 24px;
  border-radius: 12px;
  border: none;
  background: #d1d5db;
  cursor: pointer;
  transition: background .2s;
  flex-shrink: 0;
  padding: 0;
}
.toggle-track.active { background: #3b4cca; }

.toggle-thumb {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #fff;
  transition: transform .2s;
  display: block;
  box-shadow: 0 1px 3px rgba(0,0,0,.2);
}
.toggle-track.active .toggle-thumb { transform: translateX(20px); }

/* Password row */
.password-row {
  display: flex;
  gap: 8px;
  align-items: center;
}
.password-row .text-input { flex: 1; }

.eye-btn {
  width: 38px;
  height: 38px;
  border: 1.5px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #6b7280;
  transition: all .12s;
}
.eye-btn:hover { background: #f3f4f6; border-color: #d1d5db; }
.eye-btn svg { width: 16px; height: 16px; }

.icon-search-row {
  display: flex;
  gap: 10px;
  align-items: center;
}
.search-input { flex: 1; }

.selected-preview {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: background .2s;
}
.selected-preview .mi { color: #fff; font-size: 22px; }

.icon-grid {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 6px;
  max-height: 220px;
  overflow-y: auto;
  padding: 4px 2px;
}

.icon-tile {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  padding: 8px 4px;
  border: 1.5px solid #e5e7eb;
  border-radius: 10px;
  background: #fafafa;
  cursor: pointer;
  transition: all .12s;
}
.icon-tile:hover { background: #eef0fb; border-color: #3b4cca; }
.icon-tile.selected { background: #eef0fb; border-color: #3b4cca; border-width: 2px; }

.icon-tile .mi { font-size: 22px; color: #374151; }
.icon-label { font-size: 9px; color: #6b7280; text-align: center; line-height: 1.2; }

.color-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.color-swatch {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  border: 3px solid transparent;
  cursor: pointer;
  transition: transform .12s, border-color .12s;
  outline: 2px solid transparent;
}
.color-swatch:hover { transform: scale(1.12); }
.color-swatch.selected {
  border-color: #fff;
  outline-color: #3b4cca;
  transform: scale(1.1);
}

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

.btn-save {
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
.btn-save:hover:not(:disabled) { background: #2f3da0; }
.btn-save:disabled { opacity: .5; cursor: not-allowed; }

.mi {
  font-family: 'Material Icons';
  font-style: normal;
  font-weight: normal;
  line-height: 1;
  display: inline-block;
}
</style>
