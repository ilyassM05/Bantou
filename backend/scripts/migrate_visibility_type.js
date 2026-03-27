/**
 * Migration: Add visibility_type to circles table.
 * Run once: node scripts/migrate_visibility_type.js
 */
require('dotenv').config();
const db = require('../config/db');

async function migrate() {
    console.log('[MIGRATE] Starting visibility_type migration...');

    try {
        await db.query(`
            ALTER TABLE circles
            ADD COLUMN visibility_type ENUM('Public', 'Private') NOT NULL DEFAULT 'Public'
        `);
        console.log('[MIGRATE] ✅ visibility_type added to circles table');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') {
            console.warn('[MIGRATE] visibility_type already exists on circles table. Skipping.');
        } else {
            console.error('[MIGRATE] Error adding visibility_type:', e.message);
            process.exit(1);
        }
    }

    console.log('[MIGRATE] Done.');
    process.exit(0);
}

migrate().catch(err => {
    console.error('[MIGRATE] ERROR:', err);
    process.exit(1);
});
