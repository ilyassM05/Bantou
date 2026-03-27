require('dotenv').config();
const db = require('../config/db');

async function migrate() {
    try {
        await db.query(`
            CREATE TABLE IF NOT EXISTS circle_photos (
                id INT AUTO_INCREMENT PRIMARY KEY,
                circle_id INT NOT NULL,
                user_id INT NOT NULL,
                photo_url VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (circle_id) REFERENCES circles(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        `);
        console.log('Successfully created circle_photos table.');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

migrate();
