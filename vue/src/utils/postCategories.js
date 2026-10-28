// How admin posts relate to the (flat, parentId-linked) categories
// collection. Pure — unit-tested in vue/tests/postCategories.test.js.
//
// Why this exists: the app shows an admin post only inside the category its
// `category_id` points at. When categories were reorganised, categories that
// still had posts were deleted, leaving every post pointing at an id that no
// longer exists — so all Topics tabs were empty and nothing in the dashboard
// said so.
import { categoryOptions } from './categoryOptions.js'
import { chunk } from './categoryGroups.js'

export function categoryIdSet(categories) {
  return new Set((categories || []).map((c) => c.id))
}

// A post is "orphaned" when its category_id is empty or names a category
// that doesn't exist. The app never shows such a post.
export function isOrphanPost(post, ids) {
  const id = typeof post?.category_id === 'string' ? post.category_id.trim() : ''
  return !id || !ids.has(id)
}

export function orphanPosts(posts, categories) {
  const ids = categoryIdSet(categories)
  return (posts || []).filter((p) => isOrphanPost(p, ids))
}

// Per-category post counts. `direct` = posts whose category_id is that
// category; `total` additionally includes, for a main category, the posts of
// its subcategories. Orphans are counted separately.
export function postCounts(posts, categories) {
  const ids = categoryIdSet(categories)
  const parentOf = new Map((categories || []).filter((c) => c.parentId && ids.has(c.parentId)).map((c) => [c.id, c.parentId]))
  const direct = new Map()
  const total = new Map()
  let orphanCount = 0
  for (const p of posts || []) {
    if (isOrphanPost(p, ids)) { orphanCount++; continue }
    const id = p.category_id.trim()
    direct.set(id, (direct.get(id) || 0) + 1)
    total.set(id, (total.get(id) || 0) + 1)
    const parent = parentOf.get(id)
    if (parent) total.set(parent, (total.get(parent) || 0) + 1)
  }
  return { direct, total, orphanCount }
}

// Dashboard list: the categories with the most posts ("Main › Sub" labels),
// main categories counted with their subcategories.
export function topCategoriesByPosts(posts, categories, n = 6) {
  const { direct, total } = postCounts(posts, categories)
  return categoryOptions(categories)
    .map((o) => ({ ...o, direct: direct.get(o.id) || 0, total: total.get(o.id) || 0 }))
    .filter((o) => o.total > 0)
    .sort((a, b) => b.total - a.total || a.label.localeCompare(b.label))
    .slice(0, n)
}

// What deleting a category would strand: its subcategories, its own posts
// and its subcategories' posts.
export function deleteImpact(categoryId, categories, posts) {
  const subcategories = (categories || []).filter((c) => c.parentId === categoryId && c.id !== categoryId)
  const subIds = new Set(subcategories.map((c) => c.id))
  const ownPosts = (posts || []).filter((p) => p.category_id === categoryId)
  const subPosts = (posts || []).filter((p) => subIds.has(p.category_id))
  return {
    subcategories,
    ownPosts,
    subPosts,
    postCount: ownPosts.length + subPosts.length,
    safe: subcategories.length === 0 && ownPosts.length === 0 && subPosts.length === 0,
  }
}

// Human summary for the delete dialog, or null when deleting is harmless.
export function deleteBlockMessage(name, impact) {
  if (impact.safe) return null
  const parts = []
  if (impact.subcategories.length) {
    parts.push(`${impact.subcategories.length} subcategor${impact.subcategories.length === 1 ? 'y' : 'ies'}`)
  }
  if (impact.postCount) parts.push(`${impact.postCount} post${impact.postCount === 1 ? '' : 's'}`)
  return `"${name}" still has ${parts.join(' and ')}. ` +
    (impact.postCount
      ? `If you delete it, ${impact.postCount === 1 ? 'that post' : `those ${impact.postCount} posts`} will be hidden in the app (no category to show ${impact.postCount === 1 ? 'it' : 'them'} in). Move ${impact.postCount === 1 ? 'it' : 'them'} to another category first.`
      : 'Delete or reassign the subcategories first.')
}

// Moves posts to `targetId` in Firestore batches of ≤ size writes.
// commitChunk(ids) performs one batch; onProgress({ done, total }) after each.
// Stops at the first failing batch and reports how many were moved.
export async function reassignPosts({ postIds, targetId, validIds, commitChunk, onProgress = () => {}, size = 450 }) {
  if (!targetId) throw new Error('Pick a category to move the posts to.')
  if (validIds && !validIds.has(targetId)) throw new Error('That category no longer exists.')
  const ids = [...new Set(postIds || [])]
  let done = 0
  onProgress({ done, total: ids.length })
  for (const part of chunk(ids, size)) {
    try {
      await commitChunk(part)
    } catch (error) {
      return { done, total: ids.length, error }
    }
    done += part.length
    onProgress({ done, total: ids.length })
  }
  return { done, total: ids.length, error: null }
}
