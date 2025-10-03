const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');

const router = express.Router();

// Register worker
router.post('/register', [
  body('workerId').notEmpty().withMessage('Worker ID is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('name').notEmpty().withMessage('Name is required'),
  body('village').notEmpty().withMessage('Village is required'),
  body('role').isIn(['asha', 'phc']).withMessage('Role must be either asha or phc'),
  body('pin').isLength({ min: 4, max: 6 }).withMessage('PIN must be 4-6 digits')
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

    const { workerId, password, name, village, role, pin, phoneNumber } = req.body;

    // Check if worker already exists
    const existingWorker = await db.query(
      'SELECT worker_id FROM workers WHERE worker_id = $1',
      [workerId]
    );

    if (existingWorker.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Worker ID already exists'
      });
    }

    // Hash password and PIN
    const hashedPassword = await bcrypt.hash(password, 12);
    const hashedPin = await bcrypt.hash(pin, 12);

    // Insert new worker
    const result = await db.query(`
      INSERT INTO workers (worker_id, name, village, role, pin, phone_number)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING worker_id, name, village, role, phone_number, is_active, created_at
    `, [workerId, name, village, role, hashedPin, phoneNumber]);

    // Store password separately (in a real app, you might want a separate auth table)
    await db.query(`
      INSERT INTO worker_auth (worker_id, password_hash)
      VALUES ($1, $2)
      ON CONFLICT (worker_id) DO UPDATE SET password_hash = $2
    `, [workerId, hashedPassword]);

    const worker = result.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { workerId: worker.worker_id, role: worker.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.status(201).json({
      success: true,
      message: 'Worker registered successfully',
      data: {
        worker,
        token
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Login worker
router.post('/login', [
  body('workerId').notEmpty().withMessage('Worker ID is required'),
  body('password').notEmpty().withMessage('Password is required')
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

    const { workerId, password } = req.body;

    // Get worker and password
    const workerResult = await db.query(`
      SELECT w.*, wa.password_hash 
      FROM workers w 
      LEFT JOIN worker_auth wa ON w.worker_id = wa.worker_id 
      WHERE w.worker_id = $1 AND w.is_active = true
    `, [workerId]);

    if (workerResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const worker = workerResult.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, worker.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { workerId: worker.worker_id, role: worker.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    // Remove password hash from response
    delete worker.password_hash;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        worker,
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Verify PIN
router.post('/verify-pin', [
  body('workerId').notEmpty().withMessage('Worker ID is required'),
  body('pin').notEmpty().withMessage('PIN is required')
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

    const { workerId, pin } = req.body;

    const result = await db.query(
      'SELECT pin FROM workers WHERE worker_id = $1 AND is_active = true',
      [workerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found'
      });
    }

    const isValidPin = await bcrypt.compare(pin, result.rows[0].pin);

    res.json({
      success: true,
      data: {
        valid: isValidPin
      }
    });
  } catch (error) {
    console.error('PIN verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
