const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const auth = require('../middleware/auth');

const router = express.Router();

// Get all patients (with filtering)
router.get('/', auth, [
  query('assignedWorker').optional(),
  query('syncStatus').optional().isIn(['local', 'pending', 'synced']),
  query('riskLevel').optional().isIn(['low', 'medium', 'high']),
  query('search').optional()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { assignedWorker, syncStatus, riskLevel, search } = req.query;
    let query = 'SELECT * FROM patients WHERE 1=1';
    const params = [];
    let paramCount = 0;

    if (assignedWorker) {
      paramCount++;
      query += ` AND assigned_worker = $${paramCount}`;
      params.push(assignedWorker);
    }

    if (syncStatus) {
      paramCount++;
      query += ` AND sync_status = $${paramCount}`;
      params.push(syncStatus);
    }

    if (riskLevel) {
      paramCount++;
      query += ` AND risk_level = $${paramCount}`;
      params.push(riskLevel);
    }

    if (search) {
      paramCount++;
      query += ` AND (name ILIKE $${paramCount} OR phone ILIKE $${paramCount} OR village ILIKE $${paramCount})`;
      params.push(`%${search}%`);
    }

    query += ' ORDER BY created_at DESC';

    const result = await db.query(query, params);

    res.json({
      success: true,
      data: {
        patients: result.rows,
        total: result.rows.length
      }
    });
  } catch (error) {
    console.error('Get patients error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get single patient
router.get('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query('SELECT * FROM patients WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found'
      });
    }

    res.json({
      success: true,
      data: {
        patient: result.rows[0]
      }
    });
  } catch (error) {
    console.error('Get patient error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Create new patient
router.post('/', auth, [
  body('name').notEmpty().withMessage('Name is required'),
  body('age').isInt({ min: 0, max: 120 }).withMessage('Age must be between 0 and 120'),
  body('gender').isIn(['male', 'female', 'other']).withMessage('Invalid gender'),
  body('phone').optional().isMobilePhone().withMessage('Invalid phone number'),
  body('village').optional(),
  body('abhaId').optional().isLength({ min: 14, max: 14 }).withMessage('ABHA ID must be 14 digits'),
  body('riskLevel').optional().isIn(['low', 'medium', 'high']),
  body('isPriority').optional().isBoolean(),
  body('medicalConditions').optional().isArray(),
  body('nextVisitDate').optional().isISO8601(),
  body('ancVisitDate').optional().isISO8601(),
  body('assignedWorker').notEmpty().withMessage('Assigned worker is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const {
      name, age, gender, phone, village, abhaId, riskLevel,
      isPriority, medicalConditions, nextVisitDate, ancVisitDate, assignedWorker
    } = req.body;

    const patientId = uuidv4();

    const result = await db.query(`
      INSERT INTO patients (
        id, name, age, gender, phone, village, abha_id, risk_level,
        is_priority, medical_conditions, next_visit_date, anc_visit_date, assigned_worker
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *
    `, [
      patientId, name, age, gender, phone, village, abhaId, riskLevel || 'low',
      isPriority || false, medicalConditions || [], nextVisitDate, ancVisitDate, assignedWorker
    ]);

    res.status(201).json({
      success: true,
      message: 'Patient created successfully',
      data: {
        patient: result.rows[0]
      }
    });
  } catch (error) {
    console.error('Create patient error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update patient
router.put('/:id', auth, [
  body('name').optional().notEmpty(),
  body('age').optional().isInt({ min: 0, max: 120 }),
  body('gender').optional().isIn(['male', 'female', 'other']),
  body('phone').optional().isMobilePhone(),
  body('riskLevel').optional().isIn(['low', 'medium', 'high']),
  body('isPriority').optional().isBoolean(),
  body('medicalConditions').optional().isArray(),
  body('nextVisitDate').optional().isISO8601(),
  body('ancVisitDate').optional().isISO8601()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const updates = req.body;

    // Build dynamic update query
    const setClause = [];
    const params = [id];
    let paramCount = 1;

    Object.keys(updates).forEach(key => {
      if (updates[key] !== undefined) {
        paramCount++;
        setClause.push(`${key.replace(/([A-Z])/g, '_$1').toLowerCase()} = $${paramCount}`);
        params.push(updates[key]);
      }
    });

    if (setClause.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    const query = `
      UPDATE patients 
      SET ${setClause.join(', ')}, sync_status = 'pending'
      WHERE id = $1 
      RETURNING *
    `;

    const result = await db.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found'
      });
    }

    res.json({
      success: true,
      message: 'Patient updated successfully',
      data: {
        patient: result.rows[0]
      }
    });
  } catch (error) {
    console.error('Update patient error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Delete patient
router.delete('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query('DELETE FROM patients WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found'
      });
    }

    res.json({
      success: true,
      message: 'Patient deleted successfully'
    });
  } catch (error) {
    console.error('Delete patient error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
