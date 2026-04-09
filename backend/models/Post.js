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
                u.name AS user_name,
                u.role AS user_role,
                u.avatar_index AS user_avatar,
                u.privacy_level,
                (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS likes_count,
                (SELECT COUNT(*) > 0 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = ?) AS is_liked_by_user
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.association_id = ?
            ORDER BY p.created_at DESC
        `;
        const [rows] = await db.execute(query, [viewerUserId, associationId]);
        return rows;
    },

    findById: async (postId) => {
        const query = 'SELECT * FROM posts WHERE id = ?';
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
        // Try insert — if UNIQUE constraint blocks it, the like already exists → unlike
        const [insertResult] = await db.query(
            'INSERT IGNORE INTO post_likes (post_id, user_id) VALUES (?, ?)',
            [postId, userId]
        );
        if (insertResult.affectedRows > 0) {
            return { liked: true };
        }
        // Already liked → remove it
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
};

module.exports = Post;
