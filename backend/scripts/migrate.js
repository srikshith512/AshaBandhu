const db = require('../config/database');

const createTables = async () => {
  try {
    console.log('🔄 Creating database tables...');

    // Workers table
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

    // Worker authentication table (separate for security)
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
        age INTEGER NOT NULL CHECK (age >= 0 AND age <= 120),
        gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female', 'other')),
        phone VARCHAR(15),
        village VARCHAR(255),
        abha_id VARCHAR(14),
        risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
        is_priority BOOLEAN DEFAULT false,
        medical_conditions TEXT[],
        next_visit_date DATE,
        anc_visit_date DATE,
        last_visit DATE,
        assigned_worker VARCHAR(50) REFERENCES workers(worker_id),
        sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('local', 'pending', 'synced')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Patient visits table
    await db.query(`
      CREATE TABLE IF NOT EXISTS patient_visits (
        id UUID PRIMARY KEY,
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        worker_id VARCHAR(50) REFERENCES workers(worker_id),
        visit_date DATE NOT NULL,
        visit_type VARCHAR(50),
        notes TEXT,
        vital_signs JSONB,
        medications JSONB,
        follow_up_required BOOLEAN DEFAULT false,
        follow_up_date DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Sync logs table
    await db.query(`
      CREATE TABLE IF NOT EXISTS sync_logs (
        id UUID PRIMARY KEY,
        worker_id VARCHAR(50) REFERENCES workers(worker_id),
        sync_type VARCHAR(50) NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id VARCHAR(255) NOT NULL,
        action VARCHAR(20) NOT NULL CHECK (action IN ('create', 'update', 'delete')),
        data JSONB,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
        error_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        processed_at TIMESTAMP
      );
    `);

    // Create indexes for better performance
    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_patients_assigned_worker ON patients(assigned_worker);
      CREATE INDEX IF NOT EXISTS idx_patients_sync_status ON patients(sync_status);
      CREATE INDEX IF NOT EXISTS idx_patients_next_visit ON patients(next_visit_date);
      CREATE INDEX IF NOT EXISTS idx_patient_visits_patient_id ON patient_visits(patient_id);
      CREATE INDEX IF NOT EXISTS idx_patient_visits_date ON patient_visits(visit_date);
      CREATE INDEX IF NOT EXISTS idx_sync_logs_worker ON sync_logs(worker_id);
      CREATE INDEX IF NOT EXISTS idx_sync_logs_status ON sync_logs(status);
    `);

    // Create updated_at trigger function
    await db.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    `);

    // Create triggers for updated_at (drop if exists first)
    await db.query(`
      DROP TRIGGER IF EXISTS update_workers_updated_at ON workers;
      DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
      
      CREATE TRIGGER update_workers_updated_at BEFORE UPDATE ON workers
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
      
      CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `);

    console.log('✅ Database tables created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating tables:', error);
    process.exit(1);
  }
};

createTables();
