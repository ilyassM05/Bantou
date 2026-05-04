const jwt = require('jsonwebtoken');
const db = require('./config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'bantou_dev_secret_change_in_prod';

module.exports = (io) => {
    // ── Auth middleware ──────────────────────────────────────────────────────
    io.use((socket, next) => {
        const token =
            socket.handshake.auth?.token ||
            socket.handshake.query?.token;
        if (!token) return next(new Error('Authentication required'));
        try {
            socket.user = jwt.verify(token, JWT_SECRET);
            next();
        } catch {
            next(new Error('Invalid token'));
        }
    });

    io.on('connection', (socket) => {
        const userId = socket.user.id;
        socket.join(`user:${userId}`);
        console.log(`[Socket] User ${userId} connected`);

        // ── Join / leave conversation rooms ──────────────────────────────────
        socket.on('join_conversation', (conversationId) => {
            socket.join(`conv:${conversationId}`);
        });

        socket.on('leave_conversation', (conversationId) => {
            socket.leave(`conv:${conversationId}`);
        });

        // ── Typing indicators ─────────────────────────────────────────────────
        socket.on('typing', ({ conversationId }) => {
            socket.to(`conv:${conversationId}`).emit('user_typing', {
                userId,
                conversationId,
            });
        });

        socket.on('stop_typing', ({ conversationId }) => {
            socket.to(`conv:${conversationId}`).emit('user_stop_typing', {
                userId,
                conversationId,
            });
        });

        // ── Mark seen ─────────────────────────────────────────────────────────
        socket.on('mark_seen', async ({ conversationId }) => {
            try {
                const [senders] = await db.query(
                    `SELECT DISTINCT sender_id FROM messages
                     WHERE conversation_id = ? AND status != 'seen' AND sender_id != ?`,
                    [conversationId, userId]
                );
                await db.query(
                    `UPDATE messages SET status = 'seen'
                     WHERE conversation_id = ? AND sender_id != ? AND status != 'seen'`,
                    [conversationId, userId]
                );
                senders.forEach(({ sender_id }) => {
                    io.to(`user:${sender_id}`).emit('messages_seen', {
                        conversationId,
                        seenBy: userId,
                    });
                });
            } catch (err) {
                console.error('[Socket] mark_seen error:', err);
            }
        });

        socket.on('disconnect', () => {
            console.log(`[Socket] User ${userId} disconnected`);
        });
    });
};
