const express = require('express');
const { pool } = require('../db');
const { authRequired } = require('../middleware/auth');
const { isUserOnline } = require('../redis');

const router = express.Router();

// ===== GET /api/users/search?q=... =====
router.get('/search', authRequired, async (req, res) => {
  try {
    const q = (req.query.q || '').trim();
    if (q.length < 1) return res.json({ users: [] });

    const result = await pool.query(
      `SELECT id, username, display_name, avatar_url
       FROM users
       WHERE (username ILIKE $1 OR display_name ILIKE $1)
         AND id <> $2
       ORDER BY username
       LIMIT 20`,
      [`%${q}%`, req.user.sub]
    );
    const users = await Promise.all(
      result.rows.map(async (u) => ({ ...u, online: await isUserOnline(u.id) }))
    );
    return res.json({ users });
  } catch (err) {
    console.error('[users] search error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== GET /api/users/:id =====
router.get('/:id', authRequired, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, display_name, avatar_url, bio, created_at
       FROM users WHERE id = $1`,
      [req.params.id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'user_not_found' });
    const u = result.rows[0];
    u.online = await isUserOnline(u.id);
    return res.json({ user: u });
  } catch (err) {
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

module.exports = router;
