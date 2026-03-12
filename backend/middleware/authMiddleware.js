const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'bantou_dev_secret_change_in_prod';

/**
 * Middleware to verify JWT token.
 * Expects "Authorization: Bearer <token>"
 */
module.exports = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Authorization required.' });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, JWT_SECRET);

        // Attach user info to request
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired token.' });
    }
};
