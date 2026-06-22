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
            initialMembers = [],
            meetingLat,
            meetingLng,
            meetingAddress
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
            status: 'Active',
            meeting_lat: meetingLat || null,
            meeting_lng: meetingLng || null,
            meeting_address: meetingAddress || null
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
                    createdAt: c.created_at,
                    meetingLat: c.meeting_lat ? parseFloat(c.meeting_lat) : null,
                    meetingLng: c.meeting_lng ? parseFloat(c.meeting_lng) : null,
                    meetingAddress: c.meeting_address || null
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
            status,
            meetingLat,
            meetingLng,
            meetingAddress
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
            status: status || circle.status,
            meeting_lat: meetingLat !== undefined ? meetingLat : circle.meeting_lat,
            meeting_lng: meetingLng !== undefined ? meetingLng : circle.meeting_lng,
            meeting_address: meetingAddress !== undefined ? meetingAddress : circle.meeting_address
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

exports.deleteCircle = async (req, res) => {
    try {
        const userId = req.user.id;
        const circleId = req.params.id;

        if (req.user.role === 'member') {
            return res.status(403).json({ error: 'Members cannot delete circles.' });
        }

        const circle = await Circle.findById(circleId);
        if (!circle) {
            return res.status(404).json({ error: 'Circle not found' });
        }

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'Unauthorized to delete this circle' });
        }

        let isAdmin = circle.created_by === userId || association.creator_id === userId;

        if (!isAdmin) {
            const accessRequest = await CircleAccessRequest.findByCircleAndUser(circleId, userId);
            if (accessRequest && accessRequest.status === 'Approved') {
                isAdmin = true;
            }
        }

        if (req.user.role === 'SA') {
            isAdmin = true;
        }

        if (!isAdmin) {
            return res.status(403).json({ error: 'Only authorized admins can delete this circle' });
        }

        await Circle.delete(circleId);

        res.status(200).json({ message: 'Circle deleted successfully' });
    } catch (error) {
        console.error('Delete circle error:', error);
        res.status(500).json({ error: 'Failed to delete circle' });
    }
};

exports.getPendingRequests = async (req, res) => {
    try {
        const userId = req.user.id;
        const role = req.user.role;

        // Members have no access
        if (role === 'member') {
            return res.status(403).json({ error: 'Members cannot view requests' });
        }

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'No association found' });
        }

        const db = require('../config/db');

        // Association Join Requests (Pending Members)
        // SA sees all pending members; Admin sees only members who requested to join
        // circles that the admin created.
        let memberRequests;
        if (role === 'SA') {
            [memberRequests] = await db.query(
                `SELECT u.id as user_id, u.name as user_name, u.email as user_email, u.status, u.created_at,
                        mi.invited_by, inv.name as inviter_name
                 FROM users u
                 JOIN association_members am ON u.id = am.user_id
                 JOIN member_invitations mi ON mi.invitee_email = u.email AND mi.association_id = am.association_id
                 LEFT JOIN users inv ON mi.invited_by = inv.id
                 WHERE am.association_id = ? AND u.status = 'en attente'`,
                 [association.id]
            );
        } else {
            // Admin: only see member requests for circles they created
            [memberRequests] = await db.query(
                `SELECT DISTINCT u.id as user_id, u.name as user_name, u.email as user_email, u.status, u.created_at,
                        mi.invited_by, inv.name as inviter_name
                 FROM users u
                 JOIN association_members am ON u.id = am.user_id
                 JOIN member_invitations mi ON mi.invitee_email = u.email AND mi.association_id = am.association_id
                 LEFT JOIN users inv ON mi.invited_by = inv.id
                 JOIN circles c ON mi.circle_id = c.id
                 WHERE am.association_id = ? AND u.status = 'en attente' AND c.created_by = ?`,
                 [association.id, userId]
            );
        }

        let pendingRequests = [
            ...memberRequests.map(r => ({ ...r, requestType: 'association', id: r.user_id }))
        ];

        // Circle Access Requests — SA only
        if (role === 'SA') {
            const [circleRequests] = await db.query(
                `SELECT car.*, c.name as circle_name, u.name as user_name, u.email as user_email
                 FROM circle_access_requests car 
                 JOIN circles c ON car.circle_id = c.id 
                 JOIN users u ON car.user_id = u.id 
                 WHERE c.association_id = ? AND car.status = 'Pending'`,
                 [association.id]
            );
            
            // Pending Member Invitations - waiting for SA approval to send the email
            const [invitations] = await db.query(
                `SELECT mi.id, mi.invitee_email as user_email, mi.status, mi.created_at,
                        u.name AS inviter_name, c.name as circle_name
                 FROM member_invitations mi
                 JOIN users u ON mi.invited_by = u.id
                 LEFT JOIN circles c ON mi.circle_id = c.id
                 WHERE mi.association_id = ? AND mi.status = 'pending' AND mi.token = ''`,
                 [association.id]
            );
            
            const invitationRequests = invitations.map(r => ({
                ...r,
                requestType: 'invitation',
                user_name: 'Pending Invite'
            }));

            pendingRequests = [
                ...circleRequests.map(r => ({ ...r, requestType: 'circle' })),
                ...invitationRequests,
                ...pendingRequests,
            ];
        }

        res.status(200).json({ pendingRequests });
    } catch (error) {
        console.error('Get pending requests error:', error);
        res.status(500).json({ error: 'Failed to get pending requests' });
    }
};

