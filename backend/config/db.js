require('dotenv').config();
const mysql = require('mysql2');

// Auto-create database and table on first run
const bootstrap = mysql.createConnection({
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '',
});

bootstrap.connect((err) => {
    if (err) { console.error('DB bootstrap connection error:', err); return; }

    bootstrap.query('CREATE DATABASE IF NOT EXISTS bantou', (err) => {
        if (err) { console.error('Error creating database:', err); return; }
        console.log('✔  Database `bantou` ready.');

        bootstrap.query('USE bantou', (err) => {
            if (err) { console.error('Error selecting database:', err); return; }

            const createUsers = `
        CREATE TABLE IF NOT EXISTS users (
          id          INT AUTO_INCREMENT PRIMARY KEY,
          name        VARCHAR(255) NOT NULL,
          email       VARCHAR(255) NOT NULL UNIQUE,
          phone       VARCHAR(50),
          password    VARCHAR(255),
          google_id   VARCHAR(255) UNIQUE,
          role        VARCHAR(50)  DEFAULT 'SA',
          status      ENUM('actif','inactif','en attente','archivé','supprimé') DEFAULT 'en attente',
          otp_code        VARCHAR(6)   DEFAULT NULL,
          otp_expires_at  DATETIME     DEFAULT NULL,
          created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        )
      `;

            bootstrap.query(createUsers, (err) => {
                if (err) { console.error('Error creating users table:', err); bootstrap.end(); return; }
                console.log('✔  Table `users` ready.');

                const alterOtp = `
                    ALTER TABLE users
                    ADD COLUMN IF NOT EXISTS otp_code       VARCHAR(6)  DEFAULT NULL,
                    ADD COLUMN IF NOT EXISTS otp_expires_at DATETIME    DEFAULT NULL
                `;
                bootstrap.query(alterOtp, (err) => {
                    if (err) console.error('Error adding OTP columns:', err);
                    else console.log('✔  OTP columns ready.');

                    const alterFacebook = `
                        ALTER TABLE users
                        ADD COLUMN IF NOT EXISTS facebook_id VARCHAR(255) UNIQUE DEFAULT NULL
                    `;
                    bootstrap.query(alterFacebook, (err) => {
                        if (err) console.error('Error adding facebook_id column:', err);
                        else console.log('✔  facebook_id column ready.');

                        const alterProfile = `
                            ALTER TABLE users
                            ADD COLUMN IF NOT EXISTS company        VARCHAR(255)  DEFAULT NULL,
                            ADD COLUMN IF NOT EXISTS job_title      VARCHAR(255)  DEFAULT NULL,
                            ADD COLUMN IF NOT EXISTS community_role VARCHAR(255)  DEFAULT NULL,
                            ADD COLUMN IF NOT EXISTS city           VARCHAR(255)  DEFAULT NULL,
                            ADD COLUMN IF NOT EXISTS bio            TEXT          DEFAULT NULL,
                            ADD COLUMN IF NOT EXISTS website        VARCHAR(255)  DEFAULT NULL,
                            ADD COLUMN IF NOT EXISTS avatar_index   INT           DEFAULT 0
                        `;
                        bootstrap.query(alterProfile, (err) => {
                            if (err) console.error('Error adding profile columns:', err);
                            else console.log('✔  Profile columns ready.');

                            const alterSetupSeen = `
                                ALTER TABLE users
                                ADD COLUMN IF NOT EXISTS profile_setup_seen TINYINT(1) NOT NULL DEFAULT 0
                            `;
                            bootstrap.query(alterSetupSeen, (err) => {
                                if (err) console.error('Error adding profile_setup_seen column:', err);
                                else console.log('✔  profile_setup_seen column ready.');

                                // ── onboarding_seen flag ────────────────────
                                const alterOnboarding = `
                                    ALTER TABLE users
                                    ADD COLUMN IF NOT EXISTS onboarding_seen TINYINT(1) NOT NULL DEFAULT 0
                                `;
                                bootstrap.query(alterOnboarding, (err) => {
                                    if (err) console.error('Error adding onboarding_seen column:', err);
                                    else console.log('✔  onboarding_seen column ready.');

                                    // ── associations table ──────────────────
                                    const createAssociations = `
                                        CREATE TABLE IF NOT EXISTS associations (
                                            id             INT AUTO_INCREMENT PRIMARY KEY,
                                            creator_id     INT NOT NULL UNIQUE,
                                            name           VARCHAR(255) NOT NULL,
                                            address        VARCHAR(500)  DEFAULT NULL,
                                            logo           VARCHAR(500)  DEFAULT NULL,
                                            contact_emails JSON          DEFAULT NULL,
                                            contact_phones JSON          DEFAULT NULL,
                                            admin_emails   JSON          DEFAULT NULL,
                                            fb_link        VARCHAR(500)  DEFAULT NULL,
                                            linkedin_link  VARCHAR(500)  DEFAULT NULL,
                                            twitter_link   VARCHAR(500)  DEFAULT NULL,
                                            created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                            updated_at     TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                            FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE
                                        )
                                    `;
                                    bootstrap.query(createAssociations, (err) => {
                                        if (err) {
                                            console.error('Error creating associations table:', err);
                                        } else {
                                            console.log('✔  Table `associations` ready.');
                                        }

                                        const createCircles = `
                                            CREATE TABLE IF NOT EXISTS circles (
                                                id                 INT AUTO_INCREMENT PRIMARY KEY,
                                                association_id     INT NOT NULL,
                                                created_by         INT NOT NULL,
                                                name               VARCHAR(255) NOT NULL,
                                                country            VARCHAR(100) NOT NULL,
                                                city               VARCHAR(100) NOT NULL,
                                                responsible        VARCHAR(255) NOT NULL,
                                                vice_responsible   VARCHAR(255) NOT NULL,
                                                meeting_planning   VARCHAR(255) NOT NULL,
                                                status             ENUM('Active', 'Inactive') DEFAULT 'Active',
                                                created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                FOREIGN KEY (association_id) REFERENCES associations(id) ON DELETE CASCADE,
                                                FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
                                            )
                                        `;
                                        bootstrap.query(createCircles, (err) => {
                                            if (err) { console.error('Error creating circles table:', err); bootstrap.end(); return; }
                                            console.log('✔  Table `circles` ready.');

                                            const createMembers = `
                                                CREATE TABLE IF NOT EXISTS association_members (
                                                    id             INT AUTO_INCREMENT PRIMARY KEY,
                                                    association_id INT NOT NULL,
                                                    user_id        INT NOT NULL,
                                                    joined_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                    UNIQUE KEY (association_id, user_id),
                                                    FOREIGN KEY (association_id) REFERENCES associations(id) ON DELETE CASCADE,
                                                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                                                )
                                            `;
                                            bootstrap.query(createMembers, (err) => {
                                                if (err) { console.error('Error creating association_members table:', err); bootstrap.end(); return; }
                                                console.log('✔  Table `association_members` ready.');

                                                const createMeetings = `
                                                    CREATE TABLE IF NOT EXISTS meetings (
                                                        id             INT AUTO_INCREMENT PRIMARY KEY,
                                                        circle_id      INT NOT NULL,
                                                        title          VARCHAR(255) NOT NULL,
                                                        date           DATETIME NOT NULL,
                                                        end_time       DATETIME DEFAULT NULL,
                                                        created_by     INT NOT NULL,
                                                        created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                        FOREIGN KEY (circle_id) REFERENCES circles(id) ON DELETE CASCADE,
                                                        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
                                                    )
                                                `;
                                                bootstrap.query(createMeetings, (err) => {
                                                    if (err) { console.error('Error creating meetings table:', err); bootstrap.end(); return; }
                                                    console.log('✔  Table `meetings` ready.');

                                                    const createPosts = `
                                                        CREATE TABLE IF NOT EXISTS posts (
                                                            id             INT AUTO_INCREMENT PRIMARY KEY,
                                                            user_id        INT NOT NULL,
                                                            association_id INT NOT NULL,
                                                            content        TEXT,
                                                            image_url      VARCHAR(500) DEFAULT NULL,
                                                            likes_count    INT DEFAULT 0,
                                                            comments_count INT DEFAULT 0,
                                                            created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                                                            FOREIGN KEY (association_id) REFERENCES associations(id) ON DELETE CASCADE
                                                        )
                                                    `;
                                                    bootstrap.query(createPosts, (err) => {
                                                        if (err) console.error('Error creating posts table:', err);
                                                        else console.log('✔  Table `posts` ready.');

                                                        // ── post_likes ──────────────────────────
                                                        const createPostLikes = `
                                                            CREATE TABLE IF NOT EXISTS post_likes (
                                                                post_id    INT NOT NULL,
                                                                user_id    INT NOT NULL,
                                                                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                PRIMARY KEY (post_id, user_id),
                                                                FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
                                                                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                                                            )
                                                        `;
                                                        bootstrap.query(createPostLikes, (err) => {
                                                            if (err) console.error('Error creating post_likes table:', err);
                                                            else console.log('✔  Table `post_likes` ready.');

                                                            // ── post_comments ────────────────────
                                                            const createPostComments = `
                                                                CREATE TABLE IF NOT EXISTS post_comments (
                                                                    id         INT AUTO_INCREMENT PRIMARY KEY,
                                                                    post_id    INT NOT NULL,
                                                                    user_id    INT NOT NULL,
                                                                    content    TEXT NOT NULL,
                                                                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
                                                                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                                                                )
                                                            `;
                                                            bootstrap.query(createPostComments, (err) => {
                                                                if (err) console.error('Error creating post_comments table:', err);
                                                                else console.log('✔  Table `post_comments` ready.');

                                                                // ── post_shares ──────────────────
                                                                const createPostShares = `
                                                                    CREATE TABLE IF NOT EXISTS post_shares (
                                                                        id         INT AUTO_INCREMENT PRIMARY KEY,
                                                                        post_id    INT NOT NULL,
                                                                        shared_by  INT NOT NULL,
                                                                        shared_to  INT NOT NULL,
                                                                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                        FOREIGN KEY (post_id)   REFERENCES posts(id) ON DELETE CASCADE,
                                                                        FOREIGN KEY (shared_by) REFERENCES users(id) ON DELETE CASCADE,
                                                                        FOREIGN KEY (shared_to) REFERENCES users(id) ON DELETE CASCADE,
                                                                        UNIQUE KEY unique_share (post_id, shared_by, shared_to)
                                                                    )
                                                                `;
                                                                bootstrap.query(createPostShares, (err) => {
                                                                    if (err) console.error('Error creating post_shares table:', err);
                                                                    else console.log('✔  Table `post_shares` ready.');

                                                                    // ── chat_invitations ─────────────────────
                                                                    const createChatInvitations = `
                                                                        CREATE TABLE IF NOT EXISTS chat_invitations (
                                                                            id          INT AUTO_INCREMENT PRIMARY KEY,
                                                                            sender_id   INT NOT NULL,
                                                                            receiver_id INT NOT NULL,
                                                                            status      ENUM('pending','accepted','declined') DEFAULT 'pending',
                                                                            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                                                            UNIQUE KEY unique_inv (sender_id, receiver_id),
                                                                            FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
                                                                            FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
                                                                        )
                                                                    `;
                                                                    bootstrap.query(createChatInvitations, (err) => {
                                                                        if (err) console.error('Error creating chat_invitations table:', err);
                                                                        else console.log('✔  Table `chat_invitations` ready.');

                                                                        const createConversations = `
                                                                            CREATE TABLE IF NOT EXISTS conversations (
                                                                                id         INT AUTO_INCREMENT PRIMARY KEY,
                                                                                type       ENUM('private','group') DEFAULT 'private',
                                                                                name       VARCHAR(255) DEFAULT NULL,
                                                                                image_url  VARCHAR(500) DEFAULT NULL,
                                                                                created_by INT NOT NULL,
                                                                                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                                FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
                                                                            )
                                                                        `;
                                                                        bootstrap.query(createConversations, (err) => {
                                                                            if (err) console.error('Error creating conversations table:', err);
                                                                            else console.log('✔  Table `conversations` ready.');

                                                                            const createConvMembers = `
                                                                                CREATE TABLE IF NOT EXISTS conversation_members (
                                                                                    id              INT AUTO_INCREMENT PRIMARY KEY,
                                                                                    conversation_id INT NOT NULL,
                                                                                    user_id         INT NOT NULL,
                                                                                    role            ENUM('admin','member') DEFAULT 'member',
                                                                                    joined_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                                    UNIQUE KEY uq_conv_user (conversation_id, user_id),
                                                                                    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
                                                                                    FOREIGN KEY (user_id)         REFERENCES users(id) ON DELETE CASCADE
                                                                                )
                                                                            `;
                                                                            bootstrap.query(createConvMembers, (err) => {
                                                                                if (err) console.error('Error creating conversation_members table:', err);
                                                                                else console.log('✔  Table `conversation_members` ready.');

                                                                                const createMessages = `
                                                                                    CREATE TABLE IF NOT EXISTS messages (
                                                                                        id              INT AUTO_INCREMENT PRIMARY KEY,
                                                                                        conversation_id INT NOT NULL,
                                                                                        sender_id       INT NOT NULL,
                                                                                        content         TEXT,
                                                                                        type            ENUM('text','image') DEFAULT 'text',
                                                                                        image_url       VARCHAR(500) DEFAULT NULL,
                                                                                        status          ENUM('sent','delivered','seen') DEFAULT 'sent',
                                                                                        created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                                        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
                                                                                        FOREIGN KEY (sender_id)       REFERENCES users(id) ON DELETE CASCADE
                                                                                    )
                                                                                `;
                                                                                bootstrap.query(createMessages, (err) => {
                                                                                    if (err) console.error('Error creating messages table:', err);
                                                                                    else console.log('✔  Table `messages` ready.');

                                                                                    const createUserBlocks = `
                                                                                        CREATE TABLE IF NOT EXISTS user_blocks (
                                                                                            blocker_id INT NOT NULL,
                                                                                            blocked_id INT NOT NULL,
                                                                                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                                                            PRIMARY KEY (blocker_id, blocked_id),
                                                                                            FOREIGN KEY (blocker_id) REFERENCES users(id) ON DELETE CASCADE,
                                                                                            FOREIGN KEY (blocked_id) REFERENCES users(id) ON DELETE CASCADE
                                                                                        )
                                                                                    `;
                                                                                    bootstrap.query(createUserBlocks, (err) => {
                                                                                        if (err) console.error('Error creating user_blocks table:', err);
                                                                                        else console.log('✔  Table `user_blocks` ready.');

                                                                                        // ── Meeting Location columns (migration) ──────────────────
                                                                                        const alterMeetingLocation = `
                                                                                            ALTER TABLE circles
                                                                                            ADD COLUMN IF NOT EXISTS meeting_lat     DECIMAL(10, 7) DEFAULT NULL,
                                                                                            ADD COLUMN IF NOT EXISTS meeting_lng     DECIMAL(10, 7) DEFAULT NULL,
                                                                                            ADD COLUMN IF NOT EXISTS meeting_address VARCHAR(500)   DEFAULT NULL
                                                                                        `;
                                                                                        bootstrap.query(alterMeetingLocation, (err) => {
                                                                                            if (err) console.error('Error adding meeting location columns:', err);
                                                                                            else console.log('✔  Meeting location columns ready.');
                                                                                            bootstrap.end();
                                                                                        });
                                                                                    });
                                                                                });
                                                                            });
                                                                        });
                                                                    });
                                                                });
                                                            });
                                                        });
                                                    });
                                                });
                                            });
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});

// Connection pool used by the rest of the app
const pool = mysql.createPool({
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '',
    database: 'bantou',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
});

module.exports = pool.promise();
