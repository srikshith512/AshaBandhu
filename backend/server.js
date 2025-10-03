const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const workerRoutes = require('./routes/workers');
const patientRoutes = require('./routes/patients');
const syncRoutes = require('./routes/sync');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Logging
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Test database connection endpoint
app.get('/test-db', async (req, res) => {
  try {
    const db = require('./config/database');
    const result = await db.query('SELECT NOW() as current_time');
    res.json({
      success: true,
      message: 'Database connection successful',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Database test error:', error);
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: error.message
    });
  }
});

// Migration endpoint (for production setup)
app.get('/migrate', async (req, res) => {
  try {
    const db = require('./config/database');
    
    // Create workers table
    await db.query(`
      CREATE TABLE IF NOT EXISTS workers (
        worker_id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        village VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL CHECK (role IN ('asha', 'phc')),
        pin VARCHAR(255) NOT NULL,
        phone_number VARCHAR(15),
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Worker authentication table
    await db.query(`
      CREATE TABLE IF NOT EXISTS worker_auth (
        worker_id VARCHAR(50) PRIMARY KEY REFERENCES workers(worker_id) ON DELETE CASCADE,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Patients table
    await db.query(`
      CREATE TABLE IF NOT EXISTS patients (
        id UUID PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        age INTEGER NOT NULL,
        gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female', 'other')),
        village VARCHAR(255) NOT NULL,
        phone_number VARCHAR(15),
        assigned_worker VARCHAR(50) REFERENCES workers(worker_id),
        conditions TEXT[],
        medications TEXT[],
        next_visit TIMESTAMP,
        is_priority BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        version INTEGER DEFAULT 1,
        sync_status VARCHAR(20) DEFAULT 'synced'
      );
    `);

    // Create function for updating timestamps
    await db.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    `);

    // Create triggers
    await db.query(`
      DROP TRIGGER IF EXISTS update_workers_updated_at ON workers;
      DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
      
      CREATE TRIGGER update_workers_updated_at BEFORE UPDATE ON workers
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
      
      CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `);

    res.json({
      success: true,
      message: 'Database tables created successfully!',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Migration error:', error);
    res.status(500).json({
      success: false,
      message: 'Migration failed',
      error: error.message
    });
  }
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/workers', workerRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/sync', syncRoutes);
// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 ASHA Bandhu Backend Server running on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
