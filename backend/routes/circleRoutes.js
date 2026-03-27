const express = require('express');
const router = express.Router();
const circleController = require('../controllers/circleController');
const protect = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

router.post('/', protect, circleController.createCircle);
router.get('/', protect, circleController.getCircles);
router.get('/association/members', protect, circleController.getAssociationMembers);
router.get('/requests/pending', protect, circleController.getPendingRequests);
router.put('/requests/:requestId/respond', protect, circleController.respondToRequest);
router.post('/:id/request-access', protect, circleController.requestAccess);
router.put('/:id', protect, circleController.updateCircle);
router.get('/:id/participants', protect, circleController.getCircleParticipants);

// Member circle actions
router.post('/:id/join', protect, circleController.joinCircle);
router.delete('/:id/join', protect, circleController.leaveCircle);
router.post('/:id/invite', protect, circleController.inviteToCircle);

// Photos
router.post('/:id/photos', protect, upload.single('photo'), circleController.uploadCirclePhoto);
router.get('/:id/photos', protect, circleController.getCirclePhotos);

module.exports = router;

