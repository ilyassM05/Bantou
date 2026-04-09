/**
 * Migration: Add profile_picture column to users table
 * Run once: node backend/scripts/add_profile_picture.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const db = require('../config/db');

async function run() {
    try {
        // Check if column already exists
        const [cols] = await db.query(`
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'users' 
              AND COLUMN_NAME = 'profile_picture'
        `);

        if (cols.length > 0) {
            console.log('✔  Column profile_picture already exists — nothing to do.');
        } else {
            await db.query(`
                ALTER TABLE users 
                ADD COLUMN profile_picture VARCHAR(255) NULL DEFAULT NULL
                AFTER avatar_index
            `);
            console.log('✔  Added profile_picture column to users table.');
        }

        // Also add association logo column to associations if it doesn't have one
        const [assocCols] = await db.query(`
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'associations' 
              AND COLUMN_NAME = 'logo'
        `);
        if (assocCols.length > 0) {
            console.log('✔  Column logo already exists on associations — nothing to do.');
        } else {
            await db.query(`
                ALTER TABLE associations 
                ADD COLUMN logo VARCHAR(255) NULL DEFAULT NULL
            `);
            console.log('✔  Added logo column to associations table.');
        }

        // Seed a mock profile picture for the first user (for testing)
        const [users] = await db.query('SELECT id FROM users ORDER BY id LIMIT 1');
        if (users.length > 0) {
            await db.query(
                'UPDATE users SET profile_picture = ? WHERE id = ? AND profile_picture IS NULL',
                ['/uploads/profiles/mock_profile.jpg', users[0].id]
            );
            console.log(`✔  Mock profile picture seeded for user id=${users[0].id}`);
        }

        // Seed a mock association logo for the first association (for testing)
        const [assocs] = await db.query('SELECT id FROM associations ORDER BY id LIMIT 1');
        if (assocs.length > 0) {
            await db.query(
                'UPDATE associations SET logo = ? WHERE id = ? AND (logo IS NULL OR logo = "")',
                ['/uploads/profiles/mock_logo.png', assocs[0].id]
            );
            console.log(`✔  Mock association logo seeded for association id=${assocs[0].id}`);
        }

        console.log('\n✔  Migration complete.');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

run();
