const express = require('express');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const auth = require('../middleware/auth');

const router = express.Router();

// Get worker profile
router.get('/profile', auth, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT worker_id, name, village, role, phone_number, is_active, created_at FROM workers WHERE worker_id = $1',
      [req.worker.worker_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found'
      });
    }

    res.json({
      success: true,
      data: {
        worker: result.rows[0]
      }
    });
  } catch (error) {
    console.error('Get worker profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update worker profile
router.put('/profile', auth, [
  body('name').optional().notEmpty().withMessage('Name cannot be empty'),
  body('village').optional().notEmpty().withMessage('Village cannot be empty'),
  body('phoneNumber').optional().isMobilePhone().withMessage('Invalid phone number')
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

    const { name, village, phoneNumber } = req.body;
    const updates = {};
    
    if (name) updates.name = name;
    if (village) updates.village = village;
    if (phoneNumber) updates.phone_number = phoneNumber;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    const setClause = Object.keys(updates).map((key, index) => `${key} = $${index + 2}`).join(', ');
    const values = [req.worker.worker_id, ...Object.values(updates)];

    const result = await db.query(`
      UPDATE workers 
      SET ${setClause}
      WHERE worker_id = $1 
      RETURNING worker_id, name, village, role, phone_number, is_active, created_at
    `, values);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        worker: result.rows[0]
      }
    });
  } catch (error) {
    console.error('Update worker profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get all workers (PHC only)
router.get('/', auth, async (req, res) => {
  try {
    // Only PHC workers can view all workers
    if (req.worker.role !== 'phc') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. PHC role required.'
      });
    }

    const result = await db.query(`
      SELECT worker_id, name, village, role, phone_number, is_active, created_at 
      FROM workers 
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      data: {
        workers: result.rows,
        total: result.rows.length
      }
    });
  } catch (error) {
    console.error('Get workers error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
