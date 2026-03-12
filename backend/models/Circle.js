const db = require('../config/db');

const Circle = {
    /**
     * Create a new circle mapped to an association and user.
     * @param {object} data
     */
    async create(data) {
        const {
            association_id,
            created_by,
            name,
            country,
            city,
            responsible,
            vice_responsible,
            meeting_planning,
            status = 'Active'
        } = data;

        const [result] = await db.query(
            `INSERT INTO circles 
             (association_id, created_by, name, country, city, responsible, vice_responsible, meeting_planning, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                association_id,
                created_by,
                name,
                country,
                city,
                responsible,
                vice_responsible,
                meeting_planning,
                status
            ]
        );
        return result.insertId;
    },

    /**
     * Get all circles for a specific association.
     * @param {number} associationId
     * @returns {Array} array of circles
     */
    async findByAssociationId(associationId) {
        const [rows] = await db.query(
            'SELECT * FROM circles WHERE association_id = ? ORDER BY created_at DESC',
            [associationId]
        );
        return rows;
    },

    /**
     * Get a circle by its ID
     */
    async findById(id) {
        const [rows] = await db.query(
            'SELECT * FROM circles WHERE id = ?',
            [id]
        );
        return rows[0] || null;
    }
};

module.exports = Circle;
