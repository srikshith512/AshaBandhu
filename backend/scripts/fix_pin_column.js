const db = require('../config/database');

async function fixPinColumn() {
  try {
    console.log('🔄 Fixing PIN column size...');
    
    await db.query(`
      ALTER TABLE workers ALTER COLUMN pin TYPE VARCHAR(255);
    `);
    
    console.log('✅ PIN column fixed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error fixing PIN column:', error);
    process.exit(1);
  }
}

fixPinColumn();
