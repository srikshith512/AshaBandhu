const jwt = require('jsonwebtoken');
const db = require('../config/database');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Verify worker still exists and is active
    const result = await db.query(
      'SELECT worker_id, name, role, is_active FROM workers WHERE worker_id = $1',
      [decoded.workerId]
    );

    if (result.rows.length === 0 || !result.rows[0].is_active) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. Worker not found or inactive.'
      });
    }

    req.worker = result.rows[0];
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token.'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired.'
      });
    }

    console.error('--- AUTH MIDDLEWARE CRASH ---');
    console.error('Error Message:', error.message);
    console.error('Error Stack:', error.stack);
    // If it's a DB error, it might have a 'code' property
    if (error.code) {
      console.error('DB Error Code:', error.code);
    }
    res.status(500).json({
      success: false,
      message: 'Internal server error during authentication.'
    });
  }
};

module.exports = auth;
