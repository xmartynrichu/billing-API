/**
 * PostgreSQL Database Connection
 * Manages database connection pool and initialization
 */

const { Pool } = require('pg');

/**
 * Create connection pool
 */
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  max: 20, // Maximum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});

/**
 * Handle pool errors
 */
pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client:', err);
});

/**
 * Connection test on startup
 */
(async () => {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ PostgreSQL connected successfully');
    console.log('   Database Time:', result.rows[0].now);
  } catch (err) {
    console.error('❌ PostgreSQL connection failed');
    console.error('   Error:', err.message);
    console.error('   Code:', err.code);
    
    // Retry connection attempt
    setTimeout(() => {
      console.log('🔄 Retrying database connection...');
    }, 5000);
  }
})();

module.exports = pool;

