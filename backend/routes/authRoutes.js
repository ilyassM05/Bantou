const { Router } = require('express');
const auth = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ── Multer for profile pictures ───────────────────────────────────────────────
const profileUploadDir = path.join(__dirname, '../uploads/profiles');
if (!fs.existsSync(profileUploadDir)) {
    fs.mkdirSync(profileUploadDir, { recursive: true });
}
const profileStorage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, profileUploadDir),
    filename: (_req, file, cb) => {
        const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, 'profile-' + unique + path.extname(file.originalname));
    },
});
const profileUpload = multer({
    storage: profileStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (_req, file, cb) => {
        if (file.mimetype.startsWith('image/')) cb(null, true);
        else cb(new Error('Only image files are allowed'));
    },
});

// ── Multer for association logos ──────────────────────────────────────────────
const logoUploadDir = path.join(__dirname, '../uploads/logos');
if (!fs.existsSync(logoUploadDir)) {
    fs.mkdirSync(logoUploadDir, { recursive: true });
}
const logoStorage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, logoUploadDir),
    filename: (_req, file, cb) => {
        const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, 'logo-' + unique + path.extname(file.originalname));
    },
});
const logoUpload = multer({
    storage: logoStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (_req, file, cb) => {
        if (file.mimetype.startsWith('image/')) cb(null, true);
        else cb(new Error('Only image files are allowed'));
    },
});

const router = Router();


// Email / password
router.post('/signup', auth.signup);
router.post('/login', auth.login);
router.post('/forgot-password', auth.forgotPassword);
router.post('/verify-otp', auth.verifyOtp);
router.post('/reset-password', auth.resetPassword);

// Google OAuth
router.post('/google', auth.googleSignIn);

// Facebook OAuth
router.post('/facebook', auth.facebookSignIn);

// Profile
router.get('/profile', authMiddleware, auth.getProfile);
router.post('/update-profile', authMiddleware, auth.updateProfile);
router.post('/change-password', authMiddleware, auth.changePassword);
router.post('/mark-setup-seen', authMiddleware, auth.markSetupSeen);

// Profile picture
router.post('/upload-profile-picture', authMiddleware, profileUpload.single('profilePicture'), auth.uploadProfilePicture);
router.delete('/profile-picture', authMiddleware, auth.deleteProfilePicture);


// Association (onboarding)
router.post('/association', authMiddleware, auth.createAssociation);
router.get('/association/members', authMiddleware, auth.getAssociationMembers);
router.get('/association', authMiddleware, auth.getAssociation);

// Association logo (dedicated file upload — separate from the JSON save)
router.post('/association/logo', authMiddleware, logoUpload.single('logo'), auth.uploadAssociationLogo);
router.delete('/association/logo', authMiddleware, auth.deleteAssociationLogo);


// Invite link validation (no auth needed — called before signup)
router.get('/invite/:token', auth.validateInviteToken);

// Invite redirect page — served to email clients, redirects to bantou:// deep link
router.get('/invite-redirect/:token', auth.inviteRedirect);

// Member invitation (SA sends immediately; member/admin creates pending request)
router.post('/invite-member', authMiddleware, auth.inviteMember);

// SA Dashboard
router.get('/sa-dashboard', authMiddleware, auth.getSADashboard);

// Pending member invitations (submitted by non-SA members, need SA approval)
router.get('/member-invitations/pending', authMiddleware, auth.getPendingMemberInvitations);
router.put('/member-invitations/:id/respond', authMiddleware, auth.respondToMemberInvitation);

module.exports = router;
