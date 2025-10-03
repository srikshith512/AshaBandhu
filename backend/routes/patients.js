const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const auth = require('../middleware/auth');

const router = express.Router();

// --- Validation Rules ---
const patientPostValidationRules = [
  body('name').notEmpty().withMessage('Name is required'),
  body('age').isInt({ min: 0, max: 120 }).withMessage('Age must be between 0 and 120'),
  body('gender').isIn(['male', 'female', 'other']).withMessage('Invalid gender'),
  body('village').notEmpty().withMessage('Village is required'),
  body('phoneNumber').optional({ checkFalsy: true }).isMobilePhone().withMessage('Invalid phone number'),
  body('conditions').optional().isArray(),
  body('medications').optional().isArray(),
  body('nextVisit').optional({ checkFalsy: true }).isISO8601().toDate(),
  body('isPriority').optional().isBoolean(),
];

const patientPutValidationRules = [
  body('name').optional().notEmpty(),
  body('age').optional().isInt({ min: 0, max: 120 }),
  body('gender').optional().isIn(['male', 'female', 'other']),
  body('village').optional().notEmpty(),
  body('phoneNumber').optional({ checkFalsy: true }).isMobilePhone(),
  body('conditions').optional().isArray(),
  body('medications').optional().isArray(),
  body('nextVisit').optional({ checkFalsy: true }).isISO8601().toDate(),
  body('isPriority').optional().isBoolean(),
];

// --- Routes ---

// GET all patients (with filtering)
router.get('/', auth, async (req, res) => {
  try {
    const { assignedWorker, search } = req.query;
    let sqlQuery = 'SELECT * FROM patients';
    const params = [];
    
    if (assignedWorker) {
      sqlQuery += ' WHERE assigned_worker = $1';
      params.push(assignedWorker);
    }

    if (search) {
      const searchClause = `(name ILIKE $${params.length + 1} OR village ILIKE $${params.length + 1})`;
      sqlQuery += params.length > 0 ? ` AND ${searchClause}` : ` WHERE ${searchClause}`;
      params.push(`%${search}%`);
    }

    sqlQuery += ' ORDER BY updated_at DESC';

    const result = await db.query(sqlQuery, params);
    res.json({ success: true, data: result.rows });

  } catch (error) {
    console.error('Get patients error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// GET single patient by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('SELECT * FROM patients WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    res.json({ success: true, data: result.rows[0] });

  } catch (error) {
    console.error('Get single patient error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// POST (Create) a new patient
router.post('/', auth, patientPostValidationRules, async (req, res) => {
  console.log('--- CREATE PATIENT ROUTE HIT ---');
  console.log('Request Body Received:', JSON.stringify(req.body, null, 2));

  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.error('Validation failed:', errors.array());
    return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
  }

  const {
    id, name, age, gender, village, phoneNumber, 
    conditions, medications, nextVisit, isPriority
  } = req.body;
  
  const assignedWorker = req.worker.workerId;

  try {
    console.log('Attempting to insert into database...');
    const newPatient = await db.query(
      `INSERT INTO patients (id, name, age, gender, village, phone_number, assigned_worker, conditions, medications, next_visit, is_priority, sync_status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'synced') RETURNING *`,
      [ id || uuidv4(), name, age, gender, village, phoneNumber, assignedWorker, conditions, medications, nextVisit, isPriority ]
    );
    
    console.log('SUCCESS: Patient inserted into database.');
    res.status(201).json({ success: true, data: newPatient.rows[0] });

  } catch (error) {
    console.error('--- DATABASE INSERT FAILED ---');
    console.error('Error Message:', error.message);
    console.error('Error Detail:', error.detail); // Very important for Postgres errors
    console.error('Error Stack:', error.stack);
    console.error('Request Body:', JSON.stringify(req.body, null, 2));
    res.status(500).json({ success: false, message: 'Internal server error', error: error.message });
  }
});

// PUT (Update) a patient
router.put('/:id', auth, patientPutValidationRules, async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
  }

  const { id } = req.params;
  const updates = req.body;
  const setClauses = [];
  const params = [id];
  let paramCount = 1;

  Object.keys(updates).forEach(key => {
    if (updates[key] !== undefined) {
      paramCount++;
      const dbKey = key.replace(/([A-Z])/g, '_$1').toLowerCase(); // camelCase to snake_case
      setClauses.push(`${dbKey} = $${paramCount}`);
      params.push(updates[key]);
    }
  });

  if (setClauses.length === 0) {
    return res.status(400).json({ success: false, message: 'No valid fields to update' });
  }

  const sqlQuery = `UPDATE patients SET ${setClauses.join(', ')}, updated_at = NOW() WHERE id = $1 RETURNING *`;

  try {
    const result = await db.query(sqlQuery, params);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    res.json({ success: true, message: 'Patient updated', data: result.rows[0] });

  } catch (error) {
    console.error('Update patient error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// DELETE a patient
router.delete('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('DELETE FROM patients WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Patient not found' });
    }
    res.json({ success: true, message: 'Patient deleted' });

  } catch (error) {
    console.error('Delete patient error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

module.exports = router;
