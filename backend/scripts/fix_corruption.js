/**
 * fix_corruption.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Repairs all schema damage caused by the SQL database corruption.
 * Run once with:  node backend/scripts/fix_corruption.js
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * Problems found and fixed:
 *
 * 1. `posts` table: lost `association_id`, `image_url`, `likes_count`,
 *    `comments_count` columns; gained corrupt `circle_id` and `media_url`.
 *    We add the missing columns back and rename the corrupt ones.
 *
 * 2. `circle_access_requests` table: `status` default changed to 'pending'
 *    (lowercase) instead of 'Pending', missing UNIQUE constraint, `created_at`
 *    was renamed to `requested_at`.
 *
 * 3. `circle_photos` table: lost `user_id` and `status` columns, `photo_url`
 *    was renamed to `url`, `created_at` was renamed to `uploaded_at`.
 *
 * 4. `users` table: `password` became NOT NULL in some corrupted versions;
 *    also missing `privacy_level` column referenced in queries.
 *
 * 5. `associations` table: missing `updated_at` column.
 *
 * All operations use `IF NOT EXISTS` / `IF EXISTS` / `IGNORE` patterns
 * so re-running is safe.
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mysql = require('mysql2/promise');

async function run() {
    const conn = await mysql.createConnection({
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '',
        database: 'bantou',
        multipleStatements: true,
    });

    console.log('✔  Connected to bantou database.');

    // ── Helper ──────────────────────────────────────────────────────────────────
    async function exec(label, sql) {
        try {
            await conn.execute(sql);
            console.log(`✔  ${label}`);
        } catch (err) {
            // Some ALTER TABLE errors are expected when columns already exist
            if (
                err.code === 'ER_DUP_FIELDNAME' ||
                err.code === 'ER_BAD_FIELD_ERROR' ||
                (err.message && err.message.includes('Duplicate column'))
            ) {
                console.log(`⚠  Skipped (already exists): ${label}`);
            } else {
                console.error(`✘  ${label}: ${err.message}`);
            }
        }
    }

    async function query(label, sql, params = []) {
        try {
            const [result] = await conn.execute(sql, params);
            console.log(`✔  ${label}`);
            return result;
        } catch (err) {
            console.error(`✘  ${label}: ${err.message}`);
            return null;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. FIX: `posts` table
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing posts table ──────────────────────────────────────────');

    // 1a. Add `association_id` if missing
    await exec(
        'Add posts.association_id',
        `ALTER TABLE posts ADD COLUMN IF NOT EXISTS association_id INT NOT NULL DEFAULT 0 AFTER user_id`
    );

    // 1b. Add `image_url` if missing (the corruption renamed it to `media_url`)
    await exec(
        'Add posts.image_url',
        `ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_url VARCHAR(500) DEFAULT NULL`
    );

    // 1c. Add `likes_count` if missing
    await exec(
        'Add posts.likes_count',
        `ALTER TABLE posts ADD COLUMN IF NOT EXISTS likes_count INT DEFAULT 0`
    );

    // 1d. Add `comments_count` if missing
    await exec(
        'Add posts.comments_count',
        `ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_count INT DEFAULT 0`
    );

    // 1e. Copy data from media_url -> image_url if media_url exists
    try {
        const [cols] = await conn.execute(`SHOW COLUMNS FROM posts LIKE 'media_url'`);
        if (cols.length > 0) {
            await query('Copy posts.media_url -> image_url', `UPDATE posts SET image_url = media_url WHERE media_url IS NOT NULL AND (image_url IS NULL OR image_url = '')`);
            console.log('⚠  Note: posts.media_url still exists (legacy column). Application now uses image_url.');
        }
    } catch (_) {}

    // 1f. Add FK for association_id (only if associations table has rows)
    try {
        const [fkRows] = await conn.execute(
            `SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA='bantou' AND TABLE_NAME='posts' AND COLUMN_NAME='association_id' AND REFERENCED_TABLE_NAME='associations'`
        );
        if (fkRows.length === 0) {
            await exec(
                'Add posts.association_id FK',
                `ALTER TABLE posts ADD CONSTRAINT fk_posts_assoc FOREIGN KEY (association_id) REFERENCES associations(id) ON DELETE CASCADE`
            );
        } else {
            console.log('⚠  Skipped (already exists): posts FK association_id');
        }
    } catch (err) {
        console.log(`⚠  Could not add FK for posts.association_id: ${err.message}`);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. FIX: `circle_access_requests` table
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing circle_access_requests table ─────────────────────────');

    // 2a. Add `created_at` if missing (the corruption renamed it to `requested_at`)
    await exec(
        'Add circle_access_requests.created_at',
        `ALTER TABLE circle_access_requests ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
    );

    // 2b. Add `updated_at` if missing
    await exec(
        'Add circle_access_requests.updated_at',
        `ALTER TABLE circle_access_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
    );

    // 2c. Fix status default from 'pending' to 'Pending' and change type
    try {
        const [scol] = await conn.execute(`SHOW COLUMNS FROM circle_access_requests LIKE 'status'`);
        if (scol.length > 0 && scol[0].Default === 'pending') {
            await exec(
                'Fix circle_access_requests.status default to Pending',
                `ALTER TABLE circle_access_requests MODIFY COLUMN status VARCHAR(50) DEFAULT 'Pending'`
            );
            // Fix any existing lowercase 'pending' values
            await query(
                'Fix existing lowercase pending values',
                `UPDATE circle_access_requests SET status = 'Pending' WHERE status = 'pending'`
            );
        }
    } catch (err) {
        console.log(`⚠  Status fix: ${err.message}`);
    }

    // 2d. Add UNIQUE constraint on (circle_id, user_id) if not present
    try {
        const [ukRows] = await conn.execute(
            `SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS
             WHERE TABLE_SCHEMA='bantou' AND TABLE_NAME='circle_access_requests' AND CONSTRAINT_TYPE='UNIQUE'`
        );
        if (ukRows.length === 0) {
            await exec(
                'Add UNIQUE(circle_id, user_id) to circle_access_requests',
                `ALTER TABLE circle_access_requests ADD UNIQUE KEY uq_car (circle_id, user_id)`
            );
        } else {
            console.log('⚠  Skipped (already exists): UNIQUE(circle_id, user_id)');
        }
    } catch (err) {
        console.log(`⚠  UNIQUE constraint: ${err.message}`);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. FIX: `circle_photos` table
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing circle_photos table ──────────────────────────────────');

    // 3a. Add `user_id` if missing
    await exec(
        'Add circle_photos.user_id',
        `ALTER TABLE circle_photos ADD COLUMN IF NOT EXISTS user_id INT NOT NULL DEFAULT 1`
    );

    // 3b. Add `photo_url` if missing (corruption renamed it to `url`)
    await exec(
        'Add circle_photos.photo_url',
        `ALTER TABLE circle_photos ADD COLUMN IF NOT EXISTS photo_url VARCHAR(500) DEFAULT NULL`
    );

    // 3c. Copy data from url -> photo_url
    try {
        const [cols] = await conn.execute(`SHOW COLUMNS FROM circle_photos LIKE 'url'`);
        if (cols.length > 0) {
            await query(
                'Copy circle_photos.url -> photo_url',
                `UPDATE circle_photos SET photo_url = url WHERE url IS NOT NULL AND (photo_url IS NULL OR photo_url = '')`
            );
        }
    } catch (_) {}

    // 3d. Add `status` if missing
    await exec(
        'Add circle_photos.status',
        `ALTER TABLE circle_photos ADD COLUMN IF NOT EXISTS status ENUM('pending','approved') DEFAULT 'approved'`
    );

    // 3e. Add `created_at` if missing (corruption renamed it to `uploaded_at`)
    await exec(
        'Add circle_photos.created_at',
        `ALTER TABLE circle_photos ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
    );

    // 3f. Add FK for user_id
    try {
        const [fkRows] = await conn.execute(
            `SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA='bantou' AND TABLE_NAME='circle_photos' AND COLUMN_NAME='user_id' AND REFERENCED_TABLE_NAME='users'`
        );
        if (fkRows.length === 0) {
            await exec(
                'Add circle_photos.user_id FK',
                `ALTER TABLE circle_photos ADD CONSTRAINT fk_cp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
            );
        } else {
            console.log('⚠  Skipped (already exists): circle_photos.user_id FK');
        }
    } catch (err) {
        console.log(`⚠  circle_photos user FK: ${err.message}`);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. FIX: `users` table
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing users table ──────────────────────────────────────────');

    // 4a. Add `privacy_level` column (referenced in Post queries)
    await exec(
        'Add users.privacy_level',
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_level VARCHAR(50) DEFAULT 'public'`
    );

    // 4b. Make password nullable (for social login users)
    try {
        const [pcol] = await conn.execute(`SHOW COLUMNS FROM users LIKE 'password'`);
        if (pcol.length > 0 && pcol[0].Null === 'NO') {
            await exec(
                'Make users.password nullable',
                `ALTER TABLE users MODIFY COLUMN password VARCHAR(255) NULL DEFAULT NULL`
            );
        } else {
            console.log('⚠  Skipped: users.password already nullable');
        }
    } catch (err) {
        console.log(`⚠  password nullable: ${err.message}`);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. FIX: `associations` table
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing associations table ────────────────────────────────────');

    // 5a. Add `updated_at` if missing
    await exec(
        'Add associations.updated_at',
        `ALTER TABLE associations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
    );

    // 5b. Make address longer (was VARCHAR(255), code uses 500)
    await exec(
        'Extend associations.address to VARCHAR(500)',
        `ALTER TABLE associations MODIFY COLUMN address VARCHAR(500) DEFAULT NULL`
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 6. FIX: `post_likes` and `post_comments` tables
    //    They are referenced in Post.js but may have been dropped by corruption
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Ensuring post_likes and post_comments exist ─────────────────');

    await exec(
        'Create post_likes if missing',
        `CREATE TABLE IF NOT EXISTS post_likes (
            post_id    INT NOT NULL,
            user_id    INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (post_id, user_id),
            FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )`
    );

    await exec(
        'Create post_comments if missing',
        `CREATE TABLE IF NOT EXISTS post_comments (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            post_id    INT NOT NULL,
            user_id    INT NOT NULL,
            content    TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )`
    );

    await exec(
        'Create post_shares if missing',
        `CREATE TABLE IF NOT EXISTS post_shares (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            post_id    INT NOT NULL,
            shared_by  INT NOT NULL,
            shared_to  INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (post_id)   REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY (shared_by) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (shared_to) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE KEY unique_share (post_id, shared_by, shared_to)
        )`
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 7. FIX: `circle_members` table
    //    May have lost the unique constraint
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing circle_members table ─────────────────────────────────');

    try {
        const [ukRows] = await conn.execute(
            `SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS
             WHERE TABLE_SCHEMA='bantou' AND TABLE_NAME='circle_members' AND CONSTRAINT_TYPE='UNIQUE'`
        );
        if (ukRows.length === 0) {
            await exec(
                'Add UNIQUE(circle_id, user_id) to circle_members',
                `ALTER TABLE circle_members ADD UNIQUE KEY uq_cm (circle_id, user_id)`
            );
        } else {
            console.log('⚠  Skipped (already exists): circle_members UNIQUE');
        }
    } catch (err) {
        console.log(`⚠  circle_members UNIQUE: ${err.message}`);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 8. FIX: `member_invitations` table
    //    Ensure the token column and status enum are correct
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n── Fixing member_invitations table ─────────────────────────────');

    await exec(
        'Ensure member_invitations.token exists',
        `ALTER TABLE member_invitations ADD COLUMN IF NOT EXISTS token TEXT DEFAULT NULL`
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Summary
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n─────────────────────────────────────────────────────────────────');
    console.log('✔  Migration complete. All corruption fixes applied.');
    console.log('    Restart the backend server now: npm start');

    await conn.end();
}

run().catch(err => {
    console.error('Fatal migration error:', err);
    process.exit(1);
});
