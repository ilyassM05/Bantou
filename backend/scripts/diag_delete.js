require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const db = require('../config/db');

async function run() {
    const [posts] = await db.execute('SELECT id, user_id FROM posts LIMIT 1');
    if (posts.length === 0) { console.log('No posts.'); process.exit(0); }

    const testId = posts[0].id;
    console.log('Testing DELETE on post id =', testId, '(will rollback via query)');

    // Use db.query (pool) to start tx since the pool supports it
    const conn = await db.getConnection();
    try {
        await conn.query('START TRANSACTION');
        const [r] = await conn.query('DELETE FROM posts WHERE id = ?', [testId]);
        console.log('✔  DELETE succeeded! affectedRows:', r.affectedRows);
        await conn.query('ROLLBACK');
        console.log('✔  Rolled back — post is safe.');
    } catch (e) {
        console.error('✘  DELETE still fails:', e.message);
        await conn.query('ROLLBACK');
    } finally {
        conn.release();
    }

    process.exit(0);
}
run().catch(e => { console.error(e.message); process.exit(1); });
