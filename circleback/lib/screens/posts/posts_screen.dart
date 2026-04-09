import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/app_localizations.dart';
import 'create_post_screen.dart';
import 'user_profile_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService _postService = PostService();

  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  int? _currentUserId;
  String? _currentUserRole;

  // Track in-flight like requests to prevent double-taps
  final Set<int> _pendingLikes = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserInfo();
    await _fetchPosts();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await BiometricService.getToken();
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final String normalized = base64Url.normalize(parts[1]);
          final String payloadStr = utf8.decode(base64Url.decode(normalized));
          final payload = jsonDecode(payloadStr);
          if (mounted) {
            setState(() {
              _currentUserId = payload['id'];
              _currentUserRole = payload['role'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error decoding token: $e');
    }
  }

  Future<void> _fetchPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final posts = await _postService.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 1) return '${diff.inDays}d';
    if (diff.inDays == 1) return '1d';
    if (diff.inHours > 1) return '${diff.inHours}h';
    if (diff.inHours == 1) return '1h';
    if (diff.inMinutes > 1) return '${diff.inMinutes}m';
    return 'Just now';
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
    if (result == true) _fetchPosts();
  }

  void _navigateToUserProfile(int userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  /// Optimistic like toggle: update UI immediately, revert if server fails.
  Future<void> _toggleLike(int postIndex) async {
    final post = _posts[postIndex];
    if (_pendingLikes.contains(post.id)) return; // debounce

    _pendingLikes.add(post.id);

    // Optimistic update
    final wasLiked = post.isLikedByUser;
    setState(() {
      _posts[postIndex] = post.copyWith(
        isLikedByUser: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    try {
      final result = await _postService.toggleLike(post.id);
      // Sync with server truth
      if (mounted) {
        setState(() {
          _posts[postIndex] = _posts[postIndex].copyWith(
            isLikedByUser: result['liked'] as bool,
            likesCount: result['likesCount'] as int,
          );
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _posts[postIndex] = post;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like. Please try again.')),
        );
      }
    } finally {
      _pendingLikes.remove(post.id);
    }
  }

  Future<void> _deletePost(int postId) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePost),
        content: Text(l10n.deletePostConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deletePost, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _postService.deletePost(postId);
        _fetchPosts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        title: Text(
          l10n.postsFeed,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCreatePostHeader(l10n),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No posts yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...List.generate(_posts.length, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPostCard(index, l10n),
              )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _navigateToCreatePost,
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Text(
                      l10n.shareAnUpdate,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPostAction(Icons.image_outlined, l10n.photo, const Color(0xFF4285F4), _navigateToCreatePost),
              _buildPostAction(Icons.videocam_outlined, 'Video', const Color(0xFF34A853), _navigateToCreatePost),
              _buildPostAction(Icons.event_outlined, 'Event', const Color(0xFFEA4335), _navigateToCreatePost),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(int index, AppLocalizations l10n) {
    final post = _posts[index];
    final bool canDelete = post.userId == _currentUserId || _currentUserRole == 'SA';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post header (avatar + name, tappable) ─────────────────────
          Row(
            children: [
              // Tappable avatar
              GestureDetector(
                onTap: () => _navigateToUserProfile(post.userId, post.userName),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tappable name
                    GestureDetector(
                      onTap: () => _navigateToUserProfile(post.userId, post.userName),
                      child: Text(
                        post.userName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.userRole,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.circle, size: 4, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _getTimeAgo(post.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canDelete)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'delete') _deletePost(post.id);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.deletePost,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),

          // ── Content ───────────────────────────────────────────────────
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              post.content,
              style: GoogleFonts.inter(
                height: 1.5,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],

          // ── Image ─────────────────────────────────────────────────────
          if (post.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'http://10.0.2.2:3000${post.imageUrl}',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
          ],

          // ── Interaction row ───────────────────────────────────────────
          const SizedBox(height: 16),
          Divider(color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Animated Like button
                _buildLikeButton(index, post, l10n),
                _buildInteractionButton(
                  Icons.mode_comment_outlined,
                  l10n.comment,
                  post.commentsCount,
                  null,
                ),
                _buildInteractionButton(
                  Icons.share_outlined,
                  l10n.share,
                  0,
                  null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(int index, Post post, AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: post.isLikedByUser ? 1.0 : 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: InkWell(
        onTap: () => _toggleLike(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  post.isLikedByUser
                      ? Icons.thumb_up_alt
                      : Icons.thumb_up_alt_outlined,
                  key: ValueKey(post.isLikedByUser),
                  color: post.isLikedByUser ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  color: post.isLikedByUser ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: post.isLikedByUser ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                child: Text(
                  post.likesCount > 0 ? '${l10n.like} (${post.likesCount})' : l10n.like,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton(
    IconData icon,
    String label,
    int count,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 6),
            Text(
              count > 0 ? '$label ($count)' : label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
