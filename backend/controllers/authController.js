require('dotenv').config();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const Association = require('../models/Association');
const { sendOtpEmail, sendAdminInvitationEmail, sendMemberInvitationEmail } = require('../config/mailer');

// ─── JWT helpers ─────────────────────────────────────────────────────────────
const JWT_SECRET = process.env.JWT_SECRET || 'bantou_dev_secret_change_in_prod';
const JWT_EXPIRES = '7d';

function signToken(user) {
    return jwt.sign(
        { id: user.id, email: user.email, name: user.name, role: user.role },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES }
    );
}

// ─── Google OAuth client ──────────────────────────────────────────────────────
const googleClient = new OAuth2Client(
    '744799157092-klp2t0h00bjfg0ps2166k6a4fn7c7ndb.apps.googleusercontent.com'
);

// ─── Controllers ─────────────────────────────────────────────────────────────

/**
 * POST /auth/signup
 * Body: { name, email, password, phone? }
 */
exports.signup = async (req, res, next) => {
    try {
        const { name, email, phone, password, inviteToken } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ error: 'Name, email, and password are required.' });
        }

        const existing = await User.findByEmail(email);
        if (existing) {
            return res.status(409).json({ error: 'An account with this email already exists.' });
        }

        // ── Invite token detection (admin_invite OR member_invite) ──
        let invitedAssoc = null;
        let isInvitedByToken = false;
        let invitedRole = null; // 'admin' | 'member' | null
        let invitedInviterRole = null; // 'SA' | 'admin' | 'member'

        if (inviteToken) {
            try {
                const payload = jwt.verify(inviteToken, JWT_SECRET);
                if (payload.purpose === 'admin_invite' || payload.purpose === 'member_invite') {
                    isInvitedByToken = true;
                    invitedRole = payload.purpose === 'member_invite' ? 'member' : 'admin';
                    invitedInviterRole = payload.inviterRole || 'SA'; // default to SA for backwards compat
                    // Link to the association stored in the token
                    if (payload.associationId) {
                        const db = require('../config/db');
                        const [rows] = await db.query(
                            'SELECT * FROM associations WHERE id = ?',
                            [payload.associationId]
                        );
                        invitedAssoc = rows[0] || null;
                    }
                    console.log(`[SIGNUP] Valid ${payload.purpose} token. Role: ${invitedRole}. Assoc: ${invitedAssoc ? invitedAssoc.name : 'NONE'}`);

                    // Mark the member_invitation as accepted
                    if (payload.purpose === 'member_invite' && payload.invitationId) {
                        const db = require('../config/db');
                        await db.query(
                            `UPDATE member_invitations SET status='accepted' WHERE id=?`,
                            [payload.invitationId]
                        );
                    }
                }
            } catch (e) {
                console.warn('[SIGNUP] Invalid or expired inviteToken:', e.message);
            }
        }

        // Fallback email-based lookup only for admin (not member — members MUST have a valid token)
        if (!invitedAssoc && invitedRole !== 'member') {
            invitedAssoc = await Association.findByAdminEmail(email);
            if (invitedAssoc) {
                invitedRole = invitedRole || 'admin';
                console.log(`[SIGNUP] Email-based admin match for "${email}" → assoc: ${invitedAssoc.name}`);
            }
        }

        // Final role decision
        let role, status;
        if (invitedRole === 'member' && invitedAssoc) {
            role = 'member'; 
            status = invitedInviterRole === 'member' ? 'en attente' : 'actif';
        } else if (invitedRole === 'admin' || invitedAssoc) {
            role = 'admin'; 
            status = 'actif';
        } else {
            role = 'SA'; 
            status = 'actif';
        }
        console.log(`[SIGNUP] Final Role for "${email}": ${role}`);

        const passwordHash = await bcrypt.hash(password, 10);
        const id = await User.create({ name, email, phone, passwordHash, role, status });

        // Link to association if invited (admin or member)
        if (invitedAssoc) {
            const db = require('../config/db');
            await db.query(
                `INSERT IGNORE INTO association_members (association_id, user_id) VALUES (?, ?)`,
                [invitedAssoc.id, id]
            );
            await User.markOnboardingSeen(id);
        }

        const token = signToken({ id, email, name, role });
        res.status(201).json({
            message: 'Account created successfully.',
            token,
            role,
            status,
            isInvitedAdmin: role === 'admin',
            isMember: role === 'member',
            profileSetupSeen: false,
            onboardingSeen: !!(invitedAssoc || role === 'member'),
            user: { id, name, email, role, status },
        });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/login
 * Body: { email, password }
 */
exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required.' });
        }

        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        // Support both bcrypt hashes and legacy plaintext passwords
        let match = false;
        if (user.password) {
            match = await bcrypt.compare(password, user.password).catch(() => false);

            // Upgrade plaintext passwords to bcrypt on the fly
            if (!match && password === user.password) {
                match = true;
                const newHash = await bcrypt.hash(password, 10);
                await User.updatePassword(email, newHash);
            }
        }

        if (!match) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        const token = signToken(user);
        res.status(200).json({
            message: 'Login successful.',
            token,
            role: user.role,
            status: user.status,
            isInvitedAdmin: user.role === 'admin',
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            user: { id: user.id, name: user.name, email: user.email, role: user.role, status: user.status },
        });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/forgot-password
 * Body: { email }
 */
exports.forgotPassword = async (req, res, next) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: 'Email is required.' });

        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(404).json({ error: 'No account found with this email.' });
        }

        const otp = crypto.randomInt(100000, 999999).toString();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

        await User.saveOtp(email, otp, expiresAt);
        await sendOtpEmail(email, otp);

        res.status(200).json({ message: 'OTP sent to your email address.' });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/verify-otp
 * Body: { email, otp }
 */
exports.verifyOtp = async (req, res, next) => {
    try {
        const { email, otp } = req.body;
        if (!email || !otp) {
            return res.status(400).json({ error: 'Email and OTP are required.' });
        }

        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(404).json({ error: 'No account found with this email.' });
        }

        if (!user.otp_code || !user.otp_expires_at) {
            return res.status(400).json({ error: 'No OTP was requested for this account.' });
        }

        if (user.otp_code !== otp) {
            return res.status(400).json({ error: 'Invalid verification code.' });
        }

        if (new Date() > new Date(user.otp_expires_at)) {
            return res.status(400).json({ error: 'This code has expired. Please request a new one.' });
        }

        res.status(200).json({ message: 'OTP verified successfully.' });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/reset-password
 * Body: { email, otp, newPassword }
 */
exports.resetPassword = async (req, res, next) => {
    try {
        const { email, otp, newPassword } = req.body;
        if (!email || !otp || !newPassword) {
            return res.status(400).json({ error: 'Email, OTP, and new password are required.' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ error: 'Password must be at least 6 characters.' });
        }

        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(404).json({ error: 'No account found with this email.' });
        }

        if (!user.otp_code || user.otp_code !== otp) {
            return res.status(400).json({ error: 'Invalid or missing verification code.' });
        }
        if (new Date() > new Date(user.otp_expires_at)) {
            return res.status(400).json({ error: 'Verification code has expired.' });
        }

        const passwordHash = await bcrypt.hash(newPassword, 10);
        await User.updatePassword(email, passwordHash);
        await User.clearOtp(email);

        res.status(200).json({ message: 'Password updated successfully.' });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/google
 * Body: { idToken }
 */
exports.googleSignIn = async (req, res, next) => {
    try {
        const { idToken } = req.body;
        if (!idToken) {
            return res.status(400).json({ error: 'Google ID token is required.' });
        }

        const ticket = await googleClient.verifyIdToken({
            idToken,
            audience: [
                '744799157092-klp2t0h00bjfg0ps2166k6a4fn7c7ndb.apps.googleusercontent.com',
                '744799157092-b8fa9r6b5f7a0ei4jp209ublkgucrhq7.apps.googleusercontent.com',
            ],
        });

        const payload = ticket.getPayload();
        const { sub: googleId, email, name } = payload;

        if (!email) {
            return res.status(400).json({ error: 'Google account has no email address.' });
        }

        const existing = await User.findByEmail(email);
        const invitedAssoc = !existing ? await Association.findByAdminEmail(email) : null;
        const role = invitedAssoc ? 'admin' : 'SA';

        const user = await User.findOrCreateGoogleUser({ googleId, email, name, role });

        if (invitedAssoc && !existing) {
            const db = require('../config/db');
            await db.query(
                `INSERT IGNORE INTO association_members (association_id, user_id) VALUES (?, ?)`,
                [invitedAssoc.id, user.id]
            );
            await User.markOnboardingSeen(user.id);
            user.onboarding_seen = 1;
        }

        const token = signToken(user);
        res.status(200).json({
            message: 'Google sign-in successful.',
            token,
            role: user.role || role,
            status: user.status,
            isInvitedAdmin: (user.role || role) === 'admin',
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            user: { id: user.id, name: user.name, email: user.email, role: user.role, status: user.status },
        });
    } catch (err) {
        if (err.message && err.message.includes('Token used too late')) {
            return res.status(401).json({ error: 'Google token expired. Please try again.' });
        }
        if (err.message && err.message.includes('Invalid token signature')) {
            return res.status(401).json({ error: 'Invalid Google token.' });
        }
        next(err);
    }
};

/**
 * POST /auth/facebook
 * Body: { accessToken }
 */
exports.facebookSignIn = async (req, res, next) => {
    try {
        const { accessToken } = req.body;
        if (!accessToken) {
            return res.status(400).json({ error: 'Facebook access token is required.' });
        }

        const appId = process.env.FACEBOOK_APP_ID;
        const appSecret = process.env.FACEBOOK_APP_SECRET;

        const verifyUrl = `https://graph.facebook.com/debug_token?input_token=${accessToken}&access_token=${appId}|${appSecret}`;
        const verifyRes = await fetch(verifyUrl);
        const verifyData = await verifyRes.json();

        if (!verifyData.data || !verifyData.data.is_valid) {
            return res.status(401).json({ error: 'Invalid or expired Facebook access token.' });
        }

        if (verifyData.data.app_id !== appId) {
            return res.status(401).json({ error: 'Facebook token belongs to a different app.' });
        }

        const profileRes = await fetch(
            `https://graph.facebook.com/me?fields=id,name,email&access_token=${accessToken}`
        );
        const profile = await profileRes.json();

        if (!profile.id) {
            return res.status(400).json({ error: 'Could not fetch Facebook user profile.' });
        }

        const { id: facebookId, name, email } = profile;

        const existing = email ? await User.findByEmail(email) : null;
        const invitedAssoc = (!existing && email) ? await Association.findByAdminEmail(email) : null;
        const role = invitedAssoc ? 'admin' : 'SA';

        const user = await User.findOrCreateFacebookUser({ facebookId, email, name, role });

        if (invitedAssoc && !existing) {
            const db = require('../config/db');
            await db.query(
                `INSERT IGNORE INTO association_members (association_id, user_id) VALUES (?, ?)`,
                [invitedAssoc.id, user.id]
            );
            await User.markOnboardingSeen(user.id);
            user.onboarding_seen = 1;
        }

        const token = signToken(user);
        res.status(200).json({
            message: 'Facebook sign-in successful.',
            token,
            role: user.role || role,
            status: user.status,
            isInvitedAdmin: (user.role || role) === 'admin',
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            user: { id: user.id, name: user.name, email: user.email, role: user.role, status: user.status },
        });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/update-profile
 * Body: { company, jobTitle, communityRole, city, bio, website, avatarIndex }
 * Requires JWT via authMiddleware
 */
exports.updateProfile = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const profileData = req.body;

        await User.updateProfile(userId, profileData);
        await User.markProfileSetupSeen(userId);

        // NOTE: Admin users NEVER get upgraded to SA.
        // Role assignments are permanent and set at invitation time.
        res.status(200).json({
            message: 'Profile updated successfully.',
            upgraded: false,
        });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/change-password
 * Body: { currentPassword, newPassword }
 * Requires JWT via authMiddleware
 */
exports.changePassword = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ error: 'Current password and new password are required.' });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({ error: 'New password must be at least 6 characters.' });
        }

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }

        if (!user.password) {
            return res.status(400).json({ error: 'Your account uses social login. You cannot change the password.' });
        }

        const match = await bcrypt.compare(currentPassword, user.password).catch(() => false);
        if (!match && currentPassword !== user.password) {
            return res.status(401).json({ error: 'Incorrect current password.' });
        }

        const passwordHash = await bcrypt.hash(newPassword, 10);
        await User.updatePassword(user.email, passwordHash);

        res.status(200).json({ message: 'Password updated successfully.' });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/profile
 * Returns the currently authenticated user's profile data.
 */
