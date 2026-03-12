const { Router } = require('express');
const auth = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

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
router.post('/mark-setup-seen', authMiddleware, auth.markSetupSeen);

// Association (onboarding)
router.post('/association', authMiddleware, auth.createAssociation);
router.get('/association', authMiddleware, auth.getAssociation);

// Invite link validation (no auth needed — called before signup)
router.get('/invite/:token', auth.validateInviteToken);

// Invite redirect page — served to email clients, redirects to bantou:// deep link
router.get('/invite-redirect/:token', auth.inviteRedirect);

module.exports = router;
