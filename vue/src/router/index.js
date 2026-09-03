import { createRouter, createWebHistory } from 'vue-router'
import { auth } from '../fireconfigs.js'
import DashboardLayout    from '../layouts/DashboardLayout.vue'
import DashboardHome      from '../views/DashboardHome.vue'
import PostsView          from '../views/PostsView.vue'
import CategoriesView     from '../views/CategoriesView.vue'
import UsersView          from '../views/UsersView.vue'
import PackagesView       from '../views/PackagesView.vue'
import NotificationsView  from '../views/NotificationsView.vue'
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

router.beforeEach((to) => {
  if (to.meta.public) return true

  if (!authReady) {
    return new Promise((resolve) => {
      const unsub = auth.onAuthStateChanged((user) => {
        unsub()
        authUser  = user
        authReady = true
        resolve(user ? true : '/login')
      })
    })
  }

  return authUser ? true : '/login'
})

export default router
