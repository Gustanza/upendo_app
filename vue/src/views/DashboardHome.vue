<template>
  <div class="overview">

    <!-- Stat cards -->
    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background:#eef0fb">
          <svg viewBox="0 0 24 24" fill="none" stroke="#3b4cca" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
        </div>
        <div>
          <div class="stat-value">{{ posts.length }}</div>
          <div class="stat-label">Total Posts</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon" style="background:#f0fdf4">
          <svg viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
        </div>
        <div>
          <div class="stat-value">{{ categories.length }}</div>
          <div class="stat-label">Categories</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon" style="background:#fdf4ff">
          <svg viewBox="0 0 24 24" fill="none" stroke="#9333ea" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <div>
          <div class="stat-value">{{ users.length }}</div>
          <div class="stat-label">Users</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon" style="background:#fff7ed">
          <svg viewBox="0 0 24 24" fill="none" stroke="#ea580c" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
        </div>
        <div>
          <div class="stat-value">{{ featuredCount }}</div>
          <div class="stat-label">Featured Posts</div>
        </div>
      </div>
    </div>

    <!-- Second row -->
    <div class="two-col">

      <!-- Post types breakdown -->
      <div class="card">
        <div class="card-header">
          <h3>Posts by Type</h3>
        </div>
        <div class="type-list">
          <div v-for="t in postTypes" :key="t.label" class="type-row">
            <div class="type-info">
              <span class="type-dot" :style="{ background: t.color }"></span>
              <span class="type-label">{{ t.label }}</span>
            </div>
            <div class="type-bar-wrap">
              <div
                class="type-bar"
                :style="{ width: posts.length ? (t.count / posts.length * 100) + '%' : '0%', background: t.color }"
              ></div>
            </div>
            <span class="type-count">{{ t.count }}</span>
          </div>
          <div v-if="!posts.length" class="empty-hint">No posts yet.</div>
        </div>
      </div>

      <!-- Categories overview -->
      <div class="card">
        <div class="card-header">
          <h3>Categories</h3>
          <router-link to="/categories" class="see-all">Manage →</router-link>
        </div>
        <div class="cat-list">
          <div v-for="cat in categories.slice(0, 6)" :key="cat.id" class="cat-row">
            <div class="cat-badge" :style="{ background: cssColor(cat.colorHex) }">
              <span class="mi">{{ iconChar(cat.iconCode) }}</span>
            </div>
            <span class="cat-name">{{ cat.name }}</span>
            <span v-if="cat.isProtected" class="lock-chip">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="10" height="10"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
              Protected
            </span>
            <span class="post-count">{{ postCountFor(cat.id) }} posts</span>
          </div>
          <div v-if="!categories.length" class="empty-hint">No categories yet.</div>
        </div>
      </div>
    </div>

    <!-- Recent posts -->
    <div class="card">
      <div class="card-header">
        <h3>Recent Posts</h3>
        <router-link to="/posts" class="see-all">See all →</router-link>
      </div>
      <table class="recent-table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Type</th>
            <th>Category</th>
            <th>Featured</th>
            <th>Hot</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="post in recentPosts" :key="post.id">
            <td>
              <div class="post-title-cell">
                <img v-if="post.thumbnail" :src="post.thumbnail" class="thumb" alt="" />
                <div v-else class="thumb-placeholder"></div>
                <span class="post-title">{{ post.title }}</span>
              </div>
            </td>
            <td><span class="type-pill" :style="{ background: typeColor(post.type) + '22', color: typeColor(post.type) }">{{ post.type }}</span></td>
            <td class="muted">{{ categoryName(post.category_id) }}</td>
            <td>
              <svg v-if="post.featured" viewBox="0 0 24 24" width="16" fill="#f59e0b" stroke="none"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
              <span v-else class="muted">—</span>
            </td>
            <td>
              <svg v-if="post.hot" viewBox="0 0 24 24" width="16" fill="#ef4444" stroke="none"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14H9V8h2v8zm4 0h-2V8h2v8z"/></svg>
              <span v-else class="muted">—</span>
            </td>
          </tr>
          <tr v-if="!recentPosts.length">
            <td colspan="5" class="empty-hint">No posts yet.</td>
          </tr>
        </tbody>
      </table>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot } from 'firebase/firestore'
import { db } from '../fireconfigs.js'
import { flutterColorToCss, iconChar } from '../utils/iconData.js'

const posts      = ref([])
const categories = ref([])
const users      = ref([])

const TYPE_COLORS = {
  video:  '#3b4cca',
  audio:  '#9333ea',
  pdf:    '#ea580c',
  music:  '#16a34a',
  text:   '#0891b2',
}

const featuredCount = computed(() => posts.value.filter(p => p.featured).length)

const postTypes = computed(() => {
  const counts = {}
  for (const p of posts.value) {
    const t = (p.type || 'other').toLowerCase()
    counts[t] = (counts[t] ?? 0) + 1
  }
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([label, count]) => ({ label, count, color: TYPE_COLORS[label] ?? '#6b7280' }))
})

