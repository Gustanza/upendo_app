<template>
  <div class="dashboard">
    <aside class="sidebar">
      <div class="sidebar-brand">
        <span class="brand-icon">🌸</span>
        <span class="brand-name">Upendo Admin</span>
      </div>

      <nav class="sidebar-nav">
        <RouterLink to="/" class="nav-item" exact-active-class="active">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>
          Overview
        </RouterLink>

        <RouterLink to="/posts" class="nav-item" active-class="active">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          Posts
        </RouterLink>

        <RouterLink to="/categories" class="nav-item" active-class="active">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3h7v7H3z"/><path d="M14 3h7v7h-7z"/><path d="M3 14h7v7H3z"/><path d="M17.5 14l-3.5 6.06L21 20l-3.5-6z"/></svg>
          Categories
        </RouterLink>

        <RouterLink to="/users" class="nav-item" active-class="active">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          Users
        </RouterLink>
      </nav>
    </aside>

    <div class="main-wrap">
      <header class="topbar">
        <h1 class="page-title">{{ pageTitle }}</h1>
        <div class="topbar-right">
          <div class="user-chip">
            <div class="user-avatar">{{ userInitial }}</div>
            <span class="user-email">{{ user?.email }}</span>
          </div>
          <button class="logout-btn" @click="handleLogout" title="Sign out">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          </button>
        </div>
      </header>
      <main class="main-content">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth.js'

const route  = useRoute()
const router = useRouter()
const { user, logout } = useAuth()

const pageTitle = computed(() => {
  if (route.path === '/posts') return 'Posts'
  if (route.path === '/categories') return 'Categories'
  if (route.path === '/users') return 'Users'
  return 'Overview'
})

const userInitial = computed(() => user.value?.email?.[0]?.toUpperCase() ?? '?')

async function handleLogout() {
  await logout()
  router.push('/login')
}
</script>

<style scoped>
.dashboard {
  display: flex;
  min-height: 100vh;
  background: #f4f6fb;
  font-family: 'Segoe UI', system-ui, sans-serif;
}

/* ── Sidebar ── */
.sidebar {
  width: 240px;
  min-height: 100vh;
  background: #1a1d2e;
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  z-index: 100;
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 22px 20px;
  border-bottom: 1px solid #2a2d40;
}

.brand-icon { font-size: 22px; }

.brand-name {
  font-size: 16px;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.3px;
}

.sidebar-nav {
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 8px;
  color: #8b8fa8;
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.15s;
}

.nav-item:hover { background: #2a2d40; color: #d0d3e8; }
.nav-item.active { background: #3b4cca; color: #fff; }

.nav-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

/* ── Main ── */
.main-wrap {
  margin-left: 240px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.topbar {
  height: 60px;
  background: #fff;
  border-bottom: 1px solid #e8eaf0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 28px;
  position: sticky;
  top: 0;
  z-index: 50;
}

.page-title {
  font-size: 17px;
  font-weight: 600;
  color: #1a1d2e;
  margin: 0;
}

.topbar-right { display: flex; align-items: center; gap: 12px; }

.user-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 10px 4px 4px;
  border-radius: 20px;
  background: #f4f6fb;
  border: 1px solid #e8eaf0;
}
.user-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #3b4cca;
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.user-email {
  font-size: 12px;
  color: #374151;
  font-weight: 500;
  max-width: 180px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.logout-btn {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid #e8eaf0;
  background: #f8f9fc;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
  transition: all 0.15s;
}
.logout-btn:hover { background: #fee2e2; border-color: #fca5a5; color: #c81e1e; }
.logout-btn svg { width: 16px; height: 16px; }

.main-content { padding: 28px; flex: 1; }
</style>
