/**
 * Migration: create post_comments and post_shares tables.
 * Run once:  node scripts/init_comments_shares_tables.js
 */
const db = require('../config/db');

async function migrate() {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // ── post_comments ─────────────────────────────────────────────────
        await connection.query(`
            CREATE TABLE IF NOT EXISTS post_comments (
                id          INT AUTO_INCREMENT PRIMARY KEY,
                post_id     INT NOT NULL,
                user_id     INT NOT NULL,
                content     TEXT NOT NULL,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (post_id)  REFERENCES posts(id)  ON DELETE CASCADE,
                FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE
            )
        `);
        console.log('✅  post_comments table ready.');

        // ── post_shares ───────────────────────────────────────────────────
        await connection.query(`
            CREATE TABLE IF NOT EXISTS post_shares (
                id          INT AUTO_INCREMENT PRIMARY KEY,
                post_id     INT NOT NULL,
                shared_by   INT NOT NULL,
                shared_to   INT NOT NULL,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (post_id)   REFERENCES posts(id)  ON DELETE CASCADE,
                FOREIGN KEY (shared_by) REFERENCES users(id)  ON DELETE CASCADE,
                FOREIGN KEY (shared_to) REFERENCES users(id)  ON DELETE CASCADE,
                UNIQUE KEY unique_share (post_id, shared_by, shared_to)
            )
        `);
        console.log('✅  post_shares table ready.');

        await connection.commit();
        console.log('🎉  Migration completed successfully.');
    } catch (err) {
        await connection.rollback();
        console.error('❌  Migration failed:', err.message);
        process.exit(1);
    } finally {
        connection.release();
        process.exit(0);
    }
}

migrate();
