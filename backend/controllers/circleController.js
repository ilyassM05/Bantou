const Circle = require('../models/Circle');
const Association = require('../models/Association');
const CircleAccessRequest = require('../models/CircleAccessRequest');
const { sendMemberInvitationEmail } = require('../config/mailer');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const JWT_SECRET = process.env.JWT_SECRET || 'bantou_dev_secret_change_in_prod';

exports.createCircle = async (req, res) => {
    try {
        const userId = req.user.id;

        // Members cannot create circles
        if (req.user.role === 'member') {
            return res.status(403).json({ error: 'Members cannot create circles.' });
        }

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
            meetingPlanning,
            visibilityType = 'Public',
            initialMembers = []
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
            visibility_type: visibilityType,
            status: 'Active'
        });

        if (visibilityType === 'Private') {
            const db = require('../config/db');
            try {
                const membersToAdd = new Set(initialMembers);
                membersToAdd.add(userId);
                if (association.creator_id) membersToAdd.add(association.creator_id);
                
                const mIdsArray = Array.from(membersToAdd);
                if (mIdsArray.length > 0) {
                    const [usersRoles] = await db.query(
                        'SELECT id, role FROM users WHERE id IN (?)',
                        [mIdsArray]
                    );
                    const roleMap = {};
                    usersRoles.forEach(u => roleMap[u.id] = u.role);

                    for (const mId of mIdsArray) {
                        const role = roleMap[mId] || 'member';
                        if (role === 'admin' || role === 'SA') {
                            const [existingReq] = await db.query(
                                'SELECT id FROM circle_access_requests WHERE circle_id = ? AND user_id = ?',
                                [circleId, mId]
                            );
                            if (existingReq.length === 0) {
                                await db.query(
                                    `INSERT INTO circle_access_requests (circle_id, user_id, status) VALUES (?, ?, 'Approved')`,
                                    [circleId, mId]
                                );
                            } else {
                                await db.query(
                                    `UPDATE circle_access_requests SET status = 'Approved' WHERE circle_id = ? AND user_id = ?`,
                                    [circleId, mId]
                                );
                            }
                        }

                        // Add everyone to circle_members as well for standard participation
                        await db.query(
                            'INSERT IGNORE INTO circle_members (circle_id, user_id) VALUES (?, ?)',
                            [circleId, mId]
                        );
                    }
                }
            } catch (err) {
                console.error('Error adding initial circle members:', err);
            }
        }

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

        // Fetch meetings count and access statuses
        let meetingsCount = 0;
        let accessStatuses = new Map();
        let joinStatuses = new Map(); // for members: circle_id -> joined boolean
        const isOwner = association.creator_id === userId;
        const isMember = req.user.role === 'member';

        if (circles.length > 0) {
            const circleIds = circles.map(c => c.id);
            const [meetingsResult] = await db.query(
                'SELECT COUNT(*) as count FROM meetings WHERE circle_id IN (?)',
                [circleIds]
            );
            meetingsCount = meetingsResult[0].count;

            if (!isOwner) {
                accessStatuses = await CircleAccessRequest.getUserStatusesForCircles(userId, circleIds);
            }

            // For members, get their circle join status
            if (isMember) {
                const [joinRows] = await db.query(
                    'SELECT circle_id FROM circle_members WHERE user_id = ? AND circle_id IN (?)',
                    [userId, circleIds]
                );
                joinRows.forEach(r => joinStatuses.set(r.circle_id, true));
            }
        }
        
        res.status(200).json({
            associationName: association.name,
            activeMembersCount,
            meetingsCount,
            circles: circles.filter(c => {
                if (isOwner || !isMember) return true;
                if (c.visibility_type === 'Private') {
                    return joinStatuses.get(c.id) === true;
                }
                return true;
            }).map(c => {
                let accessStatus = isOwner ? 'Owner' : (accessStatuses.get(c.id) || 'None');
                if (c.created_by === userId) accessStatus = 'Owner';
                const joinStatus = isMember ? (joinStatuses.get(c.id) ? 'Joined' : 'NotJoined') : null;
                
                return {
                    id: c.id,
                    name: c.name,
                    description: c.description,
                    isAdmin: c.created_by === userId || association.creator_id === userId || accessStatus === 'Approved',
                    accessStatus,
                    joinStatus,
                    country: c.country,
                    city: c.city,
                    responsible: c.responsible,
                    viceResponsible: c.vice_responsible,
                    meetingPlanning: c.meeting_planning,
                    visibilityType: c.visibility_type,
                    status: c.status,
                    createdAt: c.created_at
                };
            })
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

        // Members cannot modify circles
        if (req.user.role === 'member') {
            return res.status(403).json({ error: 'Members cannot modify circles.' });
        }

        const circle = await Circle.findById(circleId);
        if (!circle) {
            return res.status(404).json({ error: 'Circle not found' });
        }

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'Unauthorized to update this circle' });
        }

        // Check if user is admin of this circle (Owner or Approved Admin)
        let isAdmin = circle.created_by === userId || association.creator_id === userId;

        if (!isAdmin) {
            const accessRequest = await CircleAccessRequest.findByCircleAndUser(circleId, userId);
            if (accessRequest && accessRequest.status === 'Approved') {
                isAdmin = true;
            }
        }

        if (!isAdmin) {
            return res.status(403).json({ error: 'Only authorized admins can edit this circle' });
        }

        const {
            name,
            description,
            country,
            city,
            responsible,
            viceResponsible,
            meetingPlanning,
            visibilityType,
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
            visibility_type: visibilityType || circle.visibility_type,
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

exports.requestAccess = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        const circle = await Circle.findById(circleId);
        if (!circle) {
            return res.status(404).json({ error: 'Circle not found' });
        }

        const association = await Association.findByUserId(userId);
        if (!association || association.id !== circle.association_id) {
            return res.status(403).json({ error: 'Unauthorized to request access to this circle' });
        }

        const existingRequest = await CircleAccessRequest.findByCircleAndUser(circleId, userId);
        if (existingRequest) {
            return res.status(400).json({ error: 'Access request already exists' });
        }

        await CircleAccessRequest.create({ circle_id: circleId, user_id: userId, status: 'Pending' });

        res.status(201).json({ message: 'Access request submitted successfully' });
    } catch (error) {
        console.error('Request access error:', error);
        res.status(500).json({ error: 'Failed to request access' });
    }
};

