const db = require('../config/db');

const CircleAccessRequest = {
    /**
     * Create or update a circle access request.
     * @param {object} data
     */
    async create(data) {
        const { circle_id, user_id, status = 'Pending' } = data;
        const [result] = await db.query(
            `INSERT INTO circle_access_requests (circle_id, user_id, status) VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE status = VALUES(status)`,
            [circle_id, user_id, status]
        );
        return result.insertId || result.updateId;
    },

    /**
     * Get a specific access request by circle and user.
     * @param {number} circleId
     * @param {number} userId
     * @returns {object|null}
     */
    async findByCircleAndUser(circleId, userId) {
        const [rows] = await db.query(
            'SELECT * FROM circle_access_requests WHERE circle_id = ? AND user_id = ?',
            [circleId, userId]
        );
        return rows[0] || null;
    },

    /**
     * Get all pending access requests for circles belonging to a specific association.
     * @param {number} associationId
     * @returns {Array} array of requests with circle and user details
     */
    async findByAssociationIdPending(associationId) {
        const [rows] = await db.query(
            `SELECT car.*, c.name AS circle_name, u.name AS user_name, u.email AS user_email
             FROM circle_access_requests car
             JOIN circles c ON car.circle_id = c.id
             JOIN users u ON car.user_id = u.id
             WHERE c.association_id = ? AND car.status = 'Pending'
             ORDER BY car.created_at DESC`,
            [associationId]
        );
        return rows;
    },

    /**
     * Update the status of an access request.
     * @param {number} id - Request ID
     * @param {string} status - New status (e.g. 'Approved', 'Rejected')
     */
    async updateStatus(id, status) {
        await db.query(
            'UPDATE circle_access_requests SET status = ? WHERE id = ?',
            [status, id]
        );
    },

    /**
     * Find a request by ID.
     * @param {number} id
     */
    async findById(id) {
        const [rows] = await db.query(
            'SELECT * FROM circle_access_requests WHERE id = ?',
            [id]
        );
        return rows[0] || null;
    },
    
    /**
     * Get all access statuses for a specific user across a list of circle IDs.
     * @param {number} userId
     * @param {Array<number>} circleIds
     * @returns {Map} mapping of circleId to status string
     */
    async getUserStatusesForCircles(userId, circleIds) {
        if (!circleIds || circleIds.length === 0) return new Map();
        
        const [rows] = await db.query(
            `SELECT circle_id, status FROM circle_access_requests
             WHERE user_id = ? AND circle_id IN (?)`,
            [userId, circleIds]
        );
        
        const statusMap = new Map();
        rows.forEach(r => {
            statusMap.set(r.circle_id, r.status);
        });
        return statusMap;
    }
};

module.exports = CircleAccessRequest;
