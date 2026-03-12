/**
 * Global error handler middleware.
 * Catches any error passed to next(err) and returns a clean JSON response.
 */
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
    console.error('[ErrorHandler]', err);
    const status = err.status || 500;
    const message = err.message || 'Internal server error';
    res.status(status).json({ error: message });
};

module.exports = errorHandler;
