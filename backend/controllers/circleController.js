const Circle = require('../models/Circle');
const Association = require('../models/Association');

exports.createCircle = async (req, res) => {
    try {
        const userId = req.user.id;
        
        // Find association for this user
        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'You do not have an association created yet.' });
        }

        const {
            name,
            description,
            country,
            city,
            responsible,
            viceResponsible,
            meetingPlanning
        } = req.body;

        if (!name || !country || !city || !responsible || !viceResponsible || !meetingPlanning) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        const circleId = await Circle.create({
            association_id: association.id,
            created_by: userId,
            name,
            description,
            country,
            city,
            responsible,
            vice_responsible: viceResponsible,
            meeting_planning: meetingPlanning,
            status: 'Active'
        });

        res.status(201).json({
            message: 'Circle created successfully',
            circleId
        });

        // For MVP: Auto-create a default meeting for this newly created circle
        // so that the dashboard "Meetings" count increments immediately.
        try {
            const db = require('../config/db');
            // Schedule the meeting for 7 days from now
            const meetingDate = new Date();
            meetingDate.setDate(meetingDate.getDate() + 7);
            
            await db.query(
                `INSERT INTO meetings (circle_id, title, date, created_by) VALUES (?, ?, ?, ?)`,
                [circleId, `Initial Meeting for ${name}`, meetingDate, userId]
            );
        } catch (dbErr) {
            console.error('Failed to auto-create dummy meeting:', dbErr);
        }
    } catch (error) {
        console.error('Create circle error:', error);
        res.status(500).json({ error: 'Failed to create circle' });
    }
};

exports.getCircles = async (req, res) => {
    try {
        const userId = req.user.id;
        
        // Find association for this user
        const association = await Association.findByUserId(userId);
        if (!association) {
            // It's okay to have no association yet, just return empty list
            return res.status(200).json({ circles: [], associationName: null });
        }

        const circles = await Circle.findByAssociationId(association.id);

        const db = require('../config/db');

        // Ensure the creator is an active member, especially for those who created 
        // their association before the association_members table auto-insert logic was added.
        try {
            await db.query(
                'INSERT IGNORE INTO association_members (association_id, user_id) VALUES (?, ?)',
                [association.id, association.creator_id]
            );
        } catch (e) {
            console.error('Error auto-inserting creator to association_members:', e);
        }

        // Fetch active members count
        const [membersResult] = await db.query(
            'SELECT COUNT(*) as count FROM association_members WHERE association_id = ?',
            [association.id]
        );
        const activeMembersCount = membersResult[0].count;

        // Fetch meetings count
        let meetingsCount = 0;
        if (circles.length > 0) {
            const circleIds = circles.map(c => c.id);
            const [meetingsResult] = await db.query(
                'SELECT COUNT(*) as count FROM meetings WHERE circle_id IN (?)',
                [circleIds]
            );
            meetingsCount = meetingsResult[0].count;
        }
        
        res.status(200).json({
            associationName: association.name,
            activeMembersCount,
            meetingsCount,
            circles: circles.map(c => ({
                id: c.id,
                name: c.name,
                description: c.description,
                isAdmin: c.created_by === userId || association.creator_id === userId,
                country: c.country,
                city: c.city,
                responsible: c.responsible,
                viceResponsible: c.vice_responsible,
                meetingPlanning: c.meeting_planning,
                status: c.status,
                createdAt: c.created_at
            }))
        });
    } catch (error) {
        console.error('Get circles error:', error);
        res.status(500).json({ error: 'Failed to get circles' });
    }
};

exports.updateCircle = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        const circle = await Circle.findById(circleId);
        if (!circle) {
            return res.status(404).json({ error: 'Circle not found' });
        }

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'Unauthorized to update this circle' });
        }

        // Check if user is admin of this circle
        const isAdmin = circle.created_by === userId || association.creator_id === userId;
        if (!isAdmin) {
            return res.status(403).json({ error: 'Only admins can edit this circle' });
        }

        const {
            name,
            description,
            country,
            city,
            responsible,
            viceResponsible,
            meetingPlanning,
            status
        } = req.body;

        if (!name || !country || !city || !responsible || !viceResponsible || !meetingPlanning) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        await Circle.update(circleId, {
            name,
            description,
            country,
            city,
            responsible,
            vice_responsible: viceResponsible,
            meeting_planning: meetingPlanning,
            status: status || circle.status
        });

        res.status(200).json({
            message: 'Circle updated successfully'
        });
    } catch (error) {
        console.error('Update circle error:', error);
        res.status(500).json({ error: 'Failed to update circle' });
    }
};
