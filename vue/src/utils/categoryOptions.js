// Category picker options for the post form (unit-tested: npm test).
//
// The categories collection is flat (subcategories have parentId). The old
// picker listed all ~1000 docs alphabetically with no hierarchy, so many
// subcategories with the same name were indistinguishable and admins
// tended to pick the main category. Here every main category is followed by
// its subcategories, labelled "Main › Sub", and searching a main
// category's name also lists its subcategories.

const byName = (a, b) => (a.name || '').localeCompare(b.name || '')

export function categoryOptions(categories) {
  const list = categories || []
  const ids = new Set(list.map((c) => c.id))
  // A subcategory whose parent was deleted is shown as a main category.
  const isMain = (c) => !c.parentId || !ids.has(c.parentId)
  const out = []
  for (const main of list.filter(isMain).sort(byName)) {
    const subs = list.filter((c) => c.parentId === main.id && c.id !== main.id).sort(byName)
    out.push({ ...main, depth: 0, label: main.name || '', parentName: null, subCount: subs.length })
    for (const sub of subs) {
      out.push({ ...sub, depth: 1, label: `${main.name || ''} › ${sub.name || ''}`, parentName: main.name || '', subCount: 0 })
    }
  }
  return out
}

export function filterCategoryOptions(options, query) {
  const q = (query || '').trim().toLowerCase()
  if (!q) return options
  return options.filter((o) => o.label.toLowerCase().includes(q))
}
