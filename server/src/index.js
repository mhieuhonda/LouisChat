require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const { initSchema } = require('./db');
const { attachSocket } = require('./socket');
const { ping: mysqlPing } = require('./mysql');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const messageRoutes = require('./routes/messages');

const PORT = parseInt(process.env.PORT || '3000', 10);
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

const app = express();
const server = http.createServer(app);

// ===== CORS =====
app.use(cors({
  origin: CORS_ORIGIN === '*' ? true : CORS_ORIGIN.split(',').map((s) => s.trim()),
  credentials: true,
}));

// ===== Body parsing =====
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// ===== Static uploads =====
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
app.use('/uploads', express.static(uploadDir));

// ===== Health check =====
app.get('/health', (_req, res) => res.json({ ok: true, name: 'louischat-server', version: '0.1.0' }));

// ===== API routes =====
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);

// ===== 404 =====
app.use((req, res) => res.status(404).json({ error: 'not_found', path: req.path }));

// ===== Error handler =====
app.use((err, _req, res, _next) => {
  console.error('[server] error:', err);
  res.status(500).json({ error: 'server_error', detail: err.message });
});

// ===== Socket.io =====
const io = require('socket.io')(server, {
  cors: {
    origin: CORS_ORIGIN === '*' ? true : CORS_ORIGIN.split(',').map((s) => s.trim()),
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
attachSocket(io);

// ===== Boot =====
(async () => {
  try {
    await initSchema();
    await mysqlPing();
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`[LouisChat] server listening on :${PORT}`);
    });
  } catch (err) {
    console.error('[LouisChat] boot failed:', err);
    process.exit(1);
  }
})();
