const express = require('express');
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { pool } = require('../db');
const { signToken, authRequired } = require('../middleware/auth');
const { logEvent } = require('../mysql');

const router = express.Router();

// ===== Multer storage (avatar uploads) =====
const uploadDir = path.join(__dirname, '..', '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `avatar_${Date.now()}_${Math.random().toString(36).slice(2, 8)}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: (parseInt(process.env.MAX_UPLOAD_MB || '10', 10)) * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /^image\/(png|jpe?g|webp|gif)$/.test(file.mimetype);
    cb(ok ? null : new Error('only_image_allowed'), ok);
  },
});

// ===== POST /api/auth/register =====
router.post('/register', async (req, res) => {
  try {
    const { username, email, password, displayName } = req.body || {};
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'missing_fields' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'password_too_short' });
    }

    const exists = await pool.query(
      `SELECT id FROM users WHERE username = $1 OR email = $2`,
      [username, email]
    );
    if (exists.rowCount > 0) {
      return res.status(409).json({ error: 'user_exists' });
    }

    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO users (username, email, password_hash, display_name)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, email, display_name, avatar_url, created_at`,
      [username, email, hash, displayName || username]
    );

    const user = result.rows[0];
    const token = signToken({ sub: user.id, username: user.username });

    await logEvent('info', 'auth', 'user_registered', { userId: user.id, username });

    return res.status(201).json({ token, user });
  } catch (err) {
    console.error('[auth] register error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== POST /api/auth/login =====
router.post('/login', async (req, res) => {
  try {
    const { identifier, password } = req.body || {};
    if (!identifier || !password) {
      return res.status(400).json({ error: 'missing_fields' });
    }

    const result = await pool.query(
      `SELECT id, username, email, display_name, avatar_url, password_hash, created_at
       FROM users WHERE username = $1 OR email = $1`,
      [identifier]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'user_not_found' });
    }

    const user = result.rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'invalid_credentials' });
    }

    const token = signToken({ sub: user.id, username: user.username });
    await logEvent('info', 'auth', 'user_login', { userId: user.id });

    return res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        display_name: user.display_name,
        avatar_url: user.avatar_url,
        created_at: user.created_at,
      },
    });
  } catch (err) {
    console.error('[auth] login error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== GET /api/auth/me =====
router.get('/me', authRequired, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, email, display_name, avatar_url, bio, created_at, updated_at
       FROM users WHERE id = $1`,
      [req.user.sub]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'user_not_found' });
    }
    return res.json({ user: result.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== PUT /api/auth/avatar =====
router.put('/avatar', authRequired, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'no_file_uploaded' });
    }
    const publicUrl = `/uploads/${req.file.filename}`;
    await pool.query(`UPDATE users SET avatar_url = $1, updated_at = NOW() WHERE id = $2`, [
      publicUrl,
      req.user.sub,
    ]);

    const user = await pool.query(
      `SELECT id, username, email, display_name, avatar_url, bio FROM users WHERE id = $1`,
      [req.user.sub]
    );

    return res.json({ user: user.rows[0] });
  } catch (err) {
    console.error('[auth] avatar error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== PUT /api/auth/profile =====
router.put('/profile', authRequired, async (req, res) => {
  try {
    const { displayName, bio } = req.body || {};
    const result = await pool.query(
      `UPDATE users
       SET display_name = COALESCE($1, display_name),
           bio = COALESCE($2, bio),
           updated_at = NOW()
       WHERE id = $3
       RETURNING id, username, email, display_name, avatar_url, bio`,
      [displayName || null, bio || null, req.user.sub]
    );
    return res.json({ user: result.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

module.exports = router;
