require('dotenv').config();
const db = require('../config/db');

async function migrate() {
    console.log('[MIGRATE] Adding member_emails column to associations table...');

    try {
        await db.query(`
            ALTER TABLE associations
            ADD COLUMN member_emails LONGTEXT DEFAULT NULL AFTER admin_emails;
        `);
        console.log('[MIGRATE] ✅ associations.member_emails column added');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') {
            console.log('[MIGRATE] ⚠️ member_emails column already exists.');
        } else {
            console.error('[MIGRATE] ERROR:', e.message);
            process.exit(1);
        }
    }

    console.log('[MIGRATE] Done.');
    process.exit(0);
}

migrate();
