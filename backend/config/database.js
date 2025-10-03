require('dotenv').config();
const { Pool } = require('pg');

// Check for the database connection string.
// Vercel automatically provides POSTGRES_URL. For local dev, it's in .env.
const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL or POSTGRES_URL environment variable is not set.');
}

// The Supabase connection string from the environment variables has all the necessary configuration.
const pool = new Pool({
  connectionString,
});

pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  // Don't exit the process in a serverless environment, just log it.
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
  pool,
};
