const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const mc = require('../controllers/messageController');

// ── Invitations ───────────────────────────────────────────────────────────────
router.post('/invitations', auth, mc.sendInvitation);
router.get('/invitations', auth, mc.getInvitations);
router.patch('/invitations/:id', auth, mc.respondToInvitation);

// ── Conversations ─────────────────────────────────────────────────────────────
router.get('/conversations', auth, mc.getConversations);
router.post('/conversations', auth, mc.createGroupConversation);
router.post('/conversations/direct', auth, mc.getOrCreateDirectConversation);

// ── Messages ──────────────────────────────────────────────────────────────────
router.get('/conversations/:id/messages', auth, mc.getMessages);
router.post('/conversations/:id/messages', auth, mc.sendMessage);
router.post('/conversations/:id/seen', auth, mc.markSeen);

// ── Group Members ─────────────────────────────────────────────────────────────
router.post('/conversations/:id/members', auth, mc.addMember);
router.delete('/conversations/:id/members/:uid', auth, mc.removeMember);

// ── User Search ───────────────────────────────────────────────────────────────
router.get('/users/search', auth, mc.searchUsers);

// ── Block ─────────────────────────────────────────────────────────────────────
router.post('/block/:uid', auth, mc.blockUser);
router.delete('/block/:uid', auth, mc.unblockUser);

module.exports = router;
