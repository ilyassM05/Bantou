const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const authMiddleware = require('../middleware/authMiddleware');
const multer = require('multer');

// Configure multer
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const upload = multer({ storage: storage });

// All routes require auth
router.use(authMiddleware);

router.get('/', postController.getPosts);
router.post('/', upload.single('image'), postController.createPost);
router.delete('/:id', postController.deletePost);
router.get('/user/:userId/profile', postController.getUserProfile);
router.post('/:id/like', postController.toggleLike);

module.exports = router;
