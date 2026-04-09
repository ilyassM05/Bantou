const db = require('../config/db');

async function migrate() {
    try {
        // 1. Create post_likes table
        await db.query(`
            CREATE TABLE IF NOT EXISTS post_likes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                post_id INT NOT NULL,
                user_id INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY unique_like (post_id, user_id),
                FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        `);
        console.log('✔  post_likes table created.');

        // 2. Add privacy_level column to users (idempotent)
        await db.query(`
            ALTER TABLE users
            ADD COLUMN IF NOT EXISTS privacy_level ENUM('public','association','private') NOT NULL DEFAULT 'association';
        `);
        console.log('✔  privacy_level column added to users.');

        process.exit(0);
    } catch (err) {
        console.error('Migration error:', err);
        process.exit(1);
    }
}

migrate();
