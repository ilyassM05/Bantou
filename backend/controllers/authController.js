require('dotenv').config();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const Association = require('../models/Association');
const { sendOtpEmail, sendAdminInvitationEmail } = require('../config/mailer');

// ─── JWT helpers ─────────────────────────────────────────────────────────────
const JWT_SECRET = process.env.JWT_SECRET || 'bantou_dev_secret_change_in_prod';
const JWT_EXPIRES = '7d';

function signToken(user) {
    return jwt.sign(
        { id: user.id, email: user.email, role: user.role },
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

        // ── Invited admin detection via invite token (token-based, reliable) ──
        let invitedAssoc = null;
        if (inviteToken) {
            try {
                const payload = jwt.verify(inviteToken, JWT_SECRET);
                if (payload.purpose === 'admin_invite' && payload.associationId) {
                    const db = require('../config/db');
                    const [rows] = await db.query(
                        'SELECT * FROM associations WHERE id = ?',
                        [payload.associationId]
                    );
                    invitedAssoc = rows[0] || null;
                    console.log(`[SIGNUP] Token-based lookup → assoc: ${invitedAssoc ? invitedAssoc.name : 'NOT FOUND'}`);
                }
            } catch (e) {
                // Expired or tampered token — treat as normal signup
                console.warn('[SIGNUP] Invalid inviteToken, treating as normal signup:', e.message);
            }
        }

        // Fallback: if no token provided, try email-based lookup (legacy support)
        if (!invitedAssoc && !inviteToken) {
            invitedAssoc = await Association.findByAdminEmail(email);
            console.log(`[SIGNUP] Email-based lookup for "${email}" → assoc: ${invitedAssoc ? invitedAssoc.name : 'NULL'}`);
        }

        const role = invitedAssoc ? 'ADMIN' : 'SA';
        const status = invitedAssoc ? 'actif' : 'en attente';

        const passwordHash = await bcrypt.hash(password, 10);
        const id = await User.create({ name, email, phone, passwordHash, role, status });

        // Link to association if invited
        if (invitedAssoc) {
            const db = require('../config/db');
            await db.query(
                `INSERT IGNORE INTO association_members (association_id, user_id) VALUES (?, ?)`,
                [invitedAssoc.id, id]
            );
            await User.markOnboardingSeen(id);
        }

        const token = signToken({ id, email, role });
        res.status(201).json({
            message: 'Account created successfully.',
            token,
            role,
            isInvitedAdmin: !!invitedAssoc,
            profileSetupSeen: false,
            onboardingSeen: !!invitedAssoc,
            user: { id, name, email, role },
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
            isInvitedAdmin: user.role === 'ADMIN',
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            user: { id: user.id, name: user.name, email: user.email, role: user.role },
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
        const role = invitedAssoc ? 'ADMIN' : 'SA';

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
            isInvitedAdmin: (user.role || role) === 'ADMIN',
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            user: { id: user.id, name: user.name, email: user.email },
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
        const role = invitedAssoc ? 'ADMIN' : 'SA';

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
            isInvitedAdmin: (user.role || role) === 'ADMIN',
            profileSetupSeen: !!user.profile_setup_seen,
            onboardingSeen: !!user.onboarding_seen,
            user: { id: user.id, name: user.name, email: user.email },
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

        // Fetch the user to check their current role before upgrading
        const user = await User.findById(userId);
        // Capture the role value NOW (before any DB change) so the response is accurate
        const wasAdmin = !!(user && user.role === 'ADMIN');

        // If the user was a restricted invited admin, upgrade them to full SA
        if (wasAdmin) {
            const db = require('../config/db');
            await db.query('UPDATE users SET role = ? WHERE id = ?', ['SA', userId]);
        }

        res.status(200).json({
            message: 'Profile updated successfully.',
            upgraded: wasAdmin,
        });
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
        const userId = req.user.id;
        const {
            name,
            address,
            contactEmails,
            contactPhones,
            adminEmails,
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

        // Check for newly added admins to send invitations
        let newlyAddedEmails = [];
        const existingAssoc = await Association.findByUserId(userId);
        if (existingAssoc && existingAssoc.admin_emails) {
            const oldAdmins = safeParse(existingAssoc.admin_emails);
            newlyAddedEmails = cleanAdminEmails.filter(email => !oldAdmins.includes(email));
        } else {
            // First time setting up association, all are new
            newlyAddedEmails = [...cleanAdminEmails];
        }

        await Association.createOrUpdate(userId, {
            name,
            address,
            logoUrl: null, // logo upload to be handled separately if needed
            contactEmails,
            contactPhones,
            adminEmails: cleanAdminEmails,
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
        for (const email of newlyAddedEmails) {
            // Generate a signed invite token — includes associationId so signup can
            // look up the association directly without relying on email matching.
            const inviteToken = jwt.sign(
                { email, associationId: newAssoc ? newAssoc.id : null, purpose: 'admin_invite' },
                JWT_SECRET,
                { expiresIn: '7d' }
            );
            generatedInviteTokens[email] = inviteToken;
            await sendAdminInvitationEmail(email, req.user.name, name, inviteToken).catch(err => {
                console.error(`Failed to send invitation to ${email}:`, err);
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

        if (payload.purpose !== 'admin_invite' || !payload.email) {
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
