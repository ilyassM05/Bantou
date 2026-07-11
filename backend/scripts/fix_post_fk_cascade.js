/**
 * fix_post_fk_cascade.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Fixes the missing ON DELETE CASCADE on post_comments, post_likes, and
 * post_shares foreign keys that reference posts(id).
 *
 * The existing FKs block post deletion when related records exist.
 * This script drops the old FKs and re-creates them with ON DELETE CASCADE.
 *
 * Run once: node backend/scripts/fix_post_fk_cascade.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mysql = require('mysql2/promise');

async function run() {
    const conn = await mysql.createConnection({
        host: 'localhost', port: 3306, user: 'root', password: '', database: 'bantou'
    });
    console.log('Connected to bantou database.\n');

    // Helper: drop FK if it exists, then recreate with CASCADE
    async function fixFk(table, constraintName, column, refTable, refColumn) {
        // Drop old constraint
        try {
            await conn.execute(`ALTER TABLE \`${table}\` DROP FOREIGN KEY \`${constraintName}\``);
            console.log(`✔  Dropped FK ${constraintName} from ${table}`);
        } catch (e) {
            console.log(`⚠  Could not drop ${constraintName}: ${e.message}`);
        }

        // Re-add with CASCADE
        try {
            await conn.execute(`
                ALTER TABLE \`${table}\`
                ADD CONSTRAINT \`${constraintName}\`
                FOREIGN KEY (\`${column}\`)
                REFERENCES \`${refTable}\`(\`${refColumn}\`)
                ON DELETE CASCADE
            `);
            console.log(`✔  Re-created FK ${constraintName} with ON DELETE CASCADE`);
        } catch (e) {
            console.error(`✘  Failed to re-create ${constraintName}: ${e.message}`);
        }
    }

    console.log('=== Fixing post_comments FK ===');
    await fixFk('post_comments', 'pc_ibfk_1', 'post_id', 'posts', 'id');

    console.log('\n=== Fixing post_likes FK ===');
    await fixFk('post_likes', 'pl_ibfk_1', 'post_id', 'posts', 'id');

    console.log('\n=== Fixing post_shares FK ===');
    await fixFk('post_shares', 'ps_ibfk_1', 'post_id', 'posts', 'id');

    // Verify by running a test DELETE (rollback)
    console.log('\n=== Verification: test DELETE with rollback ===');
    const [posts] = await conn.execute('SELECT id FROM posts LIMIT 1');
    if (posts.length > 0) {
        const testId = posts[0].id;
        try {
            await conn.execute('START TRANSACTION');
            const [r] = await conn.execute('DELETE FROM posts WHERE id = ?', [testId]);
            console.log(`✔  Test DELETE succeeded (affectedRows: ${r.affectedRows}) — rolling back`);
            await conn.execute('ROLLBACK');
        } catch (e) {
            console.error('✘  Test DELETE still fails:', e.message);
            await conn.execute('ROLLBACK');
        }
    } else {
        console.log('  No posts to test with.');
    }

    await conn.end();
    console.log('\nDone. Restart the backend server: npm start');
}

run().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