const recentPosts = computed(() =>
  [...posts.value]
    .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0))
    .slice(0, 8)
)

function postCountFor(catId) {
  return posts.value.filter(p => p.category_id === catId).length
}

function categoryName(catId) {
  return categories.value.find(c => c.id === catId)?.name ?? '—'
}

function cssColor(hex) { return flutterColorToCss(hex) }

function typeColor(type) {
  return TYPE_COLORS[(type || '').toLowerCase()] ?? '#6b7280'
}

let unsubs = []

onMounted(() => {
  unsubs.push(
    onSnapshot(collection(db, 'posts'), snap => {
      posts.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    }),
    onSnapshot(collection(db, 'categories'), snap => {
      categories.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    }),
    onSnapshot(collection(db, 'users'), snap => {
      users.value = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    }),
  )
})

onUnmounted(() => unsubs.forEach(u => u()))
</script>

<style scoped>
.overview {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* ── Stat cards ── */
.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.stat-card {
  background: #fff;
  border: 1px solid #e8eaf0;
  border-radius: 12px;
  padding: 18px 20px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 46px;
  height: 46px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.stat-icon svg { width: 22px; height: 22px; }

.stat-value { font-size: 26px; font-weight: 700; color: #1a1d2e; line-height: 1; }
.stat-label { font-size: 12px; color: #6b7280; margin-top: 4px; }

/* ── Two-col row ── */
.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

/* ── Generic card ── */
.card {
  background: #fff;
  border: 1px solid #e8eaf0;
  border-radius: 12px;
  overflow: hidden;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f3f4f6;
}
.card-header h3 { margin: 0; font-size: 14px; font-weight: 700; color: #1a1d2e; }
.see-all { font-size: 12px; color: #3b4cca; text-decoration: none; font-weight: 500; }
.see-all:hover { text-decoration: underline; }

/* ── Post types ── */
.type-list { padding: 12px 20px; display: flex; flex-direction: column; gap: 14px; }

.type-row {
  display: grid;
  grid-template-columns: 100px 1fr 36px;
  align-items: center;
  gap: 12px;
}

.type-info { display: flex; align-items: center; gap: 8px; }
.type-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
.type-label { font-size: 13px; color: #374151; text-transform: capitalize; }

.type-bar-wrap {
  height: 6px;
  background: #f3f4f6;
  border-radius: 99px;
  overflow: hidden;
}
.type-bar { height: 100%; border-radius: 99px; transition: width .4s ease; }
.type-count { font-size: 13px; font-weight: 600; color: #1a1d2e; text-align: right; }

/* ── Categories list ── */
.cat-list { padding: 8px 0; }

.cat-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 20px;
  border-bottom: 1px solid #f9fafb;
}
.cat-row:last-child { border-bottom: none; }

.cat-badge {
  width: 32px;
  height: 32px;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.cat-badge .mi { color: #fff; font-size: 17px; }

.cat-name { font-size: 13px; font-weight: 600; color: #1a1d2e; flex: 1; }

.lock-chip {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 10px;
  font-weight: 600;
  color: #6b7280;
  background: #f3f4f6;
  border-radius: 99px;
  padding: 2px 8px;
}

.post-count { font-size: 12px; color: #9ca3af; white-space: nowrap; }

/* ── Recent posts table ── */
.recent-table {
  width: 100%;
  border-collapse: collapse;
}

.recent-table thead tr { background: #f8f9fc; }
.recent-table th {
  padding: 10px 16px;
  font-size: 11px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: .6px;
  text-align: left;
}
.recent-table td {
  padding: 12px 16px;
  border-top: 1px solid #f3f4f6;
  vertical-align: middle;
}
.recent-table tbody tr:hover { background: #fafbff; }

.post-title-cell { display: flex; align-items: center; gap: 10px; }
.thumb {
  width: 38px;
  height: 38px;
  border-radius: 8px;
  object-fit: cover;
  flex-shrink: 0;
}
.thumb-placeholder {
  width: 38px;
  height: 38px;
  border-radius: 8px;
  background: #f3f4f6;
  flex-shrink: 0;
}
.post-title { font-size: 13px; font-weight: 600; color: #1a1d2e; }

.type-pill {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 99px;
  font-size: 11px;
  font-weight: 600;
  text-transform: capitalize;
}

.muted { font-size: 13px; color: #9ca3af; }

.empty-hint {
  padding: 24px;
  text-align: center;
  color: #9ca3af;
  font-size: 13px;
}

.mi {
  font-family: 'Material Icons';
  font-style: normal;
  font-weight: normal;
  line-height: 1;
  display: inline-block;
}

@media (max-width: 900px) {
  .stat-grid { grid-template-columns: repeat(2, 1fr); }
  .two-col   { grid-template-columns: 1fr; }
}
</style>
