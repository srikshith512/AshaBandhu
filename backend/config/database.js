// Load environment variables from .env
require('dotenv').config();
const { Pool } = require('pg');

// Connection string configuration
let connectionString = process.env.POSTGRES_URL_NON_POOLING || process.env.POSTGRES_URL;

// If using Supabase, modify the connection string to disable SSL verification
if (connectionString && connectionString.includes('supabase.co')) {
  // Add SSL parameters to bypass certificate issues
  const url = new URL(connectionString);
  url.searchParams.set('sslmode', 'require');
  url.searchParams.set('sslcert', '');
  url.searchParams.set('sslkey', '');
  url.searchParams.set('sslrootcert', '');
  connectionString = url.toString();
}

const dbConfig = connectionString ? {
  connectionString: connectionString,
  ssl: process.env.NODE_ENV === 'production' ? { 
    rejectUnauthorized: false,
    checkServerIdentity: false
  } : false,
} : {
  host: process.env.DB_HOST || process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || process.env.POSTGRES_DATABASE || 'asha_bandhu',
  user: process.env.DB_USER || process.env.POSTGRES_USER || 'postgres',
  password: process.env.DB_PASSWORD || process.env.POSTGRES_PASSWORD || 'password',
  ssl: process.env.NODE_ENV === 'production' ? { 
    rejectUnauthorized: false,
    checkServerIdentity: false
  } : false,
};

const pool = new Pool(dbConfig);

// Test database connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(),
  pool
};
