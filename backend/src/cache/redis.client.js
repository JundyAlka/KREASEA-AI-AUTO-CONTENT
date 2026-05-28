/**
 * REDIS CACHE CLIENT — KreaSea Backend
 * ─────────────────────────────────────────────────────────
 * Dual-mode: gunakan Redis jika tersedia, fallback ke in-memory Map.
 * Cocok untuk development tanpa Redis dan production dengan Upstash.
 */

let redis = null;
const memoryCache = new Map(); // fallback jika Redis tidak ada

async function initRedis() {
  const redisUrl = process.env.REDIS_URL;
  if (!redisUrl || redisUrl.includes('your_password')) {
    console.warn('[Cache] Redis URL tidak dikonfigurasi — menggunakan in-memory cache (tidak persistent)');
    return;
  }

  try {
    const { default: IORedis } = await import('ioredis');
    redis = new IORedis(redisUrl, {
      maxRetriesPerRequest: 2,
      connectTimeout: 5000,
      lazyConnect: true,
    });

    redis.on('error', (err) => {
      console.warn('[Cache] Redis error, fallback in-memory tetap aktif:', err.message);
    });

    await redis.connect();
    console.log('[Cache] Redis terhubung:', redisUrl.replace(/:\/\/.*@/, '://***@'));
  } catch (err) {
    console.warn('[Cache] Gagal connect Redis, fallback ke in-memory:', err.message);
    if (redis) redis.disconnect();
    redis = null;
  }
}

/**
 * Simpan ke cache dengan TTL dalam detik
 * @param {string} key
 * @param {any} value
 * @param {number} ttlSeconds
 */
async function setCache(key, value, ttlSeconds = 300) {
  const serialized = JSON.stringify(value);
  if (redis) {
    await redis.set(key, serialized, 'EX', ttlSeconds);
  } else {
    memoryCache.set(key, {
      value: serialized,
      expiry: Date.now() + ttlSeconds * 1000,
    });
    // Cleanup expired entries sesekali
    if (memoryCache.size > 500) cleanMemoryCache();
  }
}

/**
 * Ambil dari cache, return null jika tidak ada atau expired
 * @param {string} key
 * @returns {Promise<any|null>}
 */
async function getCache(key) {
  if (redis) {
    const val = await redis.get(key);
    return val ? JSON.parse(val) : null;
  }

  const entry = memoryCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiry) {
    memoryCache.delete(key);
    return null;
  }
  return JSON.parse(entry.value);
}

/**
 * Set cooldown state untuk API key (di Redis, untuk sharing antar instance)
 * @param {string} keyId
 * @param {number} durationMs
 */
async function setKeyCooldown(keyId, durationMs) {
  const ttlSec = Math.ceil(durationMs / 1000);
  await setCache(`key_cooldown:${keyId}`, true, ttlSec);
}

async function isKeyCooldown(keyId) {
  const val = await getCache(`key_cooldown:${keyId}`);
  return val === true;
}

async function deleteCache(key) {
  if (redis) {
    await redis.del(key);
  } else {
    memoryCache.delete(key);
  }
}

function cleanMemoryCache() {
  const now = Date.now();
  for (const [k, v] of memoryCache.entries()) {
    if (now > v.expiry) memoryCache.delete(k);
  }
}

/**
 * Buat cache key yang konsisten dari parameter
 * @param {string} prefix - nama fitur
 * @param {object} params - parameter request
 */
function makeCacheKey(prefix, params) {
  const sorted = JSON.stringify(params, Object.keys(params).sort());
  // Simple hash — cukup untuk cache key
  let hash = 0;
  for (let i = 0; i < sorted.length; i++) {
    hash = ((hash << 5) - hash + sorted.charCodeAt(i)) | 0;
  }
  return `${prefix}:${Math.abs(hash)}`;
}

module.exports = { initRedis, setCache, getCache, setKeyCooldown, isKeyCooldown, deleteCache, makeCacheKey };
