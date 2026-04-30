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
      </div>

      <div class="modal-footer">
        <button class="btn-cancel" @click="$emit('close')">Cancel</button>
        <button class="btn-save" :disabled="!form.name.trim() || saving" @click="save">
          {{ saving ? 'Saving…' : 'Save Category' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue'
import { collection, addDoc, doc, updateDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { MATERIAL_ICONS, COLOR_OPTIONS, flutterColorToCss, iconChar } from '../utils/iconData.js'

const props = defineProps({
  category: { type: Object, default: null },
})
const emit = defineEmits(['close', 'saved'])

const isEdit = computed(() => !!props.category?.id)

const form = reactive({
  name:     props.category?.name     ?? '',
  iconCode: props.category?.iconCode ?? 0xe574,  // default: category icon
  colorHex: props.category?.colorHex ?? 0xFF1565C0, // default: blue
})

const iconSearch = ref('')
const saving     = ref(false)

const filteredIcons = computed(() => {
  const q = iconSearch.value.trim().toLowerCase()
  return q ? MATERIAL_ICONS.filter(i => i.label.toLowerCase().includes(q)) : MATERIAL_ICONS
})

const selectedCssColor = computed(() => flutterColorToCss(form.colorHex))

async function save() {
  if (!form.name.trim()) return
  saving.value = true
  try {
    const payload = {
      name:      form.name.trim(),
      iconCode:  form.iconCode,
      colorHex:  form.colorHex,
      updatedAt: serverTimestamp(),
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
}
.text-input:focus { border-color: #3b4cca; }

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

/* Material Icons font rendering */
.mi {
  font-family: 'Material Icons';
  font-style: normal;
  font-weight: normal;
  line-height: 1;
  display: inline-block;
}
</style>
