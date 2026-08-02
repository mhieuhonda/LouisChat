// Socket.io realtime layer.
// Strategy: each socket joins a personal room `user:<id>` and every conversation
// room `conv:<conversationId>`. Redis pub/sub fans messages across workers.
const { verifyToken } = require('./middleware/auth');
const { pool } = require('./db');
const { setUserOnline, setUserOffline, subscribe, publishMessage } = require('./redis');
const { logEvent } = require('./mysql');

function attachSocket(io) {
  // Auth middleware
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) return next(new Error('no_token'));
    const decoded = verifyToken(token);
    if (!decoded) return next(new Error('invalid_token'));
    socket.user = decoded;
    next();
  });

  io.on('connection', async (socket) => {
    const userId = socket.user.sub;
    const username = socket.user.username;

    await setUserOnline(userId, socket.id);
    await logEvent('info', 'socket', 'connected', { userId });

    socket.join(`user:${userId}`);

    // Tell this user's peers they're online
    socket.emit('presence', { userId, online: true });

    // Listen for client subscribing to a conversation room
    socket.on('conversation:join', async (conversationId) => {
      if (!conversationId) return;
      const member = await pool.query(
        `SELECT 1 FROM conversation_members WHERE conversation_id = $1 AND user_id = $2`,
        [conversationId, userId]
      );
      if (member.rowCount > 0) {
        socket.join(`conv:${conversationId}`);
      }
    });

    socket.on('conversation:leave', (conversationId) => {
      socket.leave(`conv:${conversationId}`);
    });

    // Typing indicator
    socket.on('typing', async ({ conversationId, isTyping }) => {
      await publishMessage('chat:typing', {
        conversation_id: conversationId,
        user_id: userId,
        username,
        isTyping: !!isTyping,
      });
    });

    // Client-acknowledged read receipts (server is the source of truth via REST,
    // but we also broadcast so other clients update instantly)
    socket.on('message:read', async ({ conversationId }) => {
      await publishMessage('chat:read', {
        conversation_id: conversationId,
        reader_id: userId,
      });
    });

    socket.on('disconnect', async () => {
      const fullyOffline = await setUserOffline(userId, socket.id);
      if (fullyOffline) {
        socket.broadcast.emit('presence', { userId, online: false });
        await logEvent('info', 'socket', 'disconnected', { userId });
      }
    });
  });

  // ===== Fan-out from Redis pub/sub to socket rooms =====
  subscribe('chat:message', (payload) => {
    const { conversation_id, message } = payload;
    if (!conversation_id || !message) return;
    io.to(`conv:${conversation_id}`).emit('message:new', payload);
  });

  subscribe('chat:typing', (payload) => {
    const { conversation_id, user_id, username, isTyping } = payload;
    if (!conversation_id) return;
    io.to(`conv:${conversation_id}`).emit('typing', {
      conversation_id,
      user_id,
      username,
      isTyping,
    });
  });

  subscribe('chat:read', (payload) => {
    const { conversation_id, reader_id } = payload;
    if (!conversation_id) return;
    io.to(`conv:${conversation_id}`).emit('message:read', {
      conversation_id,
      reader_id,
    });
  });

  subscribe('presence', (payload) => {
    io.emit('presence', payload);
  });
}

module.exports = { attachSocket };
