// Orphaned posts, counts, bulk reassign and the category delete guard — npm test
import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  isOrphanPost, orphanPosts, postCounts, topCategoriesByPosts,
  deleteImpact, deleteBlockMessage, reassignPosts, categoryIdSet,
} from '../src/utils/postCategories.js'

const categories = [
  { id: 'm1', name: 'Familia' },
  { id: 's1', name: 'Malezi', parentId: 'm1' },
  { id: 's2', name: 'Ndoa', parentId: 'm1' },
  { id: 'm2', name: 'Usalama' },
]
// Mirrors production: every post pointed at a deleted category id.
const prodLike = [
  ...Array.from({ length: 18 }, (_, i) => ({ id: `a${i}`, category_id: 'VVU82d7153BPnHiNqXbB' })),
  ...Array.from({ length: 32 }, (_, i) => ({ id: `b${i}`, category_id: '8QyyR00YLASdvPC1jbYQ' })),
]

test('posts pointing at deleted, empty or missing categories are orphans', () => {
  const ids = categoryIdSet(categories)
  assert.equal(isOrphanPost({ category_id: 's1' }, ids), false)
  assert.equal(isOrphanPost({ category_id: ' s1 ' }, ids), false)
  for (const p of [{ category_id: 'gone' }, { category_id: '' }, {}, { category_id: 42 }]) {
    assert.equal(isOrphanPost(p, ids), true, JSON.stringify(p))
  }
  assert.equal(orphanPosts(prodLike, categories).length, 50)
})

test('counts: direct per category, main totals include subcategories, orphans separate', () => {
  const posts = [{ category_id: 's1' }, { category_id: 's1' }, { category_id: 's2' }, { category_id: 'm1' }, { category_id: 'gone' }]
  const { direct, total, orphanCount } = postCounts(posts, categories)
  assert.equal(direct.get('s1'), 2)
  assert.equal(direct.get('m1'), 1)
  assert.equal(total.get('m1'), 4)
  assert.equal(orphanCount, 1)
  const top = topCategoriesByPosts(posts, categories)
  assert.deepEqual(top.map((t) => [t.label, t.total]), [['Familia', 4], ['Familia › Malezi', 2], ['Familia › Ndoa', 1]])
  assert.deepEqual(topCategoriesByPosts(prodLike, categories), [])
  assert.equal(postCounts(prodLike, categories).orphanCount, 50)
})

test('bulk reassign: batches of ≤450, progress reported, de-duplicated', async () => {
  const ids = Array.from({ length: 1000 }, (_, i) => `p${i}`)
  const batches = []
  const progress = []
  const res = await reassignPosts({
    postIds: [...ids, 'p0'], targetId: 's1', validIds: categoryIdSet(categories),
    commitChunk: async (part) => { batches.push(part.length) },
    onProgress: (p) => progress.push(p.done),
  })
  assert.deepEqual(batches, [450, 450, 100])
  assert.deepEqual(progress, [0, 450, 900, 1000])
  assert.deepEqual(res, { done: 1000, total: 1000, error: null })
})

test('bulk reassign: stops at the first failing batch and says how many moved', async () => {
  let n = 0
  const err = Object.assign(new Error('Missing or insufficient permissions.'), { code: 'permission-denied' })
  const res = await reassignPosts({
    postIds: Array.from({ length: 900 }, (_, i) => `p${i}`), targetId: 's1',
    commitChunk: async () => { if (n++ === 1) throw err },
  })
  assert.equal(res.done, 450)
  assert.equal(res.error, err)
  await assert.rejects(reassignPosts({ postIds: ['p'], targetId: '', commitChunk: async () => {} }), /Pick a category/)
  await assert.rejects(reassignPosts({ postIds: ['p'], targetId: 'gone', validIds: categoryIdSet(categories), commitChunk: async () => {} }), /no longer exists/)
})

test('delete guard: blocks a category with posts or subcategories, allows an empty one', () => {
  const posts = [{ id: '1', category_id: 's1' }, { id: '2', category_id: 'm1' }, { id: '3', category_id: 'm2' }]
  const main = deleteImpact('m1', categories, posts)
  assert.equal(main.subcategories.length, 2)
  assert.equal(main.postCount, 2)
  assert.equal(main.safe, false)
  assert.match(deleteBlockMessage('Familia', main), /2 subcategories and 2 posts/)
  assert.match(deleteBlockMessage('Familia', main), /hidden in the app/)

  const leaf = deleteImpact('m2', categories, posts)
  assert.equal(leaf.postCount, 1)
  assert.match(deleteBlockMessage('Usalama', leaf), /that post will be hidden/)

  const empty = deleteImpact('s2', categories, posts)
  assert.equal(empty.safe, true)
  assert.equal(deleteBlockMessage('Ndoa', empty), null)
})
