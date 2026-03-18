const express = require('express');
const router = express.Router();
const circleController = require('../controllers/circleController');
const protect = require('../middleware/authMiddleware');

router.post('/', protect, circleController.createCircle);
router.get('/', protect, circleController.getCircles);
router.put('/:id', protect, circleController.updateCircle);

module.exports = router;
