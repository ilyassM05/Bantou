const db = require('../config/db');

const User = {
    /**
     * Find a user by ID.
     * @returns {object|null}
     */
    async findById(id) {
        const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
        return rows[0] || null;
    },

    /**
     * Find a user by email.
     * @returns {object|null} first matching user row or null
     */
    async findByEmail(email) {
        const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        return rows[0] || null;
    },

    /**
     * Find a user by Google ID.
     * @returns {object|null}
     */
    async findByGoogleId(googleId) {
        const [rows] = await db.query('SELECT * FROM users WHERE google_id = ?', [googleId]);
        return rows[0] || null;
    },

    /**
     * Create a new email/password user.
     * @returns {number} insertId
     */
    async create({ name, email, phone, passwordHash, role = 'SA', status = 'en attente' }) {
        const [result] = await db.query(
            'INSERT INTO users (name, email, phone, password, role, status) VALUES (?, ?, ?, ?, ?, ?)',
            [name, email, phone || null, passwordHash, role, status]
        );
        return result.insertId;
    },

    /**
     * Find an existing Google user or create a new one (upsert by google_id or email).
     * @returns {object} user row
     */
    async findOrCreateGoogleUser({ googleId, email, name, role = 'SA' }) {
        // 1. Does a google_id record already exist?
        let user = await User.findByGoogleId(googleId);
        if (user) return user;

        // 2. Does the email exist without a google_id? (user previously signed up by email)
        user = await User.findByEmail(email);
        if (user) {
            // Link the google_id to the existing account
            await db.query('UPDATE users SET google_id = ? WHERE id = ?', [googleId, user.id]);
            return { ...user, google_id: googleId };
        }

        // 3. Brand-new user — create without password
        const [result] = await db.query(
            'INSERT INTO users (name, email, google_id, role, status) VALUES (?, ?, ?, ?, ?)',
            [name, email, googleId, role, 'actif']
        );
        const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
        return rows[0];
    },

    /**
     * Find a user by Facebook ID.
     * @returns {object|null}
     */
    async findByFacebookId(facebookId) {
        const [rows] = await db.query('SELECT * FROM users WHERE facebook_id = ?', [facebookId]);
        return rows[0] || null;
    },

    /**
     * Find an existing Facebook user or create a new one (upsert by facebook_id or email).
     * @returns {object} user row
     */
    async findOrCreateFacebookUser({ facebookId, email, name, role = 'SA' }) {
        // 1. Does a facebook_id record already exist?
        let user = await User.findByFacebookId(facebookId);
        if (user) return user;

        // 2. Does the email exist? Link the facebook_id to the existing account
        if (email) {
            user = await User.findByEmail(email);
            if (user) {
                await db.query('UPDATE users SET facebook_id = ? WHERE id = ?', [facebookId, user.id]);
                return { ...user, facebook_id: facebookId };
            }
        }

        // 3. Brand-new user — create without password
        const safeName = name || 'Facebook User';
        const safeEmail = email || `fb_${facebookId}@facebook.com`;
        const [result] = await db.query(
            'INSERT INTO users (name, email, facebook_id, role, status) VALUES (?, ?, ?, ?, ?)',
            [safeName, safeEmail, facebookId, role, 'actif']
        );
        const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
        return rows[0];
    },

    /**
     * Update password hash for a user by email.
     */
    async updatePassword(email, passwordHash) {
        await db.query('UPDATE users SET password = ? WHERE email = ?', [passwordHash, email]);
    },

    /**
     * Store a 6-digit OTP and its expiry for the given email.
     */
    async saveOtp(email, otp, expiresAt) {
        await db.query(
            'UPDATE users SET otp_code = ?, otp_expires_at = ? WHERE email = ?',
            [otp, expiresAt, email]
        );
    },

    /**
     * Clear OTP fields after successful use or on reset.
     */
    async clearOtp(email) {
        await db.query(
            'UPDATE users SET otp_code = NULL, otp_expires_at = NULL WHERE email = ?',
            [email]
        );
    },

    /**
     * Update user profile information.
     */
    async updateProfile(userId, { name, company, jobTitle, communityRole, city, bio, website, avatarIndex }) {
        await db.query(
            `UPDATE users 
             SET name = COALESCE(?, name), company = ?, job_title = ?, community_role = ?, city = ?, bio = ?, website = ?, avatar_index = ? 
             WHERE id = ?`,
            [name || null, company, jobTitle, communityRole, city, bio, website, avatarIndex, userId]
        );
    },

    /**
     * Mark that the user has seen the profile setup screen (save or skip).
     */
    async markProfileSetupSeen(userId) {
        await db.query(
            'UPDATE users SET profile_setup_seen = 1 WHERE id = ?',
            [userId]
        );
    },

    /**
     * Mark that the user has completed onboarding (association + profile setup).
     */
    async markOnboardingSeen(userId) {
        await db.query(
            'UPDATE users SET onboarding_seen = 1 WHERE id = ?',
            [userId]
        );
    },
};



module.exports = User;
