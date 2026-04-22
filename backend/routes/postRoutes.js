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

// Existing routes
router.get('/',                        postController.getPosts);
router.post('/',   upload.single('image'), postController.createPost);
router.delete('/:id',                  postController.deletePost);
router.get('/user/:userId/profile',    postController.getUserProfile);
router.post('/:id/like',               postController.toggleLike);

// NEW — /members MUST come before /:id/* to avoid Express matching "members" as a post ID
router.get('/members',                 postController.getAssociationMembers);
router.get('/:id/comments',            postController.getComments);
router.post('/:id/comments',           postController.addComment);
router.post('/:id/share',              postController.sharePost);

module.exports = router;
