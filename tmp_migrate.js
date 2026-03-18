const db = require('./backend/config/db');

async function migrate() {
    try {
        console.log('Running migration...');
        await db.query('ALTER TABLE circles ADD COLUMN description TEXT');
        console.log('Migration successful: Added description column.');
    } catch (e) {
        if (e.code === 'ER_DUP_FIELDNAME') {
            console.log('Column description already exists.');
        } else {
            console.error('Migration failed:', e.message);
        }
    } finally {
        process.exit();
    }
}

migrate();