exports.getPendingRequests = async (req, res) => {
    try {
        const userId = req.user.id;

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'No association found' });
        }

        if (association.creator_id !== userId) {
            return res.status(403).json({ error: 'Only association owners can view pending requests' });
        }

        const pendingRequests = await CircleAccessRequest.findByAssociationIdPending(association.id);

        res.status(200).json({ pendingRequests });
    } catch (error) {
        console.error('Get pending requests error:', error);
        res.status(500).json({ error: 'Failed to get pending requests' });
    }
};

exports.respondToRequest = async (req, res) => {
    try {
        const userId = req.user.id;
        const requestId = req.params.requestId;
        const { status } = req.body; // 'Approved' or 'Rejected'

        if (!['Approved', 'Rejected'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        const accessRequest = await CircleAccessRequest.findById(requestId);
        if (!accessRequest) {
            return res.status(404).json({ error: 'Access request not found' });
        }

        const circle = await Circle.findById(accessRequest.circle_id);
        const association = await Association.findByUserId(userId);

        if (!association || association.id !== circle.association_id || association.creator_id !== userId) {
            return res.status(403).json({ error: 'Unauthorized to respond to this request' });
        }

        await CircleAccessRequest.updateStatus(requestId, status);

        res.status(200).json({ message: `Request ${status.toLowerCase()} successfully` });
    } catch (error) {
        console.error('Respond to request error:', error);
        res.status(500).json({ error: 'Failed to respond to request' });
    }
};

// ─── Member Circle Actions ──────────────────────────────────────────

/**
 * POST /api/circles/:id/join
 * Member joins a circle.
 */
exports.joinCircle = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        const circle = await Circle.findById(circleId);
        if (!circle) return res.status(404).json({ error: 'Circle not found' });

        // Verify user is in the same association
        const association = await Association.findByUserId(userId);
        if (!association || association.id !== circle.association_id) {
            return res.status(403).json({ error: 'You do not belong to this association.' });
        }

        const db = require('../config/db');
        await db.query(
            'INSERT IGNORE INTO circle_members (circle_id, user_id) VALUES (?, ?)',
            [circleId, userId]
        );

        res.status(200).json({ message: 'Successfully joined the circle.' });
    } catch (error) {
        console.error('Join circle error:', error);
        res.status(500).json({ error: 'Failed to join circle' });
    }
};

