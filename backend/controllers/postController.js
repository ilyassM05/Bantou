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
        const postId = req.params.id;

        const post = await Post.findById(postId);
        if (!post) {
            return res.status(404).json({ error: 'Post not found' });
        }

        if (post.user_id !== userId && req.user.role !== 'SA') {
            return res.status(403).json({ error: 'Unauthorized to delete this post.' });
        }

        await Post.delete(postId);
        res.status(200).json({ message: 'Post deleted successfully' });
    } catch (error) {
        console.error('Delete post error:', error);
        res.status(500).json({ error: 'Failed to delete post' });
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

        // No privacy restrictions — return all information to any authenticated user
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

