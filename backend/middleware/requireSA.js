/**
 * Middleware: requireSA
 * Rejects any request that is not from a Super Admin (role === 'SA').
 * Must be used AFTER authMiddleware so that req.user is already populated.
 */
module.exports = (req, res, next) => {
    if (!req.user || req.user.role !== 'SA') {
        return res.status(403).json({
            error: 'Access restricted to Super Admins only.',
        });
    }
    next();
};
