// Optional MySQL connection (kept for auxiliary logs / future use).
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || '163.44.96.79',
  port: parseInt(process.env.MYSQL_PORT || '3306', 10),
  user: process.env.MYSQL_USER || 'codelung',
  password: process.env.MYSQL_PASSWORD || 'dungthaydoimatkhau',
  database: process.env.MYSQL_DATABASE || 'default',
  waitForConnections: true,
  connectionLimit: 5,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
});

async function ping() {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    console.log('[MySQL] ping OK.');
    return true;
  } catch (err) {
    console.warn('[MySQL] ping failed:', err.message);
    return false;
  }
}

async function logEvent(level, source, message, meta = null) {
  try {
    await pool.execute(
      `CREATE TABLE IF NOT EXISTS app_events (
        id BIGINT AUTO_INCREMENT PRIMARY KEY,
        level VARCHAR(20) NOT NULL,
        source VARCHAR(80) NOT NULL,
        message TEXT,
        meta JSON,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )`
    );
    await pool.execute(
      `INSERT INTO app_events (level, source, message, meta) VALUES (?, ?, ?, ?)`,
      [level, source, message, meta ? JSON.stringify(meta) : null]
    );
  } catch (err) {
    // do not break the request flow
  }
}

module.exports = { pool, ping, logEvent };
