const db = require('../config/db');

// ── Helper ────────────────────────────────────────────────────────────────────

/**
 * Returns the relationship status between the current user and a target user.
 * Uses the existing chat_invitations table.
 * Possible values:
 *   'self'             — same user
 *   'none'             — no relationship
 *   'pending_sent'     — current user sent a request, awaiting response
 *   'pending_received' — target user sent a request to current user
 *   'friends'          — accepted (bidirectional friendship)
 */
async function getStatus(currentId, targetId) {
    if (currentId === targetId) return 'self';

    const [rows] = await db.execute(
        `SELECT id, sender_id, receiver_id, status
         FROM chat_invitations
         WHERE (sender_id = ? AND receiver_id = ?)
            OR (sender_id = ? AND receiver_id = ?)
         LIMIT 1`,
        [currentId, targetId, targetId, currentId],
    );

    if (rows.length === 0) return 'none';
    const row = rows[0];

    if (row.status === 'accepted') return 'friends';
    if (row.status === 'declined') return 'none'; // treat declined as no relation
    if (row.status === 'pending') {
        return row.sender_id === currentId ? 'pending_sent' : 'pending_received';
    }
    return 'none';
}

// ── Controllers ───────────────────────────────────────────────────────────────

/**
 * GET /api/friends/status/:targetUserId
 * Returns { status: 'none' | 'pending_sent' | 'pending_received' | 'friends' | 'self' }
 */