/**
 * DELETE /api/circles/:id/join
 * Member leaves a circle.
 */
exports.leaveCircle = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        const db = require('../config/db');
        await db.query(
            'DELETE FROM circle_members WHERE circle_id = ? AND user_id = ?',
            [circleId, userId]
        );

        res.status(200).json({ message: 'Successfully left the circle.' });
    } catch (error) {
        console.error('Leave circle error:', error);
        res.status(500).json({ error: 'Failed to leave circle' });
    }
};

/**
 * POST /api/circles/:id/invite
 * Member invites someone to join a circle by email.
 * Creates a pending member_invitation entry that SA must approve.
 */
exports.inviteToCircle = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;
        const { email } = req.body;

        if (!email) return res.status(400).json({ error: 'Email is required.' });

        const circle = await Circle.findById(circleId);
        if (!circle) return res.status(404).json({ error: 'Circle not found' });

        const association = await Association.findByUserId(userId);
        if (!association || association.id !== circle.association_id) {
            return res.status(403).json({ error: 'You do not belong to this association.' });
        }

        // Check if the SA is the one calling — SA can send directly
        const inviterRole = req.user.role;
        const db = require('../config/db');

        // Check if already invited
        const [existing] = await db.query(
            'SELECT id FROM member_invitations WHERE invitee_email=? AND association_id=? AND status IN (?)',
            [email.trim().toLowerCase(), association.id, ['pending', 'accepted']]
        );
        if (existing.length > 0) {
            return res.status(400).json({ error: 'This email has already been invited.' });
        }

        // Get inviter name
        const inviterUser = await User.findById(userId);
        const inviterName = inviterUser?.name || req.user.name || 'A Bantou Member';

        if (inviterRole === 'SA') {
            // SA: generate token + send immediately
            const [invRow] = await db.query(
                `INSERT INTO member_invitations (association_id, invited_by, invitee_email, circle_id, token, status)
                 VALUES (?, ?, ?, ?, '', 'pending')`,
                [association.id, userId, email.trim().toLowerCase(), circleId]
            );
            const invitationId = invRow.insertId;

            const inviteToken = jwt.sign(
                { email: email.trim().toLowerCase(), associationId: association.id, purpose: 'member_invite', invitationId },
                JWT_SECRET,
                { expiresIn: '7d' }
            );

            await db.query('UPDATE member_invitations SET token=? WHERE id=?', [inviteToken, invitationId]);
            await sendMemberInvitationEmail(
                email.trim().toLowerCase(), inviterName, association.name, inviteToken, circle.name
            );

            return res.status(200).json({ message: 'Invitation sent successfully.' });
        } else {
            // Non-SA: create pending entry, SA must approve
            await db.query(
                `INSERT INTO member_invitations (association_id, invited_by, invitee_email, circle_id, token, status)
                 VALUES (?, ?, ?, ?, '', 'pending')`,
                [association.id, userId, email.trim().toLowerCase(), circleId]
            );
            return res.status(200).json({ message: 'Your invitation request has been submitted for Super Admin approval.' });
        }
    } catch (error) {
        console.error('Invite to circle error:', error);
        res.status(500).json({ error: 'Failed to send circle invitation' });
    }
};

exports.getAssociationMembers = async (req, res) => {
    try {
        const userId = req.user.id;
        const search = req.query.search || '';

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'No association found' });
        }

        const db = require('../config/db');
        let query = `
            SELECT u.id, u.name, u.email, u.phone, u.role
            FROM users u
            JOIN association_members am ON u.id = am.user_id
            WHERE am.association_id = ?
        `;
        const queryParams = [association.id];

        if (search) {
            query += ' AND (u.name LIKE ? OR u.email LIKE ?)';
            const likeSearch = `%${search}%`;
            queryParams.push(likeSearch, likeSearch);
        }

        const [members] = await db.query(query, queryParams);

        res.status(200).json({ members });
    } catch (error) {
        console.error('Get association members error:', error);
        res.status(500).json({ error: 'Failed to fetch association members' });
    }
};

