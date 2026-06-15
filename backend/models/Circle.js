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
            description,
            country,
            city,
            responsible,
            vice_responsible,
            meeting_planning,
            visibility_type = 'Public',
            status = 'Active',
            meeting_lat = null,
            meeting_lng = null,
            meeting_address = null
        } = data;

        const [result] = await db.query(
            `INSERT INTO circles 
             (association_id, created_by, name, description, country, city, responsible, vice_responsible, meeting_planning, visibility_type, status, meeting_lat, meeting_lng, meeting_address)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                association_id,
                created_by,
                name,
                description || null,
                country,
                city,
                responsible,
                vice_responsible,
                meeting_planning,
                visibility_type,
                status,
                meeting_lat,
                meeting_lng,
                meeting_address
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
     * Update an existing circle by its ID
     */
    async update(id, data) {
        const {
            name,
            description,
            country,
            city,
            responsible,
            vice_responsible,
            meeting_planning,
            visibility_type,
            status,
            meeting_lat,
            meeting_lng,
            meeting_address
        } = data;

        await db.query(
            `UPDATE circles 
             SET name = COALESCE(?, name), 
                 description = ?, 
                 country = COALESCE(?, country), 
                 city = COALESCE(?, city), 
                 responsible = COALESCE(?, responsible), 
                 vice_responsible = COALESCE(?, vice_responsible), 
                 meeting_planning = COALESCE(?, meeting_planning), 
                 visibility_type = COALESCE(?, visibility_type),
                 status = COALESCE(?, status),
                 meeting_lat = ?,
                 meeting_lng = ?,
                 meeting_address = ?
             WHERE id = ?`,
            [
                name,
                description || null,
                country,
                city,
                responsible,
                vice_responsible,
                meeting_planning,
                visibility_type,
                status,
                meeting_lat !== undefined ? meeting_lat : null,
                meeting_lng !== undefined ? meeting_lng : null,
                meeting_address !== undefined ? meeting_address : null,
                id
            ]
        );
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
    },

    /**
     * Delete a circle by its ID
     */
    async delete(id) {
        await db.query('DELETE FROM circle_photos WHERE circle_id = ?', [id]);
        await db.query('DELETE FROM circle_members WHERE circle_id = ?', [id]);
        await db.query('DELETE FROM circle_access_requests WHERE circle_id = ?', [id]);
        await db.query('DELETE FROM meetings WHERE circle_id = ?', [id]);
        await db.query('DELETE FROM member_invitations WHERE circle_id = ?', [id]);
        await db.query('DELETE FROM circles WHERE id = ?', [id]);
    }
};

module.exports = Circle;