exports.getFriendStatus = async (req, res) => {
    try {
        const currentId = req.user.id;
        const targetId  = parseInt(req.params.targetUserId, 10);
        if (isNaN(targetId)) return res.status(400).json({ error: 'Invalid user id' });

        const status = await getStatus(currentId, targetId);
        return res.json({ status });
    } catch (err) {
        console.error('[friendController] getFriendStatus error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};

/**
 * POST /api/friends/request/:targetUserId
 * Sends a friend request. Idempotent — if a pending request already exists, returns 200.
 */
exports.sendFriendRequest = async (req, res) => {
    try {
        const senderId   = req.user.id;
        const receiverId = parseInt(req.params.targetUserId, 10);
        if (isNaN(receiverId)) return res.status(400).json({ error: 'Invalid user id' });
        if (senderId === receiverId) return res.status(400).json({ error: 'Cannot send request to yourself' });

        const status = await getStatus(senderId, receiverId);

        if (status === 'friends') {
            return res.json({ message: 'Already friends' });
        }
        if (status === 'pending_sent') {
            return res.json({ message: 'Request already sent' });
        }
        if (status === 'pending_received') {
            // Auto-accept if the other side already requested
            await db.execute(
                `UPDATE chat_invitations
                 SET status = 'accepted', updated_at = NOW()
                 WHERE sender_id = ? AND receiver_id = ?`,
                [receiverId, senderId],
            );
            return res.json({ message: 'Friend request accepted (auto-matched)' });
        }

        // Insert fresh request (replace if a declined row exists)
        await db.execute(
            `INSERT INTO chat_invitations (sender_id, receiver_id, status)
             VALUES (?, ?, 'pending')
             ON DUPLICATE KEY UPDATE status = 'pending'`,
            [senderId, receiverId],
        );

        return res.status(201).json({ message: 'Friend request sent' });
    } catch (err) {
        console.error('[friendController] sendFriendRequest error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};

/**
 * PUT /api/friends/respond/:requestId
 * Body: { action: 'accept' | 'decline' }
 * Responds to a pending friend request (receiver only).
 */
exports.respondToFriendRequest = async (req, res) => {
    try {
        const currentId = req.user.id;
        const requestId = parseInt(req.params.requestId, 10);
        const { action } = req.body;

        if (!['accept', 'decline'].includes(action)) {
            return res.status(400).json({ error: 'action must be accept or decline' });
        }

        const [rows] = await db.execute(
            `SELECT id, sender_id, receiver_id, status FROM chat_invitations WHERE id = ?`,
            [requestId],
        );
        if (rows.length === 0) return res.status(404).json({ error: 'Request not found' });

        const inv = rows[0];
        if (inv.receiver_id !== currentId) return res.status(403).json({ error: 'Forbidden' });
        if (inv.status !== 'pending') return res.status(400).json({ error: 'Request is not pending' });

        const newStatus = action === 'accept' ? 'accepted' : 'declined';
        await db.execute(
            `UPDATE chat_invitations SET status = ?, updated_at = NOW() WHERE id = ?`,
            [newStatus, requestId],
        );

        return res.json({ message: `Request ${newStatus}` });
    } catch (err) {
        console.error('[friendController] respondToFriendRequest error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};

/**
 * GET /api/friends
 * Returns the list of accepted friends for the current user.
 */
exports.getFriends = async (req, res) => {
    try {
        const currentId = req.user.id;

        const [rows] = await db.execute(
            `SELECT
                u.id,
                u.name,
                u.email,
                u.profile_picture
             FROM chat_invitations ci
             JOIN users u ON (
                 CASE
                     WHEN ci.sender_id = ? THEN ci.receiver_id
                     ELSE ci.sender_id
                 END = u.id
             )
             WHERE ci.status = 'accepted'
               AND (ci.sender_id = ? OR ci.receiver_id = ?)`,
            [currentId, currentId, currentId],
        );

        return res.json({ friends: rows });
    } catch (err) {
        console.error('[friendController] getFriends error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};

/**
 * GET /api/friends/requests/pending
 * Returns all pending incoming friend requests for the current user.
 */
exports.getPendingRequests = async (req, res) => {
    try {
        const currentId = req.user.id;

        const [rows] = await db.execute(
            `SELECT ci.id, u.id AS sender_id, u.name, u.email, ci.created_at
             FROM chat_invitations ci
             JOIN users u ON ci.sender_id = u.id
             WHERE ci.receiver_id = ? AND ci.status = 'pending'
             ORDER BY ci.created_at DESC`,
            [currentId],
        );

        return res.json({ requests: rows });
    } catch (err) {
        console.error('[friendController] getPendingRequests error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};

/**
 * GET /api/friends/requests/sent
 * Returns all pending outgoing friend requests sent by the current user.
 */
exports.getSentRequests = async (req, res) => {
    try {
        const currentId = req.user.id;

        const [rows] = await db.execute(
            `SELECT ci.id, u.id AS receiver_id, u.name, u.email, u.profile_picture, ci.created_at
             FROM chat_invitations ci
             JOIN users u ON ci.receiver_id = u.id
             WHERE ci.sender_id = ? AND ci.status = 'pending'
             ORDER BY ci.created_at DESC`,
            [currentId],
        );

        return res.json({ requests: rows });
    } catch (err) {
        console.error('[friendController] getSentRequests error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};

/**
 * DELETE /api/friends/:targetUserId
 * Removes an accepted friendship bidirectionally.
 * Also clears any residual pending request between the two users.
 */
exports.removeFriend = async (req, res) => {
    try {
        const currentId = req.user.id;
        const targetId  = parseInt(req.params.targetUserId, 10);
        if (isNaN(targetId)) return res.status(400).json({ error: 'Invalid user id' });
        if (currentId === targetId) return res.status(400).json({ error: 'Cannot unfriend yourself' });

        // Delete the accepted friendship row (either direction)
        await db.execute(
            `DELETE FROM chat_invitations
             WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?))
               AND status = 'accepted'`,
            [currentId, targetId, targetId, currentId],
        );

        // Also clear any residual pending requests between the two users
        await db.execute(
            `DELETE FROM chat_invitations
             WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?))
               AND status = 'pending'`,
            [currentId, targetId, targetId, currentId],
        );

        return res.json({ message: 'Friend removed' });
    } catch (err) {
        console.error('[friendController] removeFriend error:', err);
        return res.status(500).json({ error: 'Server error' });
    }
};
