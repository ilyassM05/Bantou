const Post = require('../models/Post');
const Association = require('../models/Association');
const User = require('../models/User');
const db = require('../config/db');

exports.createPost = async (req, res) => {
    try {
        const userId = req.user.id;
        const { content } = req.body;
        const imageUrl = req.file ? '/uploads/' + req.file.filename : null;

        if (!content && !imageUrl) {
            return res.status(400).json({ error: 'Content or image is required.' });
        }

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(403).json({ error: 'You do not belong to an association.' });
        }

        const postId = await Post.create(userId, association.id, content, imageUrl);
        res.status(201).json({ message: 'Post created successfully', postId });
    } catch (error) {
        console.error('Create post error:', error);
        res.status(500).json({ error: 'Failed to create post' });
    }
};

exports.getPosts = async (req, res) => {
    try {
        const userId = req.user.id;

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(200).json({ posts: [] });
        }

        const posts = await Post.findByAssociationId(association.id, userId);

        res.status(200).json({ posts });
    } catch (error) {
        console.error('Get posts error:', error);
        res.status(500).json({ error: 'Failed to fetch posts' });
    }
};

exports.deletePost = async (req, res) => {
    try {
        const userId = req.user.id;
        const userRole = req.user.role;   // 'SA' | 'admin' | 'member'
        const postId = req.params.id;

        const post = await Post.findById(postId);
        if (!post) {
            return res.status(404).json({ error: 'Post not found.' });
        }

        const isOwnPost = post.user_id === userId;
        const authorRole = post.author_role; // 'SA' | 'admin' | 'member'

        // ── Role-based access control ─────────────────────────────────────────
        // SA: can delete any post
        // Admin: can delete their own posts OR posts created by members,
        //        but NOT posts created by SA or other admins
        // Member: can only delete their own posts
        let canDelete = false;

        if (userRole === 'SA') {
            canDelete = true;
        } else if (userRole === 'admin') {
            // Admin can delete member posts or their own posts
            canDelete = isOwnPost || authorRole === 'member';
        } else {
            // member
            canDelete = isOwnPost;
        }

        if (!canDelete) {
            if (userRole === 'admin' && (authorRole === 'SA' || authorRole === 'admin')) {
                return res.status(403).json({
                    error: 'Admins cannot delete posts created by Super Admins or other Admins.',
                });
            }
            return res.status(403).json({ error: 'You are not authorized to delete this post.' });
        }

        await Post.delete(postId);
        res.status(200).json({ message: 'Post deleted successfully.' });
    } catch (error) {
        console.error('Delete post error:', error);
        res.status(500).json({ error: 'An unexpected error occurred while deleting the post.' });
    }
};


exports.toggleLike = async (req, res) => {
    try {
        const userId = req.user.id;
        const postId = parseInt(req.params.id);

        const post = await Post.findById(postId);
        if (!post) {
            return res.status(404).json({ error: 'Post not found' });
        }

        const result = await Post.toggleLike(postId, userId);
        const newCount = await Post.getLikesCount(postId);

        res.status(200).json({
            liked: result.liked,
            likesCount: newCount,
        });
    } catch (error) {
        console.error('Toggle like error:', error);
        res.status(500).json({ error: 'Failed to toggle like' });
    }
};

exports.getUserProfile = async (req, res) => {
    try {
        const targetUserId = parseInt(req.params.userId);

        const user = await User.findById(targetUserId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.status(200).json({
            id: user.id,
            name: user.name,
            role: user.role,
            avatarIndex: user.avatar_index ?? 0,
            profilePicture: user.profile_picture || null,
            company: user.company,
            jobTitle: user.job_title,
            communityRole: user.community_role,
            city: user.city,
            bio: user.bio,
            website: user.website,
            email: user.email,
            phone: user.phone,
        });
    } catch (error) {
        console.error('Get user profile error:', error);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
};

// ── Comments ──────────────────────────────────────────────────────────────────

exports.getComments = async (req, res) => {
    try {
        const postId = parseInt(req.params.id);

        const post = await Post.findById(postId);
        if (!post) {
            return res.status(404).json({ error: 'Post not found' });
        }

        // Access check: requester must belong to the same association as the post
        const association = await Association.findByUserId(req.user.id);
        if (!association || association.id !== post.association_id) {
            return res.status(403).json({ error: 'Access denied.' });
        }

        const comments = await Post.getComments(postId);
        res.status(200).json({ comments });
    } catch (error) {
        console.error('Get comments error:', error);
        res.status(500).json({ error: 'Failed to fetch comments' });
    }
};

exports.addComment = async (req, res) => {
    try {
        const userId = req.user.id;
        const postId = parseInt(req.params.id);
        const { content } = req.body;

        if (!content || !content.trim()) {
            return res.status(400).json({ error: 'Comment content cannot be empty.' });
        }

        const post = await Post.findById(postId);
        if (!post) {
            return res.status(404).json({ error: 'Post not found' });
        }

        const comment = await Post.addComment(postId, userId, content.trim());
        res.status(201).json({ comment });
    } catch (error) {
        console.error('Add comment error:', error);
        res.status(500).json({ error: 'Failed to add comment' });
    }
};

// ── Sharing ───────────────────────────────────────────────────────────────────

/**
 * POST /:id/share
 * Body: { recipientIds: [int, int, ...] }   — any number of association members
 */
exports.sharePost = async (req, res) => {
    try {
        const userId = req.user.id;
        const postId = parseInt(req.params.id);
        const { recipientIds } = req.body;

        if (!Array.isArray(recipientIds) || recipientIds.length === 0) {
            return res.status(400).json({ error: 'Please select at least one recipient.' });
        }

        const post = await Post.findById(postId);
        if (!post) {
            return res.status(404).json({ error: 'Post not found' });
        }

        const association = await Association.findByUserId(userId);
        if (!association || association.id !== post.association_id) {
            return res.status(403).json({ error: 'Access denied.' });
        }

        // Filter out self-shares silently
        const filteredIds = recipientIds.filter(id => id !== userId);
        if (filteredIds.length === 0) {
            return res.status(400).json({ error: 'You cannot share a post only with yourself.' });
        }

        await Post.sharePost(postId, userId, filteredIds, association.id);
        res.status(200).json({ message: 'Post shared successfully.' });
    } catch (error) {
        console.error('Share post error:', error);
        res.status(500).json({ error: error.message || 'Failed to share post' });
    }
};

/**
 * GET /members
 * Returns all members of the current user's association (excluding self).
 */
exports.getAssociationMembers = async (req, res) => {
    try {
        const userId = req.user.id;

        const association = await Association.findByUserId(userId);
        if (!association) {
            return res.status(200).json({ members: [] });
        }

        // Members = the association creator + everyone in association_members
        // (users table has no direct association_id column)
        const [rows] = await db.execute(`
            SELECT DISTINCT u.id, u.name, u.avatar_index
            FROM users u
            WHERE u.id != ?
              AND (
                u.id = (SELECT creator_id FROM associations WHERE id = ?)
                OR u.id IN (SELECT user_id FROM association_members WHERE association_id = ?)
              )
            ORDER BY u.name ASC
        `, [userId, association.id, association.id]);

        res.status(200).json({ members: rows });
    } catch (error) {
        console.error('Get association members error:', error);
        res.status(500).json({ error: 'Failed to fetch members' });
    }
};
