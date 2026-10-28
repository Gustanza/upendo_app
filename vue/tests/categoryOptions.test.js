// Post form category picker — run with: npm test
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { categoryOptions, filterCategoryOptions } from '../src/utils/categoryOptions.js'

const cats = [
  { id: 's2', name: 'Utangulizi', parentId: 'm2' },
  { id: 'm1', name: 'Familia' },
  { id: 's1', name: 'Utangulizi', parentId: 'm1' },
  { id: 'm2', name: 'Afya' },
  { id: 's3', name: 'Malezi', parentId: 'm1' },
  { id: 'orphan', name: 'Yatima', parentId: 'gone' },
]

test('each main category is followed by its subcategories, which are selectable and labelled', () => {
  const opts = categoryOptions(cats)
  assert.deepEqual(opts.map((o) => o.id), ['m2', 's2', 'm1', 's3', 's1', 'orphan'])
  const s1 = opts.find((o) => o.id === 's1')
  assert.equal(s1.depth, 1)
  assert.equal(s1.label, 'Familia › Utangulizi')
  assert.equal(opts.find((o) => o.id === 'm1').subCount, 2)
  assert.equal(opts.find((o) => o.id === 'orphan').depth, 0)
})

test('duplicate subcategory names are distinguishable; searching a main lists its subs', () => {
  const opts = categoryOptions(cats)
  assert.deepEqual(filterCategoryOptions(opts, 'utangulizi').map((o) => o.label), ['Afya › Utangulizi', 'Familia › Utangulizi'])
  assert.deepEqual(filterCategoryOptions(opts, 'familia').map((o) => o.id), ['m1', 's3', 's1'])
  assert.equal(filterCategoryOptions(opts, '  ').length, opts.length)
})
