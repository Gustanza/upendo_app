// Admin bootstrap gate + banner — run with: npm test
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createAdminGate, bootstrapWarning } from '../src/utils/adminGate.js'

const deferred = () => {
  let resolve, reject
  const promise = new Promise((res, rej) => { resolve = res; reject = rej })
  return { promise, resolve, reject }
}
const user = { uid: 'u1', email: 'moyoapptanzania@gmail.com' }

test('admin-only writes awaiting ready() wait for the in-flight ensureAdmin (no race)', async () => {
  const d = deferred()
  let calls = 0
  const gate = createAdminGate({ call: () => { calls++; return d.promise } })
  gate.ensure(user) // the router fires this without awaiting
  const order = []
  const write = (async () => { await gate.ready(); order.push('write') })()
  await new Promise((r) => setTimeout(r, 5))
  assert.deepEqual(order, [], 'the write must not run before ensureAdmin finishes')
  order.push('ensureAdmin done')
  d.resolve({ admin: true, created: true })
  await write
  assert.deepEqual(order, ['ensureAdmin done', 'write'])
  assert.equal(calls, 1, 'one call per uid, shared by ensure() and ready()')
})

test('ready() without a prior ensure() starts one for the current user', async () => {
  let calls = 0
  const gate = createAdminGate({ call: async () => { calls++; return { admin: true } }, currentUser: () => user })
  assert.deepEqual(await gate.ready(), { admin: true })
  assert.equal(calls, 1)
  assert.equal(await createAdminGate({ call: async () => ({}) }).ready(), null, 'signed out → nothing to wait for')
})

test('a failing call never rejects ready(), reports the error, and is retried next time', async () => {
  const statuses = []
  let n = 0
  const gate = createAdminGate({
    call: async () => { if (n++ === 0) throw Object.assign(new Error('boom'), { code: 'functions/internal' }); return { admin: true } },
    onStatus: (s) => statuses.push(s),
    describe: (e) => `failed: ${e.message}`,
    currentUser: () => user,
  })
  assert.deepEqual(await gate.ensure(user), { error: 'failed: boom' })
  assert.deepEqual(await gate.ready(), { admin: true })
  assert.deepEqual(statuses, [{ error: 'failed: boom' }, { admin: true }])
})

test('banner: shown when the server does not register the account as admin', () => {
  assert.equal(bootstrapWarning(null), null)
  assert.equal(bootstrapWarning({ admin: true, created: false }), null)
  const msg = bootstrapWarning({ admin: false, created: false })
  assert.match(msg, /not registered on the server/)
  assert.match(msg, /ADMIN_EMAILS/)
  assert.equal(bootstrapWarning({ error: 'Registering your admin access failed: x' }), 'Registering your admin access failed: x')
})
