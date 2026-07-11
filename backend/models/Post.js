const db = require('../config/db');

const Post = {
    create: async (userId, associationId, content, imageUrl) => {
        const query = `
            INSERT INTO posts (user_id, association_id, content, image_url)
            VALUES (?, ?, ?, ?)
        `;
        const [result] = await db.query(query, [userId, associationId, content, imageUrl]);
        return result.insertId;
    },

    findByAssociationId: async (associationId, viewerUserId) => {
        const query = `
            SELECT
                p.*,
                u.name  AS user_name,
                u.role  AS user_role,
                u.avatar_index AS user_avatar,
                u.privacy_level,
                (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS likes_count,
                (SELECT COUNT(*) > 0 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = ?) AS is_liked_by_user,
                NULL AS shared_by_name
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.association_id = ?

            UNION ALL

            SELECT
                p.*,
                u.name  AS user_name,
                u.role  AS user_role,
                u.avatar_index AS user_avatar,
                u.privacy_level,
                (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS likes_count,
                (SELECT COUNT(*) > 0 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = ?) AS is_liked_by_user,
                sharer.name AS shared_by_name
            FROM post_shares ps
            JOIN posts p      ON ps.post_id   = p.id
            JOIN users u      ON p.user_id    = u.id
            JOIN users sharer ON ps.shared_by = sharer.id
            WHERE ps.shared_to = ?
              AND p.association_id = ?

            ORDER BY created_at DESC
        `;
        const [rows] = await db.execute(query, [
            viewerUserId, associationId,          // original posts params
            viewerUserId, viewerUserId, associationId  // shared posts params
        ]);
        return rows;
    },

    findById: async (postId) => {
        const query = `
            SELECT p.*, u.role AS author_role
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.id = ?
        `;
        const [rows] = await db.execute(query, [postId]);
        return rows[0];
    },

    delete: async (postId) => {
        const query = 'DELETE FROM posts WHERE id = ?';
        const [result] = await db.execute(query, [postId]);
        return result.affectedRows;
    },

    // Returns true if liked, false if unliked
    toggleLike: async (postId, userId) => {
        const [insertResult] = await db.query(
            'INSERT IGNORE INTO post_likes (post_id, user_id) VALUES (?, ?)',
            [postId, userId]
        );
        if (insertResult.affectedRows > 0) {
            return { liked: true };
        }
        await db.query(
            'DELETE FROM post_likes WHERE post_id = ? AND user_id = ?',
            [postId, userId]
        );
        return { liked: false };
    },

    getLikesCount: async (postId) => {
        const [rows] = await db.query(
            'SELECT COUNT(*) AS count FROM post_likes WHERE post_id = ?',
            [postId]
        );
        return rows[0].count;
    },

    // ── Comments ─────────────────────────────────────────────────────────

    getComments: async (postId) => {
        const [rows] = await db.execute(`
            SELECT
                pc.id,
                pc.post_id,
                pc.user_id,
                pc.content,
                pc.created_at,
                u.name AS user_name
            FROM post_comments pc
            JOIN users u ON pc.user_id = u.id
            WHERE pc.post_id = ?
            ORDER BY pc.created_at ASC
        `, [postId]);
        return rows;
    },

    addComment: async (postId, userId, content) => {
        const [result] = await db.execute(
            'INSERT INTO post_comments (post_id, user_id, content) VALUES (?, ?, ?)',
            [postId, userId, content]
        );
        const commentId = result.insertId;

        // Increment denormalized counter
        await db.execute(
            'UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?',
            [postId]
        );

        // Return newly inserted comment with user name
        const [rows] = await db.execute(`
            SELECT pc.id, pc.post_id, pc.user_id, pc.content, pc.created_at, u.name AS user_name
            FROM post_comments pc
            JOIN users u ON pc.user_id = u.id
            WHERE pc.id = ?
        `, [commentId]);
        return rows[0];
    },

    // ── Sharing ──────────────────────────────────────────────────────────

    /**
     * Share a post to multiple recipients.
     * @param {number} postId
     * @param {number} sharedBy   – sender's user id
     * @param {number[]} recipientIds – array of recipient user ids
     * @param {number} associationId  – sender's association (for validation)
     */
    sharePost: async (postId, sharedBy, recipientIds, associationId) => {
        if (!recipientIds || recipientIds.length === 0) return;

        // Verify all recipients belong to the same association.
        // Membership is tracked via association_members junction table
        // (or the user is the association creator) — users have no direct association_id.
        const placeholders = recipientIds.map(() => '?').join(', ');
        const [validRows] = await db.execute(`
            SELECT DISTINCT u.id
            FROM users u
            WHERE u.id IN (${placeholders})
              AND (
                u.id = (SELECT creator_id FROM associations WHERE id = ?)
                OR u.id IN (SELECT user_id FROM association_members WHERE association_id = ?)
              )
        `, [...recipientIds, associationId, associationId]);

        if (validRows.length !== recipientIds.length) {
            throw new Error('One or more recipients are not members of your association.');
        }

        // Batch insert — INSERT IGNORE skips duplicate shares
        // include user_id = sharedBy to satisfy NOT NULL constraint on user_id
        const values = recipientIds.map(rid => [postId, sharedBy, sharedBy, rid]);
        await db.query(
            'INSERT IGNORE INTO post_shares (post_id, user_id, shared_by, shared_to) VALUES ?',
            [values]
        );
    },
};

module.exports = Post;
