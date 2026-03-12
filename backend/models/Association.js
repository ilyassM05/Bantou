const db = require('../config/db');

const Association = {
    /**
     * Find an association by the user's ID.
     * Searches both creator_id and association_members to support invited admins.
     * @returns {object|null}
     */
    async findByUserId(userId) {
        const [rows] = await db.query(
            `SELECT a.* FROM associations a
             LEFT JOIN association_members am ON a.id = am.association_id
             WHERE a.creator_id = ? OR am.user_id = ?
             LIMIT 1`,
            [userId, userId]
        );
        return rows[0] || null;
    },

    /**
     * Find an association where the given email is listed in admin_emails.
     * admin_emails is stored as a JSON array in a longtext column (e.g. ["a@b.com","c@d.com"]).
     * We use LIKE with exact JSON string matching to avoid false positives.
     * @param {string} email
     * @returns {object|null}
     */
    async findByAdminEmail(email) {
        // Match the email exactly as it appears inside the JSON array string
        const [rows] = await db.query(
            `SELECT * FROM associations WHERE admin_emails LIKE ?`,
            [`%"${email}"%`]
        );
        return rows[0] || null;
    },

    /**
     * Insert or update an association for a given user.
     * Uses INSERT ... ON DUPLICATE KEY UPDATE to upsert.
     * @param {number} userId
     * @param {object} data — { name, address, logoUrl, contactEmails, contactPhones, adminEmails, facebookUrl, linkedinUrl, twitterUrl }
     */
    async createOrUpdate(userId, {
        name,
        address,
        logoUrl,
        contactEmails,
        contactPhones,
        adminEmails,
        facebookUrl,
        linkedinUrl,
        twitterUrl,
    }) {
        await db.query(
            `INSERT INTO associations
                (creator_id, name, address, logo, contact_emails, contact_phones, admin_emails, fb_link, linkedin_link, twitter_link)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                name           = VALUES(name),
                address        = VALUES(address),
                logo           = VALUES(logo),
                contact_emails = VALUES(contact_emails),
                contact_phones = VALUES(contact_phones),
                admin_emails   = VALUES(admin_emails),
                fb_link        = VALUES(fb_link),
                linkedin_link  = VALUES(linkedin_link),
                twitter_link   = VALUES(twitter_link)`,
            [
                userId,
                name,
                address || null,
                logoUrl || null,
                contactEmails ? JSON.stringify(contactEmails) : null,
                contactPhones ? JSON.stringify(contactPhones) : null,
                adminEmails ? JSON.stringify(adminEmails) : null,
                facebookUrl || null,
                linkedinUrl || null,
                twitterUrl || null,
            ]
        );
    },
};

module.exports = Association;
