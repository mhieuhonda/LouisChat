// PostgreSQL connection pool + schema bootstrap
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.PG_HOST || '163.44.96.79',
  port: parseInt(process.env.PG_PORT || '5432', 10),
  user: process.env.PG_USER || 'codelung',
  password: process.env.PG_PASSWORD || 'dungthaydoimatkhau',
  database: process.env.PG_DATABASE || 'postgres',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('[PG] Unexpected error on idle client', err);
});

async function initSchema() {
  const client = await pool.connect();
  try {
    // Users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username      VARCHAR(50)  UNIQUE NOT NULL,
        email         VARCHAR(120) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        display_name  VARCHAR(120) NOT NULL,
        avatar_url    TEXT,
        bio           TEXT,
        created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        last_seen     TIMESTAMPTZ
      );
    `);

    // Conversations (1-1 for v0.1; group-ready schema)
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversations (
        id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        type       VARCHAR(20) NOT NULL DEFAULT 'direct',
        title      VARCHAR(200),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS conversation_members (
        conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
        user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (conversation_id, user_id)
      );
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_conv_members_user ON conversation_members(user_id);
    `);

    // Messages
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
        sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content         TEXT NOT NULL,
        attachment_url  TEXT,
        status          VARCHAR(20) NOT NULL DEFAULT 'sent',
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        read_at         TIMESTAMPTZ
      );
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_messages_conv_created
        ON messages(conversation_id, created_at DESC);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
    `);

    console.log('[PG] Schema initialized.');
  } finally {
    client.release();
  }
}

module.exports = { pool, initSchema };
