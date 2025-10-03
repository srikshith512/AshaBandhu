const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const auth = require('../middleware/auth');

const router = express.Router();

// Sync patients from mobile to server
router.post('/patients', auth, [
  body('patients').isArray().withMessage('Patients must be an array'),
  body('patients.*.id').notEmpty().withMessage('Patient ID is required'),
  body('patients.*.action').isIn(['create', 'update', 'delete']).withMessage('Invalid action')
], async (req, res) => {
  const client = await db.getClient();
  
  try {
    await client.query('BEGIN');
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { patients } = req.body;
    const results = [];

    for (const patientData of patients) {
      const { id, action, data } = patientData;
      
      try {
        let result;
        
        switch (action) {
          case 'create':
            result = await client.query(`
              INSERT INTO patients (
                id, name, age, gender, phone, village, abha_id, risk_level,
                is_priority, medical_conditions, next_visit_date, anc_visit_date, 
                assigned_worker, sync_status
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'synced')
              ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                age = EXCLUDED.age,
                gender = EXCLUDED.gender,
                phone = EXCLUDED.phone,
                village = EXCLUDED.village,
                abha_id = EXCLUDED.abha_id,
                risk_level = EXCLUDED.risk_level,
                is_priority = EXCLUDED.is_priority,
                medical_conditions = EXCLUDED.medical_conditions,
                next_visit_date = EXCLUDED.next_visit_date,
                anc_visit_date = EXCLUDED.anc_visit_date,
                sync_status = 'synced'
              RETURNING *
            `, [
              id, data.name, data.age, data.gender, data.phone, data.village,
              data.abhaId, data.riskLevel, data.isPriority, data.medicalConditions,
              data.nextVisitDate, data.ancVisitDate, data.assignedWorker
            ]);
            break;
            
          case 'update':
            result = await client.query(`
              UPDATE patients 
              SET name = $2, age = $3, gender = $4, phone = $5, village = $6,
                  abha_id = $7, risk_level = $8, is_priority = $9, 
                  medical_conditions = $10, next_visit_date = $11, 
                  anc_visit_date = $12, sync_status = 'synced'
              WHERE id = $1 
              RETURNING *
            `, [
              id, data.name, data.age, data.gender, data.phone, data.village,
              data.abhaId, data.riskLevel, data.isPriority, data.medicalConditions,
              data.nextVisitDate, data.ancVisitDate
            ]);
            break;
            
          case 'delete':
            result = await client.query('DELETE FROM patients WHERE id = $1 RETURNING *', [id]);
            break;
        }

        // Log sync operation
        await client.query(`
          INSERT INTO sync_logs (id, worker_id, sync_type, entity_type, entity_id, action, data, status)
          VALUES ($1, $2, 'mobile_to_server', 'patient', $3, $4, $5, 'completed')
        `, [uuidv4(), req.worker.worker_id, id, action, JSON.stringify(data)]);

        results.push({
          id,
          action,
          status: 'success',
          data: result.rows[0] || null
        });
        
      } catch (error) {
        console.error(`Error syncing patient ${id}:`, error);
        
        // Log failed sync
        await client.query(`
          INSERT INTO sync_logs (id, worker_id, sync_type, entity_type, entity_id, action, data, status, error_message)
          VALUES ($1, $2, 'mobile_to_server', 'patient', $3, $4, $5, 'failed', $6)
        `, [uuidv4(), req.worker.worker_id, id, action, JSON.stringify(data), error.message]);

        results.push({
          id,
          action,
          status: 'error',
          error: error.message
        });
      }
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Sync completed',
      data: {
        results,
        totalProcessed: patients.length,
        successful: results.filter(r => r.status === 'success').length,
        failed: results.filter(r => r.status === 'error').length
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Sync patients error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  } finally {
    client.release();
  }
});

// Get updates from server for mobile
router.get('/patients', auth, async (req, res) => {
  try {
    const { lastSync } = req.query;
    let query = 'SELECT * FROM patients WHERE sync_status = $1';
    const params = ['synced'];

    // If ASHA worker, only get their assigned patients
    if (req.worker.role === 'asha') {
      query += ' AND assigned_worker = $2';
      params.push(req.worker.worker_id);
    }

    if (lastSync) {
      const paramIndex = params.length + 1;
      query += ` AND updated_at > $${paramIndex}`;
      params.push(new Date(lastSync));
    }

    query += ' ORDER BY updated_at DESC';

    const result = await db.query(query, params);

    res.json({
      success: true,
      data: {
        patients: result.rows,
        total: result.rows.length,
        syncTime: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Get sync patients error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get sync status
router.get('/status', auth, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        sync_type,
        entity_type,
        status,
        COUNT(*) as count,
        MAX(created_at) as last_sync
      FROM sync_logs 
      WHERE worker_id = $1 
      GROUP BY sync_type, entity_type, status
      ORDER BY last_sync DESC
    `, [req.worker.worker_id]);

    res.json({
      success: true,
      data: {
        syncStatus: result.rows
      }
    });
  } catch (error) {
    console.error('Get sync status error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
