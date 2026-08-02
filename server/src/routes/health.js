const express = require('express');
const { pool, ping: pgPing } = require('../db');
const { ping: mysqlPing } = require('../mysql');
const { redis } = require('../redis');

const router = express.Router();

// ===== GET /api/health =====
// Lightweight liveness check — no DB calls.
router.get('/', (_req, res) => {
  res.json({
    ok: true,
    name: 'louischat-server',
    version: '0.3.0',
    uptime: Math.floor(process.uptime()),
    ts: new Date().toISOString(),
  });
});

// ===== GET /api/health/deep =====
// Readiness check — verifies all backing services.
router.get('/deep', async (_req, res) => {
  const out = { ok: true, services: {}, ts: new Date().toISOString() };
  const tasks = [
    ['postgres', async () => {
      await pgPing();
      return 'ok';
    }],
    ['mysql', async () => {
      const ok = await mysqlPing();
      if (!ok) throw new Error('mysql_ping_failed');
      return 'ok';
    }],
    ['redis', async () => {
      const pong = await redis.ping();
      if (pong !== 'PONG') throw new Error('redis_no_pong');
      return 'ok';
    }],
  ];

  await Promise.all(
    tasks.map(async ([name, fn]) => {
      try {
        const detail = await fn();
        out.services[name] = { ok: true, detail };
      } catch (err) {
        out.ok = false;
        out.services[name] = { ok: false, error: err.message };
      }
    })
  );

  // Pool stats
  try {
    out.services.postgres.pool = {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount,
    };
  } catch (_) {}

  return res.status(out.ok ? 200 : 503).json(out);
});

module.exports = router;
