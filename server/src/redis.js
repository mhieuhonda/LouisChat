// Redis client (sessions + pub/sub for realtime)
const Redis = require('ioredis');

const redisUrl = process.env.REDIS_PASSWORD
  ? `redis://:${process.env.REDIS_PASSWORD}@${process.env.REDIS_HOST || '163.44.96.79'}:${process.env.REDIS_PORT || 6379}`
  : `redis://${process.env.REDIS_HOST || '163.44.96.79'}:${process.env.REDIS_PORT || 6379}`;

const redis = new Redis(redisUrl, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  lazyConnect: false,
  reconnectOnError(err) {
    const targets = ['READONLY', 'NOAUTH', 'ECONNRESET'];
    return targets.some((t) => err.message.includes(t));
  },
});

// Separate connection for subscriptions (required by Redis)
const subscriber = new Redis(redisUrl, {
  maxRetriesPerRequest: null,
});

redis.on('connect', () => console.log('[Redis] connected.'));
redis.on('error', (err) => console.error('[Redis] error:', err.message));
subscriber.on('error', (err) => console.error('[Redis sub] error:', err.message));

// Presence helpers
async function setUserOnline(userId, socketId) {
  await redis.sadd(`online:${userId}`, socketId);
  await redis.publish('presence', JSON.stringify({ userId, online: true }));
}

async function setUserOffline(userId, socketId) {
  await redis.srem(`online:${userId}`, socketId);
  const remaining = await redis.scard(`online:${userId}`);
  if (remaining === 0) {
    await redis.publish('presence', JSON.stringify({ userId, online: false }));
  }
  return remaining === 0;
}

async function isUserOnline(userId) {
  const count = await redis.scard(`online:${userId}`);
  return count > 0;
}

// Message bus helpers
async function publishMessage(channel, payload) {
  await redis.publish(channel, JSON.stringify(payload));
}

async function subscribe(channel, handler) {
  subscriber.subscribe(channel);
  subscriber.on('message', (ch, msg) => {
    if (ch === channel) {
      try { handler(JSON.parse(msg)); } catch (e) { /* ignore */ }
    }
  });
}

module.exports = {
  redis,
  subscriber,
  setUserOnline,
  setUserOffline,
  isUserOnline,
  publishMessage,
  subscribe,
};
