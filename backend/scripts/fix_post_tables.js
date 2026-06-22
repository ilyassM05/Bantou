require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mysql = require('mysql2/promise');

async function run() {
    const conn = await mysql.createConnection({
        host: 'localhost', port: 3306, user: 'root', password: '', database: 'bantou'
    });

    // Fix post_likes: add UNIQUE KEY (post_id, user_id)
    try {
        await conn.execute('ALTER TABLE post_likes ADD UNIQUE KEY uq_pl (post_id, user_id)');
        console.log('✔  Fixed post_likes UNIQUE KEY (post_id, user_id)');
    } catch(e) { console.log('⚠  post_likes UNIQUE:', e.message); }

    // Fix post_shares: add shared_by and shared_to columns
    try {
        await conn.execute('ALTER TABLE post_shares ADD COLUMN IF NOT EXISTS shared_by INT NOT NULL DEFAULT 0');
        console.log('✔  Added post_shares.shared_by');
    } catch(e) { console.log('⚠  shared_by:', e.message); }

    try {
        await conn.execute('ALTER TABLE post_shares ADD COLUMN IF NOT EXISTS shared_to INT NOT NULL DEFAULT 0');
        console.log('✔  Added post_shares.shared_to');
    } catch(e) { console.log('⚠  shared_to:', e.message); }

    try {
        await conn.execute('ALTER TABLE post_shares ADD UNIQUE KEY uq_ps (post_id, shared_by, shared_to)');
        console.log('✔  Added post_shares UNIQUE KEY');
    } catch(e) { console.log('⚠  post_shares UNIQUE:', e.message); }

    // Fix association_members: ensure UNIQUE KEY exists
    try {
        const [uk] = await conn.execute(
            "SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA='bantou' AND TABLE_NAME='association_members' AND CONSTRAINT_TYPE='UNIQUE'"
        );
        if (uk.length === 0) {
            await conn.execute('ALTER TABLE association_members ADD UNIQUE KEY uq_am (association_id, user_id)');
            console.log('✔  Added association_members UNIQUE KEY');
        } else {
            console.log('⚠  association_members UNIQUE already exists');
        }
    } catch(e) { console.log('⚠  assoc_members UNIQUE:', e.message); }

    await conn.end();
    console.log('Done.');
}

run().catch(e => { console.error(e.message); process.exit(1); });