exports.respondToRequest = async (req, res) => {
    try {
        const userId = req.user.id;
        const role = req.user.role;
        const requestId = req.params.requestId;
        const { status, requestType } = req.body; // 'Approved' or 'Rejected', requestType: 'circle' | 'association'

        if (!['Approved', 'Rejected'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        // Members have no access
        if (role === 'member') {
            return res.status(403).json({ error: 'Members cannot respond to requests' });
        }

        // Admins can only handle association (member invitation) requests for circles they created
        if (role === 'admin' && requestType !== 'association') {
            return res.status(403).json({ error: 'Admins can only approve or decline member invitations for their own circles' });
        }

        const association = await Association.findByUserId(userId);
        if (!association) return res.status(403).json({ error: 'No association found' });

        const db = require('../config/db');

        if (requestType === 'invitation') {
            if (role !== 'SA') {
                return res.status(403).json({ error: 'Only Super Admins can respond to invitations.' });
            }
            
            const [invRows] = await db.query('SELECT * FROM member_invitations WHERE id = ? AND association_id = ?', [requestId, association.id]);
            const invitation = invRows[0];
            if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

            if (status === 'Rejected') {
                await db.query('UPDATE member_invitations SET status=? WHERE id=?', ['rejected', requestId]);
            } else if (status === 'Approved') {
                const jwt = require('jsonwebtoken');
                const JWT_SECRET = process.env.JWT_SECRET || 'supersecret';
                const inviteToken = jwt.sign(
                    { email: invitation.invitee_email, associationId: association.id, purpose: 'member_invite', invitationId: invitation.id, inviterRole: 'member' },
                    JWT_SECRET,
                    { expiresIn: '7d' }
                );
                await db.query('UPDATE member_invitations SET token=?, status=? WHERE id=?', [inviteToken, 'pending', requestId]);

                const [inviterRows] = await db.query('SELECT name FROM users WHERE id = ?', [invitation.invited_by]);
                const inviterName = inviterRows[0]?.name || 'A Bantou User';
                
                let circleName = null;
                if (invitation.circle_id) {
                    const [crows] = await db.query('SELECT name FROM circles WHERE id=?', [invitation.circle_id]);
                    circleName = crows[0]?.name || null;
                }

                const { sendMemberInvitationEmail } = require('../config/mailer');
                await sendMemberInvitationEmail(invitation.invitee_email, inviterName, association.name, inviteToken, circleName);
            }
            return res.status(200).json({ message: 'Invitation request handled.' });
        }

        if (requestType === 'association') {
            // For admins: verify this member's invitation is linked to a circle the admin created
            if (role === 'admin') {
                const [adminCheck] = await db.query(
                    `SELECT mi.id FROM member_invitations mi
                     JOIN circles c ON mi.circle_id = c.id
                     WHERE mi.invitee_email = (
                         SELECT email FROM users WHERE id = ?
                     ) AND c.created_by = ? AND mi.association_id = ?`,
                    [requestId, userId, association.id]
                );
                if (adminCheck.length === 0) {
                    return res.status(403).json({ error: 'You can only manage requests for circles you created.' });
                }
            }

            // Handle member joining — allowed for both SA and admin (within scope)
            if (status === 'Approved') {
                await db.query('UPDATE users SET status = ? WHERE id = ?', ['actif', requestId]);
            } else {
                await db.query('DELETE FROM association_members WHERE user_id = ? AND association_id = ?', [requestId, association.id]);
                await db.query('DELETE FROM users WHERE id = ?', [requestId]);
            }
            return res.status(200).json({ message: `Association Join Request ${status.toLowerCase()} successfully` });
        }

        // Circle Access Requests — SA only
        if (role !== 'SA') {
            return res.status(403).json({ error: 'Only Super Admins can respond to circle access requests' });
        }

        const accessRequest = await CircleAccessRequest.findById(requestId);
        if (!accessRequest) {
            return res.status(404).json({ error: 'Access request not found' });
        }

        const circle = await Circle.findById(accessRequest.circle_id);
        if (!association || association.id !== circle.association_id) {
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
        const role = req.user.role;

        const circle = await Circle.findById(circleId);
        if (!circle) return res.status(404).json({ error: 'Circle not found' });

        const db = require('../config/db');

        // Super Admin can join any circle directly without association membership check
        if (role === 'SA') {
            await db.query(
                'INSERT IGNORE INTO circle_members (circle_id, user_id) VALUES (?, ?)',
                [circleId, userId]
            );
            return res.status(200).json({ message: 'Successfully joined the circle.' });
        }

        // Other roles: verify user is in the same association
        const association = await Association.findByUserId(userId);
        if (!association || association.id !== circle.association_id) {
            return res.status(403).json({ error: 'You do not belong to this association.' });
        }

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
                { email: email.trim().toLowerCase(), associationId: association.id, purpose: 'member_invite', invitationId, inviterRole },
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

        // Members, Admins, and Super Admins are all allowed to view participants
        // (Management actions remain restricted in their respective endpoints)

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
                u.profile_picture,
                IF(u.role = 'SA', 1, IF(cm.circle_id IS NOT NULL OR car.status = 'Approved', 1, 0)) as has_joined,
                COALESCE(cm.joined_at, car.updated_at) as joined_at
            FROM users u
            JOIN association_members am ON u.id = am.user_id
            LEFT JOIN circle_members cm ON u.id = cm.user_id AND cm.circle_id = ?
            LEFT JOIN circle_access_requests car ON u.id = car.user_id AND car.circle_id = ?
            WHERE am.association_id = ?
            ORDER BY has_joined DESC, u.name ASC
        `;

        const [participants] = await db.query(query, [circleId, circleId, association.id]);

        // Attach association logo for animation
        const associationLogo = association.logo || null;

        const formattedParticipants = participants.map(p => ({
            id: p.id,
            name: p.name,
            email: p.email,
            role: p.role,
            hasJoined: p.has_joined === 1,
            joinedAt: p.joined_at,
            profilePicture: p.profile_picture || null,
            associationLogo,
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
        const userRole = req.user.role;
        const circleId = req.params.id;

        const access = await checkCirclePhotoAccess(userId, userRole, circleId);
        if (access.error) return res.status(access.status).json({ error: access.error });

        if (!req.file) {
            return res.status(400).json({ error: 'No photo uploaded' });
        }

        const photoUrl = '/uploads/' + req.file.filename;

        // SA and admin photos are auto-approved; member photos go into moderation
        const status = (userRole === 'SA' || userRole === 'admin') ? 'approved' : 'pending';

        const db = require('../config/db');
        const [result] = await db.query(
            'INSERT INTO circle_photos (circle_id, user_id, photo_url, status) VALUES (?, ?, ?, ?)',
            [circleId, userId, photoUrl, status]
        );

        const message = status === 'approved'
            ? 'Photo uploaded successfully'
            : 'Photo submitted for review';

        res.status(201).json({
            message,
            status,
            photo: {
                id: result.insertId,
                url: photoUrl,
                status
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
        const userRole = req.user.role;
        const circleId = req.params.id;

        const access = await checkCirclePhotoAccess(userId, userRole, circleId);
        if (access.error) return res.status(access.status).json({ error: access.error });

        const db = require('../config/db');

        // Admins and SA see all photos (pending + approved) for moderation.
        // Regular members only see approved photos.
        const isPrivileged = userRole === 'SA' || userRole === 'admin';
        const statusFilter = isPrivileged ? `AND cp.status IN ('pending', 'approved')` : `AND cp.status = 'approved'`;

        const query = `
            SELECT cp.id, cp.photo_url, cp.created_at, cp.status, u.name as uploader_name
            FROM circle_photos cp
            JOIN users u ON cp.user_id = u.id
            WHERE cp.circle_id = ? ${statusFilter}
            ORDER BY cp.status ASC, cp.created_at DESC
        `;
        const [photos] = await db.query(query, [circleId]);

        res.status(200).json({ photos });
    } catch (error) {
        console.error('Get photos error:', error);
        res.status(500).json({ error: 'Failed to fetch photos' });
    }
};

/**
 * PUT /api/circles/:id/photos/:photoId/approve
 * Approve a pending photo. Admin and SA only.
 */
exports.approveCirclePhoto = async (req, res) => {
    try {
        const userId = req.user.id;
        const userRole = req.user.role;
        const circleId = req.params.id;
        const photoId = req.params.photoId;

        if (userRole !== 'SA' && userRole !== 'admin') {
            return res.status(403).json({ error: 'Only admins can approve photos.' });
        }

        const access = await checkCirclePhotoAccess(userId, userRole, circleId);
        if (access.error) return res.status(access.status).json({ error: access.error });

        const db = require('../config/db');
        const [result] = await db.query(
            `UPDATE circle_photos SET status = 'approved' WHERE id = ? AND circle_id = ?`,
            [photoId, circleId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Photo not found.' });
        }

        res.status(200).json({ message: 'Photo approved successfully.' });
    } catch (error) {
        console.error('Approve photo error:', error);
        res.status(500).json({ error: 'Failed to approve photo' });
    }
};

/**
 * DELETE /api/circles/:id/photos/:photoId
 * Reject/delete a photo. Admin and SA only.
 */
exports.rejectCirclePhoto = async (req, res) => {
    try {
        const userId = req.user.id;
        const userRole = req.user.role;
        const circleId = req.params.id;
        const photoId = req.params.photoId;

        if (userRole !== 'SA' && userRole !== 'admin') {
            return res.status(403).json({ error: 'Only admins can reject photos.' });
        }

        const access = await checkCirclePhotoAccess(userId, userRole, circleId);
        if (access.error) return res.status(access.status).json({ error: access.error });

        const db = require('../config/db');

        // Fetch the photo record first so we can delete the file from disk
        const [rows] = await db.query(
            'SELECT photo_url FROM circle_photos WHERE id = ? AND circle_id = ?',
            [photoId, circleId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Photo not found.' });
        }

        // Delete from DB
        await db.query(
            'DELETE FROM circle_photos WHERE id = ? AND circle_id = ?',
            [photoId, circleId]
        );

        // Attempt to delete the physical file (non-fatal if missing)
        try {
            const path = require('path');
            const fs = require('fs');
            const filePath = path.join(__dirname, '..', rows[0].photo_url);
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
        } catch (fsErr) {
            console.error('Could not delete photo file:', fsErr);
        }

        res.status(200).json({ message: 'Photo rejected and removed.' });
    } catch (error) {
        console.error('Reject photo error:', error);
        res.status(500).json({ error: 'Failed to reject photo' });
    }
};
