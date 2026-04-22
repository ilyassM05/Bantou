import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/post.dart';
import '../../models/post_comment.dart';
import '../../services/post_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/app_localizations.dart';
import 'user_profile_screen.dart';

/// Temporary "Shared with me" inbox screen.
/// Shows only posts that were shared to the current user,
/// with the same inline-comment capability as the main feed.
/// Replace this with a full messaging screen once that is built.
class SharedPostsScreen extends StatefulWidget {
  const SharedPostsScreen({super.key});

  @override
  State<SharedPostsScreen> createState() => _SharedPostsScreenState();
}

class _SharedPostsScreenState extends State<SharedPostsScreen> {
  final PostService _postService = PostService();

  List<Post> _sharedPosts = [];
  bool _isLoading = true;
  String? _error;

  final Set<int> _pendingLikes = {};
  final Map<int, List<PostComment>?> _commentsMap = {};
  final Set<int> _expandedComments = {};
  final Map<int, TextEditingController> _commentControllers = {};
  final Set<int> _submittingComment = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    for (final ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchSharedPosts();
  }

  Future<void> _fetchSharedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final allPosts = await _postService.getPosts();
      if (mounted) {
        setState(() {
          // Keep only posts shared to the current user
          _sharedPosts = allPosts
              .where((p) => p.sharedByName != null)
              .toList();
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

  Future<void> _toggleLike(int postIndex) async {
    final post = _sharedPosts[postIndex];
    if (_pendingLikes.contains(post.id)) return;
    _pendingLikes.add(post.id);
    final wasLiked = post.isLikedByUser;
    setState(() {
      _sharedPosts[postIndex] = post.copyWith(
        isLikedByUser: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });
    try {
      final result = await _postService.toggleLike(post.id);
      if (mounted) {
        setState(() {
          _sharedPosts[postIndex] = _sharedPosts[postIndex].copyWith(
            isLikedByUser: result['liked'] as bool,
            likesCount: result['likesCount'] as int,
          );
        });
      }
    } catch (_) {
      if (mounted) setState(() => _sharedPosts[postIndex] = post);
    } finally {
      _pendingLikes.remove(post.id);
    }
  }

  Future<void> _toggleComments(int postId) async {
    if (_expandedComments.contains(postId)) {
      setState(() => _expandedComments.remove(postId));
      return;
    }
    setState(() => _expandedComments.add(postId));
    if (!_commentsMap.containsKey(postId)) {
      try {
        final comments = await _postService.getComments(postId);
        if (mounted) setState(() => _commentsMap[postId] = comments);
      } catch (_) {
        if (mounted) setState(() => _commentsMap[postId] = []);
      }
    }
  }

  Future<void> _submitComment(int postIndex) async {
    final post = _sharedPosts[postIndex];
    final ctrl = _commentControllers[post.id];
    if (ctrl == null || ctrl.text.trim().isEmpty) return;
    if (_submittingComment.contains(post.id)) return;
    final text = ctrl.text.trim();
    setState(() => _submittingComment.add(post.id));
    try {
      final comment = await _postService.addComment(post.id, text);
      if (mounted) {
        ctrl.clear();
        setState(() {
          _commentsMap[post.id] = [...?_commentsMap[post.id], comment];
          _sharedPosts[postIndex] =
              post.copyWith(commentsCount: post.commentsCount + 1);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment.remove(post.id));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.move_to_inbox_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Shared with me',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSharedPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                    ),
                  )
                : _sharedPosts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sharedPosts.length,
                        itemBuilder: (_, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPostCard(index, l10n),
                        ),
                      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.move_to_inbox_outlined,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No shared posts yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone shares a post with you\nit will appear here.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(int index, AppLocalizations l10n) {
    final post = _sharedPosts[index];
    final bool commentsOpen = _expandedComments.contains(post.id);
    final List<PostComment>? comments = _commentsMap[post.id];
    _commentControllers.putIfAbsent(post.id, () => TextEditingController());
    final ctrl = _commentControllers[post.id]!;

    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Shared-by banner ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.reply_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.sharedBy} ${post.sharedByName}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Post author ───────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _navigateToUserProfile(post.userId, post.userName),
                      child: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          post.userName.isNotEmpty
                              ? post.userName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToUserProfile(
                                post.userId, post.userName),
                            child: Text(
                              post.userName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
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
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.circle,
                                  size: 4, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _getTimeAgo(post.createdAt),
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Content ───────────────────────────────────────────────
                if (post.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: GoogleFonts.inter(
                        height: 1.5,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                ],

                // ── Image ─────────────────────────────────────────────────
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'http://10.0.2.2:3000${post.imageUrl}',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ],

                // ── Interaction row ───────────────────────────────────────
                const SizedBox(height: 16),
                Divider(color: AppColors.borderSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLikeButton(index, post, l10n),
                      _buildCommentButton(post, commentsOpen, l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Inline comments ───────────────────────────────────────────
          if (commentsOpen) ...[
            Divider(height: 1, color: AppColors.borderSoft),
            _buildCommentsSection(post, comments, ctrl, l10n, index),
          ],
        ],
      ),
    );
  }

  Widget _buildLikeButton(int index, Post post, AppLocalizations l10n) {
    return InkWell(
      onTap: () => _toggleLike(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                post.isLikedByUser
                    ? Icons.thumb_up_alt
                    : Icons.thumb_up_alt_outlined,
                key: ValueKey(post.isLikedByUser),
                color: post.isLikedByUser
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                color: post.isLikedByUser
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: post.isLikedByUser
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 13,
              ),
              child: Text(
                post.likesCount > 0
                    ? '${l10n.like} (${post.likesCount})'
                    : l10n.like,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(Post post, bool isOpen, AppLocalizations l10n) {
    final color = isOpen ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: () => _toggleComments(post.id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOpen ? Icons.mode_comment : Icons.mode_comment_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              post.commentsCount > 0
                  ? '${l10n.comment} (${post.commentsCount})'
                  : l10n.comment,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: isOpen ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(
    Post post,
    List<PostComment>? comments,
    TextEditingController ctrl,
    AppLocalizations l10n,
    int postIndex,
  ) {
    return Container(
      color: AppColors.inputFill.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comments == null)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ))
          else if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.noComments,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...comments.map((c) => _buildCommentTile(c)),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.addComment,
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: AppColors.primary),
                    ),
                    suffixIcon: _submittingComment.contains(post.id)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: AppColors.primary, size: 20),
                            onPressed: () => _submitComment(postIndex),
                          ),
                  ),
                  onSubmitted: (_) => _submitComment(postIndex),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(PostComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTimeAgo(comment.createdAt),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment.content,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
