require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');

const { initSchema, pool } = require('./db');
const { attachSocket } = require('./socket');
const { ping: mysqlPing } = require('./mysql');
const { errorHandler, notFound } = require('./middleware/error');
const { apiLimiter } = require('./middleware/rateLimit');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const messageRoutes = require('./routes/messages');
const healthRoutes = require('./routes/health');

const PORT = parseInt(process.env.PORT || '3000', 10);
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

const app = express();
const server = http.createServer(app);

// ===== Trust proxy (needed when behind reverse proxy + rate-limit) =====
app.set('trust proxy', 1);

// ===== Security headers =====
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  contentSecurityPolicy: false,
}));

// ===== CORS =====
app.use(cors({
  origin: CORS_ORIGIN === '*' ? true : CORS_ORIGIN.split(',').map((s) => s.trim()),
  credentials: true,
}));

// ===== Compression =====
app.use(compression());

// ===== Request logging =====
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ===== Body parsing =====
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// ===== Static uploads (must come before rate limiter so avatars load fast) =====
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
app.use('/uploads', express.static(uploadDir, {
  maxAge: '7d',
  immutable: true,
  fallthrough: true,
}));

// ===== Health (no rate limit) =====
app.use('/api/health', healthRoutes);

// ===== API rate limiter =====
app.use('/api', apiLimiter);

// ===== API routes =====
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);

// ===== 404 =====
app.use(notFound);

// ===== Error handler (must be last) =====
app.use(errorHandler);

// ===== Socket.io =====
const io = require('socket.io')(server, {
  cors: {
    origin: CORS_ORIGIN === '*' ? true : CORS_ORIGIN.split(',').map((s) => s.trim()),
    methods: ['GET', 'POST'],
    credentials: true,
  },
  pingInterval: 25000,
  pingTimeout: 60000,
  maxHttpBufferSize: 1e6, // 1 MB
});
attachSocket(io);

// ===== Graceful shutdown =====
let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`\n[LouisChat] received ${signal}, shutting down...`);

  // Stop accepting new connections
  server.close(() => console.log('[LouisChat] HTTP server closed.'));

  // Close socket.io
  try {
    io.close();
  } catch (_) {}

  // Close DB pools
  try {
    await pool.end();
    console.log('[LouisChat] PG pool closed.');
  } catch (_) {}

  setTimeout(() => process.exit(0), 1000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('uncaughtException', (err) => {
  console.error('[LouisChat] uncaughtException:', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('[LouisChat] unhandledRejection:', reason);
});

// ===== Boot =====
(async () => {
  try {
    await initSchema();
    await mysqlPing();
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`[LouisChat] server v0.2.0 listening on :${PORT}`);
      console.log(`[LouisChat] health:  http://localhost:${PORT}/api/health`);
      console.log(`[LouisChat] deep:    http://localhost:${PORT}/api/health/deep`);
    });
  } catch (err) {
    console.error('[LouisChat] boot failed:', err);
    process.exit(1);
  }
})();
