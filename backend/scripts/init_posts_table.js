const db = require('../config/db');

async function createPostsTable() {
    try {
        await db.query(`
            CREATE TABLE IF NOT EXISTS posts (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                association_id INT NOT NULL,
                content TEXT NOT NULL,
                image_url VARCHAR(255) DEFAULT NULL,
                likes_count INT DEFAULT 0,
                comments_count INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (association_id) REFERENCES associations(id) ON DELETE CASCADE
            );
        `);
        console.log('Successfully created posts table.');
        process.exit(0);
    } catch (err) {
        console.error('Error creating posts table:', err);
        process.exit(1);
    }
}

createPostsTable();
