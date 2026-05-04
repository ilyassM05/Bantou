const { Router } = require('express');
const authMiddleware = require('../middleware/authMiddleware');
const friend = require('../controllers/friendController');

const router = Router();

// All friend routes require authentication
router.use(authMiddleware);

// Get relationship status with a specific user
router.get('/status/:targetUserId', friend.getFriendStatus);

// Send a friend request
router.post('/request/:targetUserId', friend.sendFriendRequest);

// Respond to a pending request (accept / decline)
router.put('/respond/:requestId', friend.respondToFriendRequest);

// List accepted friends
router.get('/', friend.getFriends);

// List pending incoming requests
router.get('/requests/pending', friend.getPendingRequests);

// List pending outgoing requests
router.get('/requests/sent', friend.getSentRequests);

// Remove a friend (bidirectional)
router.delete('/:targetUserId', friend.removeFriend);

module.exports = router;
