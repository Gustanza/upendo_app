const Fuse = require('fuse.js');
const { onRequest } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');

const CACHE_TTL_MS = 5 * 60 * 1000;
let cache = { posts: null, fetchedAt: 0 };

async function getPosts() {
  const now = Date.now();
  if (cache.posts && now - cache.fetchedAt < CACHE_TTL_MS) {
    return cache.posts;
  }

  const snapshot = await getFirestore().collection('posts').get();
  const posts = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  cache = { posts, fetchedAt: now };
  return posts;
}

const fuseOptions = {
  includeScore: true,
  threshold: 0.4,
  ignoreLocation: true,
  keys: [
    { name: 'title', weight: 0.6 },
    { name: 'subtitle', weight: 0.25 },
    { name: 'description', weight: 0.15 },
  ],
};

exports.searchPosts = onRequest({ cors: true }, async (req, res) => {
  const query = (req.query.q || req.body?.q || '').toString().trim();

  if (!query) {
    res.status(400).json({ error: 'missing query param "q"' });
    return;
  }

  try {
    const posts = await getPosts();
    const fuse = new Fuse(posts, fuseOptions);
    const results = fuse.search(query, { limit: 20 }).map((r) => r.item);
    res.status(200).json({ results });
  } catch (err) {
    console.error('searchPosts: failed', err);
    res.status(500).json({ error: 'search failed' });
  }
});