exports.getProfile = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }

        res.status(200).json({
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role,
            status: user.status,
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            company: user.company,
            jobTitle: user.job_title,
            communityRole: user.community_role,
            city: user.city,
            bio: user.bio,
            website: user.website,
            avatarIndex: user.avatar_index,
            profilePicture: user.profile_picture || null,
        });
    } catch (err) {
        next(err);
    }
};

/**
 * POST /auth/mark-setup-seen
 * Called when the user skips the profile setup screen.
 */
exports.markSetupSeen = async (req, res, next) => {
    try {
        const userId = req.user.id;
        await User.markProfileSetupSeen(userId);
        res.status(200).json({ message: 'Profile setup marked as seen.' });
    } catch (err) {
        next(err);
    }
};

// ─── Association Controllers ──────────────────────────────────────────────────

// Add near the top: email validation regex
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Helper to safely parse JSON strings from the DB
const safeParse = (val) => {
    if (!val) return [];
    try { return typeof val === 'string' ? JSON.parse(val) : val; }
    catch { return []; }
};

/**
 * POST /auth/association
 * Body: { name, address, contactEmails, contactPhones, adminEmails, facebookUrl, linkedinUrl, twitterUrl }
 * Requires JWT via authMiddleware
 * Saves the association and marks onboarding as seen.
 */
