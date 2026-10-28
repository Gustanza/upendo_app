<template>
  <div class="cat-picker">
    <input v-model="search" class="cp-search" type="text" :placeholder="placeholder" />
    <select v-model="model" class="cp-select" :size="size">
      <option v-for="o in filtered" :key="o.id" :value="o.id" :disabled="exclude.includes(o.id)">
        {{ o.depth ? '    ' + o.label : o.label + (o.subCount ? ` (main · ${o.subCount} subcategories)` : '') }}
      </option>
    </select>
    <p v-if="!filtered.length" class="cp-empty">No categories match "{{ search }}"</p>
  </div>
</template>

<script setup>
// Hierarchical "Main › Sub" category chooser (utils/categoryOptions.js),
// used for moving posts (bulk reassign, category delete guard).
import { ref, computed } from 'vue'
import { categoryOptions, filterCategoryOptions } from '../utils/categoryOptions.js'

const props = defineProps({
  categories: { type: Array, required: true },
  exclude: { type: Array, default: () => [] },
  placeholder: { type: String, default: 'Search main categories or subcategories…' },
  size: { type: Number, default: 8 },
})
const model = defineModel({ type: String, default: '' })
const search = ref('')
const options = computed(() => categoryOptions(props.categories))
const filtered = computed(() => filterCategoryOptions(options.value, search.value))
</script>

<style scoped>
.cat-picker { display: flex; flex-direction: column; gap: 6px; min-width: 280px; }
.cp-search, .cp-select {
  width: 100%; padding: 7px 10px; border: 1.5px solid #e5e7eb; border-radius: 8px;
  font-size: 13px; font-family: inherit; background: #fff; box-sizing: border-box;
}
.cp-search:focus, .cp-select:focus { outline: none; border-color: #8b2942; }
.cp-empty { margin: 0; font-size: 12px; color: #9ca3af; }
</style>
