require('dotenv').config();
require('./config/db'); // Bootstrap DB + table on startup

const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const circleRoutes = require('./routes/circleRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// ── Global middleware ──────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// ── Request logger (dev) ───────────────────────────────────────────────────
app.use((req, _res, next) => {
    console.log(`[REQ] ${req.method} ${req.path}`);
    next();
});

// ── Routes ────────────────────────────────────────────────────────────────
app.use('/auth', authRoutes);
app.use('/api/circles', circleRoutes);

// ── Health check ──────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// ── Global error handler (must be last) ───────────────────────────────────
app.use(errorHandler);

// ── Start ─────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✔  Server running on http://localhost:${PORT}`);
});

