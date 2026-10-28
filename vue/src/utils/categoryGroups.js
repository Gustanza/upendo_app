// Pure helpers for the Category Groups page (unit-tested: npm test).

// "Position" of a new group: one after the current last, so it's listed
// at the end on the app's Explore/Home screens. Lower numbers come first.
export function nextGroupOrder(groups) {
  const orders = (groups || []).map((g) => Number(g.order)).filter(Number.isFinite)
  return orders.length ? Math.max(...orders) + 1 : 1
}

export function normalizeOrder(value, fallback = 0) {
  const n = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(n) && String(value).trim() !== '' ? Math.trunc(n) : fallback
}

// The writes that assign the ticked main categories to groupId and
// un-assign the unticked ones, as [categoryId, 'set' | 'clear'] pairs.
export function groupMembershipChanges(mains, groupId, wantedIds) {
  const changes = []
  for (const c of mains) {
    const wanted = wantedIds.has(c.id)
    if (wanted && c.groupId !== groupId) changes.push([c.id, 'set'])
    if (!wanted && c.groupId === groupId) changes.push([c.id, 'clear'])
  }
  return changes
}

// Firestore batches hold at most 500 writes.
export function chunk(list, size = 450) {
  const out = []
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size))
  return out
}
