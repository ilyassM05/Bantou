require('dotenv').config();
require('./config/db'); // Bootstrap DB + table on startup

const http = require('http');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');

const authRoutes = require('./routes/authRoutes');
const circleRoutes = require('./routes/circleRoutes');
const postRoutes = require('./routes/postRoutes');
const messageRoutes = require('./routes/messageRoutes');
const friendRoutes  = require('./routes/friendRoutes');
const errorHandler = require('./middleware/errorHandler');
const socketHandler = require('./socket');

const app = express();
const server = http.createServer(app);

// ── Socket.io ─────────────────────────────────────────────────────────────────
const io = new Server(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
});
socketHandler(io);
// Make `io` available to route handlers via req.app.get('io')
app.set('io', io);

// ── Global middleware ──────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// ── Request logger (dev) ───────────────────────────────────────────────────────
app.use((req, _res, next) => {
    console.log(`[REQ] ${req.method} ${req.path}`);
    next();
});

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/auth', authRoutes);
app.use('/api/circles', circleRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/friends',  friendRoutes);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// ── Global error handler (must be last) ───────────────────────────────────────
app.use(errorHandler);

// ── Start ─────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`✔  Server running on http://localhost:${PORT}`);
    console.log(`✔  Socket.io enabled`);
});
