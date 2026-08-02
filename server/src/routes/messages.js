const express = require('express');
const { pool } = require('../db');
const { authRequired } = require('../middleware/auth');
const { publishMessage } = require('../redis');

const router = express.Router();

// Helper: get-or-create a direct conversation between two users
async function getOrCreateDirectConversation(userA, userB) {
  const existing = await pool.query(
    `SELECT c.id
     FROM conversations c
     JOIN conversation_members m1 ON m1.conversation_id = c.id AND m1.user_id = $1
     JOIN conversation_members m2 ON m2.conversation_id = c.id AND m2.user_id = $2
     WHERE c.type = 'direct'
     LIMIT 1`,
    [userA, userB]
  );
  if (existing.rowCount > 0) return existing.rows[0].id;

  const created = await pool.query(
    `INSERT INTO conversations (type, title) VALUES ('direct', NULL) RETURNING id`
  );
  const convId = created.rows[0].id;
  await pool.query(
    `INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2), ($1, $3)`,
    [convId, userA, userB]
  );
  return convId;
}

// ===== GET /api/messages/conversations =====
router.get('/conversations', authRequired, async (_req, res) => {
  try {
    const result = await pool.query(
      `SELECT DISTINCT c.id, c.type, c.title, c.updated_at,
              (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message,
              (SELECT created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message_at,
              (SELECT sender_id FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_sender_id
       FROM conversations c
       JOIN conversation_members m ON m.conversation_id = c.id
       WHERE m.user_id = $1
       ORDER BY c.updated_at DESC`,
      [_req.user.sub]
    );

    // Enrich with the other participant for direct conversations
    const convs = [];
    for (const c of result.rows) {
      const peers = await pool.query(
        `SELECT u.id, u.username, u.display_name, u.avatar_url
         FROM conversation_members m
         JOIN users u ON u.id = m.user_id
         WHERE m.conversation_id = $1 AND m.user_id <> $2`,
        [c.id, _req.user.sub]
      );
      convs.push({ ...c, peers: peers.rows });
    }
    return res.json({ conversations: convs });
  } catch (err) {
    console.error('[messages] conversations error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== POST /api/messages/conversations/direct  { peerId } =====
router.post('/conversations/direct', authRequired, async (req, res) => {
  try {
    const { peerId } = req.body || {};
    if (!peerId) return res.status(400).json({ error: 'missing_peer_id' });
    if (peerId === req.user.sub) return res.status(400).json({ error: 'cannot_chat_self' });

    const convId = await getOrCreateDirectConversation(req.user.sub, peerId);
    return res.json({ conversationId: convId });
  } catch (err) {
    console.error('[messages] create direct error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== GET /api/messages/:conversationId?before=&limit= =====
router.get('/:conversationId', authRequired, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
    const before = req.query.before; // ISO timestamp

    // Make sure caller is a member
    const member = await pool.query(
      `SELECT 1 FROM conversation_members WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, req.user.sub]
    );
    if (member.rowCount === 0) {
      return res.status(403).json({ error: 'not_a_member' });
    }

    const params = [conversationId, limit];
    let sql = `
      SELECT m.id, m.conversation_id, m.sender_id, m.content, m.attachment_url,
             m.status, m.created_at, m.read_at,
             u.username AS sender_username, u.display_name AS sender_name, u.avatar_url AS sender_avatar
      FROM messages m
      JOIN users u ON u.id = m.sender_id
      WHERE m.conversation_id = $1
    `;
    if (before) {
      params.push(before);
      sql += ` AND m.created_at < $3`;
    }
    sql += ` ORDER BY m.created_at DESC LIMIT $2`;

    const result = await pool.query(sql, params);
    return res.json({ messages: result.rows.reverse() });
  } catch (err) {
    console.error('[messages] list error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== POST /api/messages/:conversationId  { content } =====
router.post('/:conversationId', authRequired, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { content } = req.body || {};
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'empty_message' });
    }

    const member = await pool.query(
      `SELECT 1 FROM conversation_members WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, req.user.sub]
    );
    if (member.rowCount === 0) {
      return res.status(403).json({ error: 'not_a_member' });
    }

    const result = await pool.query(
      `INSERT INTO messages (conversation_id, sender_id, content, status)
       VALUES ($1, $2, $3, 'sent')
       RETURNING id, conversation_id, sender_id, content, status, created_at`,
      [conversationId, req.user.sub, content.trim()]
    );

    const msg = result.rows[0];

    await pool.query(`UPDATE conversations SET updated_at = NOW() WHERE id = $1`, [conversationId]);

    // Publish over Redis so all socket workers can fan-out
    await publishMessage('chat:message', {
      conversation_id: conversationId,
      message: {
        ...msg,
        sender_username: req.user.username,
      },
    });

    return res.status(201).json({ message: msg });
  } catch (err) {
    console.error('[messages] send error:', err);
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

// ===== POST /api/messages/:conversationId/read =====
router.post('/:conversationId/read', authRequired, async (req, res) => {
  try {
    const { conversationId } = req.params;
    await pool.query(
      `UPDATE messages
       SET status = 'read', read_at = NOW()
       WHERE conversation_id = $1 AND sender_id <> $2 AND status <> 'read'`,
      [conversationId, req.user.sub]
    );
    await publishMessage('chat:read', { conversation_id: conversationId, reader_id: req.user.sub });
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: 'server_error', detail: err.message });
  }
});

module.exports = router;
