/**
 * Migration: Add member_invitations and circle_members tables.
 * Run once: node scripts/migrate_member_tables.js
 */
require('dotenv').config();
const db = require('../config/db');

async function migrate() {
    console.log('[MIGRATE] Starting member tables migration...');

    // 1. member_invitations
    await db.query(`
        CREATE TABLE IF NOT EXISTS member_invitations (
            id           INT AUTO_INCREMENT PRIMARY KEY,
            association_id INT NOT NULL,
            invited_by   INT NOT NULL,
            invitee_email VARCHAR(255) NOT NULL,
            circle_id    INT DEFAULT NULL,
            token        VARCHAR(600) NOT NULL,
            status       ENUM('pending','accepted','rejected') DEFAULT 'pending',
            created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (association_id) REFERENCES associations(id) ON DELETE CASCADE,
            FOREIGN KEY (invited_by)     REFERENCES users(id)        ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('[MIGRATE] ✅ member_invitations table ready');

    // 2. circle_members
    await db.query(`
        CREATE TABLE IF NOT EXISTS circle_members (
            id        INT AUTO_INCREMENT PRIMARY KEY,
            circle_id INT NOT NULL,
            user_id   INT NOT NULL,
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_membership (circle_id, user_id),
            FOREIGN KEY (circle_id) REFERENCES circles(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);
    console.log('[MIGRATE] ✅ circle_members table ready');

    // 3. Ensure users table has 'member' as a valid role value
    //    (ALTER COLUMN enum is idempotent in MySQL only if using MODIFY COLUMN)
    try {
        await db.query(`
            ALTER TABLE users
            MODIFY COLUMN role ENUM('SA','admin','member') NOT NULL DEFAULT 'SA';
        `);
        console.log('[MIGRATE] ✅ users.role ENUM updated to include member');
    } catch (e) {
        console.warn('[MIGRATE] role ENUM may already include member:', e.message);
    }

    console.log('[MIGRATE] Done.');
    process.exit(0);
}

migrate().catch(err => {
    console.error('[MIGRATE] ERROR:', err);
    process.exit(1);
});
