const db = require('./backend/config/db');

async function migrate() {
    try {
        console.log('Running migration to create circle_access_requests table...');
        await db.query(`
            CREATE TABLE IF NOT EXISTS circle_access_requests (
                id INT AUTO_INCREMENT PRIMARY KEY,
                circle_id INT NOT NULL,
                user_id INT NOT NULL,
                status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (circle_id) REFERENCES circles(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE KEY unique_request (circle_id, user_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        `);
        console.log('Migration successful: Created circle_access_requests table.');
    } catch (e) {
        console.error('Migration failed:', e.message);
    } finally {
        process.exit();
    }
}

migrate();
