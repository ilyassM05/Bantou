const db = require('../config/db');

// ── Helpers ──────────────────────────────────────────────────────────────────
async function isMember(convId, userId) {
    const [r] = await db.query(
        'SELECT 1 FROM conversation_members WHERE conversation_id=? AND user_id=? LIMIT 1',
        [convId, userId]
    );
    return r.length > 0;
}

async function isAdmin(convId, userId) {
    const [r] = await db.query(
        "SELECT role FROM conversation_members WHERE conversation_id=? AND user_id=? LIMIT 1",
        [convId, userId]
    );
    return r.length > 0 && r[0].role === 'admin';
}

async function isBlocked(a, b) {
    const [r] = await db.query(
        'SELECT 1 FROM user_blocks WHERE (blocker_id=? AND blocked_id=?) OR (blocker_id=? AND blocked_id=?) LIMIT 1',
        [a, b, b, a]
    );
    return r.length > 0;
}

// ── Invitations ───────────────────────────────────────────────────────────────

// POST /api/messages/invitations
exports.sendInvitation = async (req, res) => {
    try {
        const senderId = req.user.id;
        const { receiverId } = req.body;
        if (!receiverId) return res.status(400).json({ error: 'receiverId required' });
        if (senderId === Number(receiverId)) return res.status(400).json({ error: 'Cannot invite yourself' });

        if (await isBlocked(senderId, receiverId))
            return res.status(403).json({ error: 'Cannot send invitation' });

        // Check existing invitation
        const [existing] = await db.query(
            `SELECT * FROM chat_invitations
             WHERE (sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?)`,
            [senderId, receiverId, receiverId, senderId]
        );
        if (existing.length > 0) {
            const inv = existing[0];
            if (inv.status === 'accepted') return res.status(400).json({ error: 'Already connected' });
            if (inv.status === 'pending') return res.status(400).json({ error: 'Invitation already pending' });
            if (inv.status === 'declined') await db.query('DELETE FROM chat_invitations WHERE id=?', [inv.id]);
        }

        await db.query('INSERT INTO chat_invitations (sender_id, receiver_id) VALUES (?,?)', [senderId, receiverId]);

        const io = req.app.get('io');
        if (io) {
            const [[sender]] = await db.query('SELECT name FROM users WHERE id=?', [senderId]);
            io.to(`user:${receiverId}`).emit('new_invitation', { senderId, senderName: sender?.name });
        }
        res.json({ message: 'Invitation sent' });
    } catch (err) {
        console.error('[sendInvitation]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// GET /api/messages/invitations
exports.getInvitations = async (req, res) => {
    try {
        const userId = req.user.id;
        const [rows] = await db.query(
            `SELECT ci.id, ci.sender_id, ci.status, ci.created_at,
                    u.name AS sender_name, u.avatar_index AS sender_avatar_index
             FROM chat_invitations ci
             JOIN users u ON u.id = ci.sender_id
             WHERE ci.receiver_id=? AND ci.status='pending'
             ORDER BY ci.created_at DESC`,
            [userId]
        );
        res.json(rows);
    } catch (err) {
        console.error('[getInvitations]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// PATCH /api/messages/invitations/:id
exports.respondToInvitation = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id } = req.params;
        const { action } = req.body; // 'accept' | 'decline'
        if (!['accept', 'decline'].includes(action))
            return res.status(400).json({ error: 'action must be accept or decline' });

        const [[inv]] = await db.query(
            "SELECT * FROM chat_invitations WHERE id=? AND receiver_id=? AND status='pending'",
            [id, userId]
        );
        if (!inv) return res.status(404).json({ error: 'Invitation not found' });

        if (action === 'decline') {
            await db.query("UPDATE chat_invitations SET status='declined' WHERE id=?", [id]);
            return res.json({ message: 'Invitation declined' });
        }

        // Accept → create conversation
        await db.query("UPDATE chat_invitations SET status='accepted' WHERE id=?", [id]);
        const [convIns] = await db.query(
            "INSERT INTO conversations (type, created_by) VALUES ('private', ?)",
            [inv.sender_id]
        );
        const conversationId = convIns.insertId;

        await db.query(
            "INSERT INTO conversation_members (conversation_id, user_id, role) VALUES (?,?,'member'),(?,?,'member')",
            [conversationId, inv.sender_id, conversationId, inv.receiver_id]
        );

        const io = req.app.get('io');
        if (io) {
            const [[receiver]] = await db.query('SELECT name FROM users WHERE id=?', [userId]);
            io.to(`user:${inv.sender_id}`).emit('invitation_accepted', {
                conversationId, acceptedBy: userId, acceptedByName: receiver?.name,
            });
        }
        res.json({ message: 'Invitation accepted', conversationId });
    } catch (err) {
        console.error('[respondToInvitation]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// ── Conversations ─────────────────────────────────────────────────────────────

// GET /api/messages/conversations
exports.getConversations = async (req, res) => {
    try {
        const userId = req.user.id;
        const [rows] = await db.query(
            `SELECT c.id, c.type, c.name, c.image_url, c.created_at,
                    lm.content AS last_message, lm.created_at AS last_message_at,
                    lm.sender_id AS last_sender_id,
                    (SELECT COUNT(*) FROM messages
                     WHERE conversation_id=c.id AND status!='seen' AND sender_id!=?) AS unread_count
             FROM conversations c
             JOIN conversation_members cm ON cm.conversation_id=c.id AND cm.user_id=?
             LEFT JOIN messages lm ON lm.id=(
                 SELECT id FROM messages WHERE conversation_id=c.id ORDER BY created_at DESC LIMIT 1
             )
             ORDER BY COALESCE(lm.created_at, c.created_at) DESC`,
            [userId, userId]
        );

        for (const conv of rows) {
            if (conv.type === 'private') {
                const [[other]] = await db.query(
                    `SELECT u.id, u.name, u.avatar_index FROM conversation_members cm
                     JOIN users u ON u.id=cm.user_id
                     WHERE cm.conversation_id=? AND cm.user_id!=? LIMIT 1`,
                    [conv.id, userId]
                );
                if (other) {
                    conv.other_user_id = other.id;
                    conv.name = other.name;
                    conv.other_avatar_index = other.avatar_index;
                }
            }
            if (conv.type === 'group') {
                const [members] = await db.query(
                    `SELECT u.id, u.name, u.avatar_index, cm.role
                     FROM conversation_members cm
                     JOIN users u ON u.id=cm.user_id
                     WHERE cm.conversation_id=?`,
                    [conv.id]
                );
                conv.members = members;
            }
        }
        res.json(rows);
    } catch (err) {
        console.error('[getConversations]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// POST /api/messages/conversations (create group)
exports.createGroupConversation = async (req, res) => {
    try {
        const userId = req.user.id;
        const { name, memberIds } = req.body;
        if (!name || !Array.isArray(memberIds) || memberIds.length < 1)
            return res.status(400).json({ error: 'Group name and at least 1 member required' });

        const [convIns] = await db.query(
            "INSERT INTO conversations (type, name, created_by) VALUES ('group', ?, ?)",
            [name, userId]
        );
        const conversationId = convIns.insertId;

        const memberValues = [[conversationId, userId, 'admin']];
        for (const mid of memberIds) {
            if (Number(mid) !== userId) memberValues.push([conversationId, Number(mid), 'member']);
        }
        await db.query(
            'INSERT INTO conversation_members (conversation_id, user_id, role) VALUES ?',
            [memberValues]
        );

        const io = req.app.get('io');
        if (io) {
            const [[creator]] = await db.query('SELECT name FROM users WHERE id=?', [userId]);
            memberIds.forEach((mid) => {
                if (Number(mid) !== userId)
                    io.to(`user:${mid}`).emit('added_to_group', {
                        conversationId, groupName: name, addedByName: creator?.name,
                    });
            });
        }
        res.status(201).json({ conversationId, message: 'Group created' });
    } catch (err) {
        console.error('[createGroupConversation]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// POST /api/messages/conversations/direct (get or create 1-on-1 chat)
exports.getOrCreateDirectConversation = async (req, res) => {
    try {
        const userId = req.user.id;
        const { targetUserId } = req.body;
        if (!targetUserId) return res.status(400).json({ error: 'targetUserId required' });

        if (userId === Number(targetUserId)) return res.status(400).json({ error: 'Cannot message yourself' });

        if (await isBlocked(userId, targetUserId))
            return res.status(403).json({ error: 'Cannot message this user' });

        // Check if they are friends
        const [friends] = await db.query(
            `SELECT 1 FROM chat_invitations
             WHERE status = 'accepted'
               AND ((sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?))`,
            [userId, targetUserId, targetUserId, userId]
        );
        if (friends.length === 0) return res.status(403).json({ error: 'Must be friends to message' });

        // Check if private conversation already exists
        const [existing] = await db.query(
            `SELECT c.id FROM conversations c
             JOIN conversation_members cm1 ON cm1.conversation_id = c.id
             JOIN conversation_members cm2 ON cm2.conversation_id = c.id
             WHERE c.type = 'private'
               AND cm1.user_id = ?
               AND cm2.user_id = ?
             LIMIT 1`,
            [userId, targetUserId]
        );

        let conversationId;
        if (existing.length > 0) {
            conversationId = existing[0].id;
        } else {
            // Create new private conversation
            const [convIns] = await db.query(
                "INSERT INTO conversations (type, created_by) VALUES ('private', ?)",
                [userId]
            );
            conversationId = convIns.insertId;

            await db.query(
                "INSERT INTO conversation_members (conversation_id, user_id, role) VALUES (?,?,'member'),(?,?,'member')",
                [conversationId, userId, conversationId, targetUserId]
            );
        }

        // Fetch full conversation object to return
        const [rows] = await db.query(
            `SELECT c.id, c.type, c.name, c.image_url, c.created_at,
                    lm.content AS last_message, lm.created_at AS last_message_at,
                    0 AS unread_count
             FROM conversations c
             LEFT JOIN messages lm ON lm.id=(
                 SELECT id FROM messages WHERE conversation_id=c.id ORDER BY created_at DESC LIMIT 1
             )
             WHERE c.id = ?`,
            [conversationId]
        );

        const conv = rows[0];
        const [[other]] = await db.query(
            'SELECT id, name, avatar_index FROM users WHERE id=?',
            [targetUserId]
        );
        if (other) {
            conv.other_user_id = other.id;
            conv.name = other.name;
            conv.other_avatar_index = other.avatar_index;
        }

        res.json(conv);
    } catch (err) {
        console.error('[getOrCreateDirectConversation]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// ── Messages ──────────────────────────────────────────────────────────────────

// GET /api/messages/conversations/:id/messages
exports.getMessages = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: convId } = req.params;
        const { before, after, limit = 50 } = req.query;

        if (!(await isMember(convId, userId)))
            return res.status(403).json({ error: 'Not a member' });

        let q = `SELECT m.id, m.conversation_id, m.sender_id, m.content, m.type,
                        m.image_url, m.status, m.created_at,
                        u.name AS sender_name, u.avatar_index AS sender_avatar_index
                 FROM messages m
                 JOIN users u ON u.id=m.sender_id
                 WHERE m.conversation_id=?`;
        const params = [convId];
        if (before) { q += ' AND m.id<?'; params.push(before); }
        if (after)  { q += ' AND m.id>?'; params.push(after); }
        q += ' ORDER BY m.id DESC LIMIT ?';
        params.push(Number(limit));

        const [rows] = await db.query(q, params);
        res.json(rows.reverse());
    } catch (err) {
        console.error('[getMessages]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// POST /api/messages/conversations/:id/messages
exports.sendMessage = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: convId } = req.params;
        const { content, type = 'text' } = req.body;
        if (!content) return res.status(400).json({ error: 'content required' });

        if (!(await isMember(convId, userId)))
            return res.status(403).json({ error: 'Not a member' });

        const [ins] = await db.query(
            "INSERT INTO messages (conversation_id, sender_id, content, type) VALUES (?,?,?,?)",
            [convId, userId, content, type]
        );
        const [[msg]] = await db.query(
            `SELECT m.*, u.name AS sender_name, u.avatar_index AS sender_avatar_index
             FROM messages m JOIN users u ON u.id=m.sender_id WHERE m.id=?`,
            [ins.insertId]
        );

        const io = req.app.get('io');
        if (io) {
            io.to(`conv:${convId}`).emit('new_message', msg);
            const [members] = await db.query(
                'SELECT user_id FROM conversation_members WHERE conversation_id=? AND user_id!=?',
                [convId, userId]
            );
            members.forEach(({ user_id }) =>
                io.to(`user:${user_id}`).emit('new_message_notification', { conversationId: convId, message: msg })
            );
        }
        res.status(201).json(msg);
    } catch (err) {
        console.error('[sendMessage]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// POST /api/messages/conversations/:id/seen
exports.markSeen = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: convId } = req.params;
        await db.query(
            "UPDATE messages SET status='seen' WHERE conversation_id=? AND sender_id!=? AND status!='seen'",
            [convId, userId]
        );
        res.json({ message: 'Marked as seen' });
    } catch (err) {
        console.error('[markSeen]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// ── Group Management ──────────────────────────────────────────────────────────

// POST /api/messages/conversations/:id/members
exports.addMember = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: convId } = req.params;
        const { memberId } = req.body;
        if (!(await isAdmin(convId, userId))) return res.status(403).json({ error: 'Admin only' });

        const [[exists]] = await db.query(
            'SELECT 1 FROM conversation_members WHERE conversation_id=? AND user_id=?',
            [convId, memberId]
        );
        if (exists) return res.status(400).json({ error: 'Already a member' });

        await db.query(
            "INSERT INTO conversation_members (conversation_id, user_id, role) VALUES (?,?,'member')",
            [convId, memberId]
        );
        const io = req.app.get('io');
        if (io) {
            const [[conv]] = await db.query('SELECT name FROM conversations WHERE id=?', [convId]);
            io.to(`user:${memberId}`).emit('added_to_group', { conversationId: convId, groupName: conv?.name });
        }
        res.json({ message: 'Member added' });
    } catch (err) {
        console.error('[addMember]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// DELETE /api/messages/conversations/:id/members/:uid
exports.removeMember = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: convId, uid } = req.params;
        if (Number(uid) !== userId && !(await isAdmin(convId, userId)))
            return res.status(403).json({ error: 'Admin only' });

        await db.query(
            'DELETE FROM conversation_members WHERE conversation_id=? AND user_id=?',
            [convId, uid]
        );
        res.json({ message: 'Member removed' });
    } catch (err) {
        console.error('[removeMember]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// ── User Search ───────────────────────────────────────────────────────────────

// GET /api/messages/users/search?q=name
exports.searchUsers = async (req, res) => {
    try {
        const userId = req.user.id;
        const { q = '' } = req.query;
        const [rows] = await db.query(
            `SELECT u.id, u.name, u.avatar_index, u.job_title, u.city
             FROM users u
             JOIN association_members am ON am.user_id=u.id
             WHERE am.association_id IN (
                 SELECT association_id FROM association_members WHERE user_id=?
                 UNION
                 SELECT id FROM associations WHERE creator_id=?
             )
             AND u.id!=? AND u.name LIKE ?
             LIMIT 30`,
            [userId, userId, userId, `%${q}%`]
        );
        res.json(rows);
    } catch (err) {
        console.error('[searchUsers]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// ── Block ─────────────────────────────────────────────────────────────────────

// POST /api/messages/block/:uid
exports.blockUser = async (req, res) => {
    try {
        const userId = req.user.id;
        const { uid } = req.params;
        await db.query(
            'INSERT IGNORE INTO user_blocks (blocker_id, blocked_id) VALUES (?,?)',
            [userId, uid]
        );
        res.json({ message: 'User blocked' });
    } catch (err) {
        console.error('[blockUser]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

// DELETE /api/messages/block/:uid
exports.unblockUser = async (req, res) => {
    try {
        const userId = req.user.id;
        const { uid } = req.params;
        await db.query('DELETE FROM user_blocks WHERE blocker_id=? AND blocked_id=?', [userId, uid]);
        res.json({ message: 'User unblocked' });
    } catch (err) {
        console.error('[unblockUser]', err);
        res.status(500).json({ error: 'Server error' });
    }
};
