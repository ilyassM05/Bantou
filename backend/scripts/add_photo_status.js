/**
 * Migration: add `status` column to `circle_photos`
 *
 * Run once:  node backend/scripts/add_photo_status.js
 *
 * - Adds ENUM('pending','approved','rejected') DEFAULT 'pending'
 * - Back-fills all existing rows to 'approved' (backward-compatible)
 */

const db = require('../config/db');

async function run() {
    console.log('▶  Starting migration: add_photo_status …');

    try {
        // 1. Add the column (ignore error if it already exists)
        await db.query(`
            ALTER TABLE circle_photos
            ADD COLUMN status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending'
        `);
        console.log('✅  Column `status` added to circle_photos.');
    } catch (err) {
        if (err.code === 'ER_DUP_FIELDNAME') {
            console.log('ℹ️   Column `status` already exists — skipping ALTER.');
        } else {
            throw err;
        }
    }

    // 2. Back-fill existing rows so nothing breaks
    const [result] = await db.query(
        `UPDATE circle_photos SET status = 'approved' WHERE status = 'pending'`
    );
    console.log(`✅  Back-filled ${result.affectedRows} existing photo(s) → 'approved'.`);

    console.log('🎉  Migration complete.');
    process.exit(0);
}

run().catch(err => {
    console.error('❌  Migration failed:', err);
    process.exit(1);
});