exports.getCircleParticipants = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        if (req.user.role === 'member') {
            return res.status(403).json({ error: 'Only admins can view participants' });
        }

        const circle = await Circle.findById(circleId);
        if (!circle) {
            return res.status(404).json({ error: 'Circle not found' });
        }

        const association = await Association.findByUserId(userId);
        if (!association || association.id !== circle.association_id) {
            return res.status(403).json({ error: 'Unauthorized to view participants for this circle' });
        }

        const db = require('../config/db');

        const query = `
            SELECT 
                u.id, 
                u.name, 
                u.email, 
                u.role, 
                IF(cm.circle_id IS NOT NULL, 1, 0) as has_joined,
                cm.joined_at
            FROM users u
            JOIN association_members am ON u.id = am.user_id
            LEFT JOIN circle_members cm ON u.id = cm.user_id AND cm.circle_id = ?
            WHERE am.association_id = ?
            ORDER BY has_joined DESC, u.name ASC
        `;

        const [participants] = await db.query(query, [circleId, association.id]);

        const formattedParticipants = participants.map(p => ({
            id: p.id,
            name: p.name,
            email: p.email,
            role: p.role,
            hasJoined: p.has_joined === 1,
            joinedAt: p.joined_at
        }));

        res.status(200).json({ participants: formattedParticipants });
    } catch (error) {
        console.error('Get circle participants error:', error);
        res.status(500).json({ error: 'Failed to fetch circle participants' });
    }
};

async function checkCirclePhotoAccess(userId, userRole, circleId) {
    const Circle = require('../models/Circle');
    const Association = require('../models/Association');
    const db = require('../config/db');

    const circle = await Circle.findById(circleId);
    if (!circle) return { error: 'Circle not found', status: 404 };

    const association = await Association.findByUserId(userId);
    if (!association || association.id !== circle.association_id) {
        return { error: 'Unauthorized', status: 403 };
    }

    if (userRole === 'SA' || userRole === 'admin') return { circle };

    const [joinRows] = await db.query(
        'SELECT id FROM circle_members WHERE user_id = ? AND circle_id = ?',
        [userId, circleId]
    );

    if (joinRows.length === 0) {
        return { error: 'You must join the circle to access photos', status: 403 };
    }

    return { circle };
}

exports.uploadCirclePhoto = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        const access = await checkCirclePhotoAccess(userId, req.user.role, circleId);
        if (access.error) return res.status(access.status).json({ error: access.error });

        if (!req.file) {
            return res.status(400).json({ error: 'No photo uploaded' });
        }

        const photoUrl = '/uploads/' + req.file.filename;

        const db = require('../config/db');
        const [result] = await db.query(
            'INSERT INTO circle_photos (circle_id, user_id, photo_url) VALUES (?, ?, ?)',
            [circleId, userId, photoUrl]
        );

        res.status(201).json({ 
            message: 'Photo uploaded successfully', 
            photo: {
                id: result.insertId,
                url: photoUrl
            } 
        });
    } catch (error) {
        console.error('Upload photo error:', error);
        res.status(500).json({ error: 'Failed to upload photo' });
    }
};

exports.getCirclePhotos = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        const access = await checkCirclePhotoAccess(userId, req.user.role, circleId);
        if (access.error) return res.status(access.status).json({ error: access.error });
        
        const db = require('../config/db');
        const query = `
            SELECT cp.id, cp.photo_url, cp.created_at, u.name as uploader_name 
            FROM circle_photos cp
            JOIN users u ON cp.user_id = u.id
            WHERE cp.circle_id = ?
            ORDER BY cp.created_at DESC
        `;
        const [photos] = await db.query(query, [circleId]);

        res.status(200).json({ photos });
    } catch (error) {
        console.error('Get photos error:', error);
        res.status(500).json({ error: 'Failed to fetch photos' });
    }
};
