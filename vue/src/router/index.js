import { createRouter, createWebHistory } from 'vue-router'
import { signOut } from 'firebase/auth'
import { auth } from '../fireconfigs.js'
import { isAdmin } from '../utils/adminAccess.js'
import { ensureAdminAccess } from '../utils/adminBootstrap.js'
import DashboardLayout    from '../layouts/DashboardLayout.vue'
import DashboardHome      from '../views/DashboardHome.vue'
import PostsView          from '../views/PostsView.vue'
import CategoriesView     from '../views/CategoriesView.vue'
import UsersView          from '../views/UsersView.vue'
import PackagesView       from '../views/PackagesView.vue'
import NotificationsView  from '../views/NotificationsView.vue'
import CategoryGroupsView from '../views/CategoryGroupsView.vue'
import UserGroupsView     from '../views/UserGroupsView.vue'
import WithdrawalsView    from '../views/WithdrawalsView.vue'
import LoginView          from '../views/LoginView.vue'

const routes = [
  {
    path: '/login',
    component: LoginView,
    meta: { public: true },
  },
  {
    path: '/',
    component: DashboardLayout,
    children: [
      { path: '',           component: DashboardHome },
      { path: 'posts',      component: PostsView },
      { path: 'categories', component: CategoriesView },
      { path: 'users',      component: UsersView },
      { path: 'packages',       component: PackagesView },
      { path: 'notifications',  component: NotificationsView },
      { path: 'category-groups', component: CategoryGroupsView },
      { path: 'user-groups',     component: UserGroupsView },
      { path: 'withdrawals',     component: WithdrawalsView },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Wait for Firebase Auth to resolve before deciding where to send the user
let authReady = false
let authUser  = null

auth.onAuthStateChanged((user) => {
  authUser  = user
  authReady = true
})

// Signed-in non-admins (e.g. regular app users) are signed out and bounced
const guard = (user) => {
  if (!user) return '/login'
  if (!isAdmin(user)) {
    signOut(auth)
    return '/login'
  }
  // Sessions that were already signed in skip LoginView — register the
  // admins/{email} doc for them too (once per session, in the background).
  ensureAdminAccess(user)
  return true
}

router.beforeEach((to) => {
  if (to.meta.public) return true

  if (!authReady) {
    return new Promise((resolve) => {
      const unsub = auth.onAuthStateChanged((user) => {
        unsub()
        authUser  = user
        authReady = true
        resolve(guard(user))
      })
    })
  }

  return guard(authUser)
})

export default router
