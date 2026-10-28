// Pure helpers used by CategoryGroupsView — run with: npm test
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { nextGroupOrder, normalizeOrder, groupMembershipChanges, chunk } from '../src/utils/categoryGroups.js'
import { describeFirebaseError, errorCode } from '../src/utils/firebaseErrors.js'

test('new group position defaults to the end of the list', () => {
  assert.equal(nextGroupOrder([]), 1)
  assert.equal(nextGroupOrder([{ order: 0 }, { order: 4 }, { order: 2 }]), 5)
  assert.equal(nextGroupOrder([{ order: undefined }, { name: 'x' }]), 1)
})

test('position input: blank/NaN falls back, decimals truncated', () => {
  assert.equal(normalizeOrder('', 7), 7)
  assert.equal(normalizeOrder(Number.NaN, 7), 7)
  assert.equal(normalizeOrder(3, 7), 3)
  assert.equal(normalizeOrder(0, 7), 0)
  assert.equal(normalizeOrder(2.9, 7), 2)
})

test('membership changes: tick assigns, untick clears, unchanged skipped', () => {
  const mains = [{ id: 'a' }, { id: 'b', groupId: 'g' }, { id: 'c', groupId: 'other' }, { id: 'd', groupId: 'g' }]
  assert.deepEqual(groupMembershipChanges(mains, 'g', new Set(['a', 'c', 'd'])), [['a', 'set'], ['b', 'clear'], ['c', 'set']])
})

test('batches never exceed 500 writes', () => {
  const parts = chunk(Array.from({ length: 1001 }, (_, i) => i), 450)
  assert.deepEqual(parts.map((p) => p.length), [450, 450, 101])
})

test('the real Firebase error is shown, with an explanation for permission-denied', () => {
  const e = Object.assign(new Error('Missing or insufficient permissions.'), { code: 'permission-denied' })
  const msg = describeFirebaseError(e, 'Saving the group')
  assert.match(msg, /^Saving the group failed: /)
  assert.match(msg, /admins\/<your email>/)
  assert.match(msg, /\[permission-denied\] Missing or insufficient permissions\./)
  assert.equal(errorCode({ code: 'functions/permission-denied' }), 'permission-denied')
  assert.equal(describeFirebaseError(new Error('boom')), 'Saving failed: boom')
})