exports.createAssociation = async (req, res, next) => {
    try {
        // Only Super Admins can create or modify association information.
        if (req.user.role !== 'SA') {
            return res.status(403).json({ error: 'Only Super Admins can modify association information.' });
        }

        const userId = req.user.id;
        const {
            name,
            address,
            contactEmails,
            contactPhones,
            adminEmails,
            memberEmails,
            facebookUrl,
            linkedinUrl,
            twitterUrl,
        } = req.body;

        if (!name) {
            return res.status(400).json({ error: 'Association name is required.' });
        }

        // Validate admin email formats — always store lowercased to avoid mismatch
        let cleanAdminEmails = [];
        if (adminEmails && Array.isArray(adminEmails)) {
            for (const email of adminEmails) {
                const trimmed = email.trim().toLowerCase();
                if (trimmed) {
                    if (!EMAIL_REGEX.test(trimmed)) {
                        return res.status(400).json({ error: `Invalid email format: ${trimmed}` });
                    }
                    cleanAdminEmails.push(trimmed);
                }
            }
        }

        // Validate member email formats
        let cleanMemberEmails = [];
        if (memberEmails && Array.isArray(memberEmails)) {
            for (const email of memberEmails) {
                const trimmed = email.trim().toLowerCase();
                if (trimmed) {
                    if (!EMAIL_REGEX.test(trimmed)) {
                        return res.status(400).json({ error: `Invalid email format: ${trimmed}` });
                    }
                    cleanMemberEmails.push(trimmed);
                }
            }
        }

        // Check for newly added admins to send invitations
        let newlyAddedEmails = [];
        let newlyAddedMemberEmails = [];
        const existingAssoc = await Association.findByUserId(userId);
        if (existingAssoc && existingAssoc.admin_emails) {
            const oldAdmins = safeParse(existingAssoc.admin_emails);
            console.log(`[ASSOC] Found existing assoc: "${existingAssoc.name}". Old admins:`, oldAdmins);
            newlyAddedEmails = cleanAdminEmails.filter(email => !oldAdmins.includes(email));
        } else {
            // First time setting up association, all are new
            console.log(`[ASSOC] No existing association found for userId: ${userId} (admins)`);
            newlyAddedEmails = [...cleanAdminEmails];
        }
        console.log(`[ASSOC] Newly added admin emails to invite:`, newlyAddedEmails);

        // Check for newly added members to send invitations
        if (existingAssoc && existingAssoc.member_emails) {
            const oldMembers = safeParse(existingAssoc.member_emails);
            console.log(`[ASSOC] Found existing assoc: "${existingAssoc.name}". Old members:`, oldMembers);
            newlyAddedMemberEmails = cleanMemberEmails.filter(email => !oldMembers.includes(email));
        } else {
            console.log(`[ASSOC] No existing association found for userId: ${userId} (members)`);
            newlyAddedMemberEmails = [...cleanMemberEmails];
        }
        console.log(`[ASSOC] Newly added member emails to invite:`, newlyAddedMemberEmails);

        await Association.createOrUpdate(userId, {
            name,
            address,
            logoUrl: null, // logo upload to be handled separately if needed
            contactEmails,
            contactPhones,
            adminEmails: cleanAdminEmails,
            memberEmails: cleanMemberEmails,
            facebookUrl,
            linkedinUrl,
            twitterUrl,
        });

        // Mark onboarding complete
        await User.markOnboardingSeen(userId);

        // Fetch newly created association to get its ID for the members table
        const newAssoc = await Association.findByUserId(userId);
        if (newAssoc) {
            const db = require('../config/db');
            await db.query(
                `INSERT IGNORE INTO association_members (association_id, user_id) VALUES (?, ?)`,
                [newAssoc.id, userId]
            );
        }

        // Send invitations to newly added admins asynchronously
        const generatedInviteTokens = {};
        // Use the name from the JWT (req.user.name) if available, fallback to DB if missing
        let inviterName = req.user.name;
        if (!inviterName) {
            const inviterUser = await User.findById(userId);
            inviterName = inviterUser ? inviterUser.name : 'A Bantou User';
        }

        for (const email of newlyAddedEmails) {
            // Generate a signed invite token — includes associationId so signup can
            // look up the association directly without relying on email matching.
            const inviteToken = jwt.sign(
                { email, associationId: newAssoc ? newAssoc.id : null, purpose: 'admin_invite' },
                JWT_SECRET,
                { expiresIn: '7d' }
            );
            generatedInviteTokens[email] = inviteToken;
            console.log(`[ASSOC] Sending admin invitation to: ${email} (Inviter: ${inviterName})`);
            await sendAdminInvitationEmail(email, inviterName, name, inviteToken).then(() => {
                console.log(`[ASSOC] SUCCESS: Admin invitation sent to ${email}`);
            }).catch(err => {
                console.error(`[ASSOC] ERROR: Failed to send admin invitation to ${email}:`, err);
            });
        }

        // Send invitations to newly added members asynchronously
        for (const email of newlyAddedMemberEmails) {
            const inviteToken = jwt.sign(
                { email, associationId: newAssoc ? newAssoc.id : null, purpose: 'member_invite' },
                JWT_SECRET,
                { expiresIn: '7d' }
            );
            generatedInviteTokens[email] = inviteToken;
            console.log(`[ASSOC] Sending member invitation to: ${email} (Inviter: ${inviterName})`);
            await sendMemberInvitationEmail(email, inviterName, name, inviteToken).then(() => {
                console.log(`[ASSOC] SUCCESS: Member invitation sent to ${email}`);
            }).catch(err => {
                console.error(`[ASSOC] ERROR: Failed to send member invitation to ${email}:`, err);
            });
        }

        res.status(200).json({
            message: 'Association saved successfully.',
            // Tokens included for debugging / testing — harmless since they're JWTs needing the secret
            inviteTokens: generatedInviteTokens,
        });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/association
 * Returns the currently authenticated user's association data.
 */
exports.getAssociation = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const association = await Association.findByUserId(userId);

        if (!association) {
            return res.status(404).json({ error: 'No association found.' });
        }

        // Helper to safely parse JSON strings from the DB
        const safeParse = (val) => {
            if (!val) return [];
            try { return typeof val === 'string' ? JSON.parse(val) : val; }
            catch { return []; }
        };

        res.status(200).json({
            id: association.id,
            name: association.name,
            address: association.address,
            logoUrl: association.logo,
            contactEmails: safeParse(association.contact_emails),
            contactPhones: safeParse(association.contact_phones),
            adminEmails: safeParse(association.admin_emails),
            memberEmails: safeParse(association.member_emails),
            facebookUrl: association.fb_link,
            linkedinUrl: association.linkedin_link,
            twitterUrl: association.twitter_link,
        });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/invite/:token
 * Public endpoint — validates the invite JWT and returns email + association context.
 * Used by the Flutter app when it receives a deep link to pre-fill the Sign Up form.
 */
exports.validateInviteToken = async (req, res, next) => {
    try {
        const { token } = req.params;
        if (!token) {
            return res.status(400).json({ error: 'Invite token is required.' });
        }

        let payload;
        try {
            payload = jwt.verify(token, JWT_SECRET);
        } catch (err) {
            return res.status(401).json({ error: 'This invitation link has expired or is invalid.' });
        }

        if (!['admin_invite', 'member_invite'].includes(payload.purpose) || !payload.email) {
            return res.status(400).json({ error: 'Invalid invitation token.' });
        }

        // Check if the user already has an account
        const existing = await User.findByEmail(payload.email);
        if (existing) {
            return res.status(409).json({ error: 'An account with this email already exists. Please log in instead.' });
        }

        // Find the association — prefer the stored associationId in the token
        let assoc = null;
        if (payload.associationId) {
            const db = require('../config/db');
            const [rows] = await db.query('SELECT * FROM associations WHERE id = ?', [payload.associationId]);
            assoc = rows[0] || null;
        }
        // Fallback to email-based lookup for older tokens without associationId
        if (!assoc) {
            assoc = await Association.findByAdminEmail(payload.email);
        }

        res.status(200).json({
            email: payload.email,
            associationId: assoc ? assoc.id : null,
            associationName: assoc ? assoc.name : null,
            role: payload.purpose === 'member_invite' ? 'member' : 'admin',
        });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/invite-redirect/:token
 * Serves an HTML page that auto-redirects to bantou://invite?token=...
 * Email clients don't make bantou:// links clickable, so the email links here (http://),
 * and this page immediately bounces the user into the app.
 */
exports.inviteRedirect = (req, res) => {
    const { token } = req.params;
    const deepLink = `bantou://invite?token=${encodeURIComponent(token)}`;

    res.setHeader('Content-Type', 'text/html');
    res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Join Bantou</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      background: linear-gradient(135deg, #C9A84C, #8B6914);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: #fff;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      box-shadow: 0 12px 40px rgba(0,0,0,0.2);
    }
    .logo { font-size: 32px; font-weight: 800; color: #C9A84C; letter-spacing: 2px; }
    .slogan { color: #aaa; font-size: 12px; margin-top: 4px; margin-bottom: 28px; }
    h2 { color: #3D2B00; font-size: 22px; margin-bottom: 12px; }
    p { color: #6B5020; font-size: 14px; line-height: 1.6; margin-bottom: 28px; }
    .btn {
      display: block;
      background: linear-gradient(135deg, #C9A84C, #8B6914);
      color: #fff;
      text-decoration: none;
      padding: 16px 24px;
      border-radius: 12px;
      font-size: 16px;
      font-weight: 700;
      margin-bottom: 16px;
    }
    .note { color: #bbb; font-size: 11px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">Bantou</div>
    <div class="slogan">Je suis parce que nous sommes</div>
    <h2>You've been invited!</h2>
    <p>Tap the button below to open the Bantou app and create your administrator account.</p>
    <a href="${deepLink}" class="btn">Open Bantou App &rarr;</a>
    <div class="note">Make sure the Bantou app is installed on your device.<br/>This invitation expires in 7 days.</div>
  </div>
  <script>
    // Auto-attempt to open the app when page loads
    setTimeout(function() {
      window.location.href = '${deepLink}';
    }, 300);
  </script>
</body>
</html>`);
};

// ─── Member Invitation Controllers ───────────────────────────────────────────

/**
 * POST /auth/invite-member
 * SA or member invites a new user as a member.
 * Body: { email, circleId? }
 * - SA: invitation is sent immediately.
 * - member: creates a pending invitation that the SA must approve before the email is sent.
 */
exports.inviteMember = async (req, res, next) => {
    try {
        const inviterId = req.user.id;
        const inviterRole = req.user.role;
        const { email, circleId } = req.body;

        if (!email) {
            return res.status(400).json({ error: 'Email is required.' });
        }

        if (!['SA', 'admin', 'member'].includes(inviterRole)) {
            return res.status(403).json({ error: 'Not authorized to invite members.' });
        }

        // Check if the invitee already has an account
        const existing = await User.findByEmail(email.trim().toLowerCase());
        if (existing) {
            return res.status(409).json({ error: 'A user with this email already has an account.' });
        }

        // Find the inviter's association
        const assoc = await Association.findByUserId(inviterId);
        if (!assoc) {
            return res.status(404).json({ error: 'No association found.' });
        }

        // Look up circle name if circleId provided
        let circleName = null;
        if (circleId) {
            const db = require('../config/db');
            const [crows] = await db.query('SELECT name FROM circles WHERE id = ?', [circleId]);
            circleName = crows[0]?.name || null;
        }

        // Get inviter name
        let inviterName = req.user.name;
        if (!inviterName) {
            const inviterUser = await User.findById(inviterId);
            inviterName = inviterUser?.name || 'A Bantou User';
        }

        const db = require('../config/db');

        // Create invitation record + generate token + send email immediately for ALL allowlisted roles
        const [invRow] = await db.query(
            `INSERT INTO member_invitations (association_id, invited_by, invitee_email, circle_id, token, status)
             VALUES (?, ?, ?, ?, '', 'pending')`,
            [assoc.id, inviterId, email.trim().toLowerCase(), circleId || null]
        );
        const invitationId = invRow.insertId;

        const inviteToken = jwt.sign(
            { email: email.trim().toLowerCase(), associationId: assoc.id, purpose: 'member_invite', invitationId, inviterRole },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        await db.query('UPDATE member_invitations SET token=?, status=? WHERE id=?',
            [inviteToken, 'pending', invitationId]);

        await sendMemberInvitationEmail(email.trim().toLowerCase(), inviterName, assoc.name, inviteToken, circleName);

        return res.status(200).json({ message: 'Member invitation sent successfully.' });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/sa-dashboard
 * SA-only. Returns members list, admins list, circles with admin info.
 */
exports.getSADashboard = async (req, res, next) => {
    try {
        if (req.user.role !== 'SA') {
            return res.status(403).json({ error: 'Only Super Admins can access this dashboard.' });
        }

        const assoc = await Association.findByUserId(req.user.id);
        if (!assoc) {
            return res.status(404).json({ error: 'No association found.' });
        }

        const db = require('../config/db');

        // Members (role='member')
        const [members] = await db.query(
            `SELECT u.id, u.name, u.email, u.status, u.created_at
             FROM users u
             JOIN association_members am ON u.id = am.user_id
             WHERE am.association_id = ? AND u.role = 'member'
             ORDER BY u.name`,
            [assoc.id]
        );

        // Admins (role='admin' or 'SA')
        const [admins] = await db.query(
            `SELECT u.id, u.name, u.email, u.role, u.status, u.created_at
             FROM users u
             JOIN association_members am ON u.id = am.user_id
             WHERE am.association_id = ? AND u.role IN ('SA','admin')
             ORDER BY u.role, u.name`,
            [assoc.id]
        );

        // Circles with responsible admin info
        const [circles] = await db.query(
            `SELECT c.id, c.name, c.description, c.city, c.country, c.status,
                    c.responsible, c.vice_responsible, c.meeting_planning,
                    u.name AS creator_name, u.email AS creator_email
             FROM circles c
             LEFT JOIN users u ON c.created_by = u.id
             WHERE c.association_id = ?
             ORDER BY c.name`,
            [assoc.id]
        );

        return res.status(200).json({ members, admins, circles, associationName: assoc.name });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/member-invitations/pending
 * SA-only. Returns pending member invitations (submitted by members, not yet sent).
 */
exports.getPendingMemberInvitations = async (req, res, next) => {
    try {
        if (req.user.role !== 'SA') {
            return res.status(403).json({ error: 'Only Super Admins can view pending invitations.' });
        }

        const assoc = await Association.findByUserId(req.user.id);
        if (!assoc) {
            return res.status(404).json({ error: 'No association found.' });
        }

        const db = require('../config/db');
        const [rows] = await db.query(
            `SELECT mi.id, mi.invitee_email, mi.status, mi.created_at, mi.circle_id,
                    u.name AS inviter_name, u.email AS inviter_email,
                    c.name AS circle_name
             FROM member_invitations mi
             JOIN users u ON mi.invited_by = u.id
             LEFT JOIN circles c ON mi.circle_id = c.id
             WHERE mi.association_id = ? AND mi.status = 'pending' AND mi.token = ''
             ORDER BY mi.created_at DESC`,
            [assoc.id]
        );

        return res.status(200).json({ pendingInvitations: rows });
    } catch (err) {
        next(err);
    }
};

/**
 * PUT /auth/member-invitations/:id/respond
 * SA-only. Approve or reject a pending member invitation (submitted by non-SA members).
 * Body: { action: 'approve' | 'reject' }
 */
exports.respondToMemberInvitation = async (req, res, next) => {
    try {
        if (req.user.role !== 'SA') {
            return res.status(403).json({ error: 'Only Super Admins can respond to invitations.' });
        }

        const { id } = req.params;
        const { action } = req.body; // 'approve' | 'reject'

        if (!['approve', 'reject'].includes(action)) {
            return res.status(400).json({ error: 'Action must be approve or reject.' });
        }

        const assoc = await Association.findByUserId(req.user.id);
        if (!assoc) return res.status(404).json({ error: 'No association found.' });

        const db = require('../config/db');
        const [invRows] = await db.query('SELECT * FROM member_invitations WHERE id = ?', [id]);
        const invitation = invRows[0];
        if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });
        if (invitation.association_id !== assoc.id) {
            return res.status(403).json({ error: 'Not authorized.' });
        }

        if (action === 'reject') {
            await db.query('UPDATE member_invitations SET status=? WHERE id=?', ['rejected', id]);
            return res.status(200).json({ message: 'Invitation rejected.' });
        }

        // approve: generate token and send the email
        const inviterUser = await User.findById(req.user.id);
        const inviterName = inviterUser?.name || 'Super Admin';

        // Look up circle name
        let circleName = null;
        if (invitation.circle_id) {
            const [crows] = await db.query('SELECT name FROM circles WHERE id=?', [invitation.circle_id]);
            circleName = crows[0]?.name || null;
        }

        const inviteToken = jwt.sign(
            { email: invitation.invitee_email, associationId: assoc.id, purpose: 'member_invite', invitationId: invitation.id },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        await db.query('UPDATE member_invitations SET token=?, status=? WHERE id=?',
            [inviteToken, 'pending', id]);

        await sendMemberInvitationEmail(invitation.invitee_email, inviterName, assoc.name, inviteToken, circleName);

        return res.status(200).json({ message: 'Invitation approved and email sent.' });
    } catch (err) {
        next(err);
    }
};

/**
 * GET /auth/association/members
 * Returns a list of members in the user's association.
 * SA or Admin only.
 */
exports.getAssociationMembers = async (req, res, next) => {
    try {
        if (req.user.role !== 'SA' && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'Only SA and Admins can view association members.' });
        }

        const assoc = await Association.findByUserId(req.user.id);
        if (!assoc) {
            return res.status(404).json({ error: 'No association found.' });
        }

        const db = require('../config/db');
        const [members] = await db.query(
            `SELECT u.id, u.name, u.email, u.role, u.status, u.profile_picture 
             FROM users u 
             JOIN association_members am ON u.id = am.user_id 
             WHERE am.association_id = ?`,
            [assoc.id]
        );

        // Include association logo for the animation feature
        const membersWithLogo = members.map(m => ({
            ...m,
            profilePicture: m.profile_picture || null,
            associationLogo: assoc.logo || null,
        }));

        res.status(200).json(membersWithLogo);
    } catch (err) {
        next(err);
    }
};

// ─── Association Logo Controllers ────────────────────────────────────────────

/**
 * POST /auth/association/logo
 * Accepts multipart/form-data with field 'logo'.
 * Saves the logo path to associations.logo for the current user's association.
 */
exports.uploadAssociationLogo = async (req, res, next) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No logo file provided.' });
        }

        const assoc = await Association.findByUserId(req.user.id);
        if (!assoc) {
            return res.status(404).json({ error: 'No association found.' });
        }

        const relativePath = '/uploads/logos/' + req.file.filename;

        // Delete old logo file if it exists and is not a mock
        if (assoc.logo && !assoc.logo.includes('mock_')) {
            const oldFilePath = path.join(__dirname, '..', assoc.logo);
            if (fs.existsSync(oldFilePath)) {
                try { fs.unlinkSync(oldFilePath); } catch (_) {}
            }
        }

        const db = require('../config/db');
        await db.query('UPDATE associations SET logo = ? WHERE id = ?', [relativePath, assoc.id]);

        res.status(200).json({
            message: 'Association logo uploaded successfully.',
            logoUrl: relativePath,
        });
    } catch (err) {
        next(err);
    }
};

/**
 * DELETE /auth/association/logo
 * Removes the association logo from disk and clears the DB field.
 */
exports.deleteAssociationLogo = async (req, res, next) => {
    try {
        const assoc = await Association.findByUserId(req.user.id);
        if (!assoc) {
            return res.status(404).json({ error: 'No association found.' });
        }

        if (assoc.logo && !assoc.logo.includes('mock_')) {
            const filePath = path.join(__dirname, '..', assoc.logo);
            if (fs.existsSync(filePath)) {
                try { fs.unlinkSync(filePath); } catch (_) {}
            }
        }

        const db = require('../config/db');
        await db.query('UPDATE associations SET logo = NULL WHERE id = ?', [assoc.id]);

        res.status(200).json({ message: 'Association logo removed successfully.' });
    } catch (err) {
        next(err);
    }
};

// ─── Profile Picture Controllers ──────────────────────────────────────────────


/**
 * POST /auth/upload-profile-picture
 * Accepts multipart/form-data with field 'profilePicture'.
 * Saves the file path to users.profile_picture.
 */
exports.uploadProfilePicture = async (req, res, next) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided.' });
        }

        const userId = req.user.id;
        const relativePath = '/uploads/profiles/' + req.file.filename;

        // Delete old profile picture file if it exists
        const user = await User.findById(userId);
        if (user && user.profile_picture && !user.profile_picture.includes('mock_')) {
            const oldPath = path.join(__dirname, '..', user.profile_picture);
            if (fs.existsSync(oldPath)) {
                try { fs.unlinkSync(oldPath); } catch (_) {}
            }
        }

        const db = require('../config/db');
        await db.query('UPDATE users SET profile_picture = ? WHERE id = ?', [relativePath, userId]);

        res.status(200).json({
            message: 'Profile picture uploaded successfully.',
            profilePictureUrl: relativePath,
        });
    } catch (err) {
        next(err);
    }
};

/**
 * DELETE /auth/profile-picture
 * Clears users.profile_picture and deletes the file from disk.
 */
exports.deleteProfilePicture = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }

        if (user.profile_picture && !user.profile_picture.includes('mock_')) {
            const filePath = path.join(__dirname, '..', user.profile_picture);
            if (fs.existsSync(filePath)) {
                try { fs.unlinkSync(filePath); } catch (_) {}
            }
        }

        const db = require('../config/db');
        await db.query('UPDATE users SET profile_picture = NULL WHERE id = ?', [userId]);

        res.status(200).json({ message: 'Profile picture removed successfully.' });
    } catch (err) {
        next(err);
    }
};
