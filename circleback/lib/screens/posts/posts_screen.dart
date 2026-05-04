import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/post.dart';
import '../../models/post_comment.dart';
import '../../models/association_member.dart';
import '../../services/post_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/app_localizations.dart';
import 'create_post_screen.dart';
import 'user_profile_screen.dart';
import 'shared_posts_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService _postService = PostService();

  List<Post> _posts = [];
  int _sharedPostsInboxCount = 0;
  bool _isLoading = true;
  String? _error;

  int? _currentUserId;
  String? _currentUserRole;

  // Track in-flight like requests to prevent double-taps
  final Set<int> _pendingLikes = {};

  // Inline comments: postId → list of comments (null = not loaded yet)
  final Map<int, List<PostComment>?> _commentsMap = {};
  // Which posts have their comment section expanded
  final Set<int> _expandedComments = {};
  // Comment text controllers — one per post
  final Map<int, TextEditingController> _commentControllers = {};
  // Track in-flight comment submissions
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
          _sharedPostsInboxCount = posts.where((p) => p.sharedByName != null).length;
          _posts = posts.where((p) => p.sharedByName == null).toList();
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

  /// Optimistic like toggle.
  Future<void> _toggleLike(int postIndex) async {
    final post = _posts[postIndex];
    if (_pendingLikes.contains(post.id)) return;

    _pendingLikes.add(post.id);

    final wasLiked = post.isLikedByUser;
    setState(() {
      _posts[postIndex] = post.copyWith(
        isLikedByUser: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    try {
      final result = await _postService.toggleLike(post.id);
      if (mounted) {
        setState(() {
          _posts[postIndex] = _posts[postIndex].copyWith(
            isLikedByUser: result['liked'] as bool,
            likesCount: result['likesCount'] as int,
          );
        });
      }
    } catch (e) {
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

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<void> _toggleComments(int postId) async {
    if (_expandedComments.contains(postId)) {
      setState(() => _expandedComments.remove(postId));
      return;
    }

    setState(() => _expandedComments.add(postId));

    // Lazy-load if not yet fetched
    if (!_commentsMap.containsKey(postId)) {
      try {
        final comments = await _postService.getComments(postId);
        if (mounted) {
          setState(() => _commentsMap[postId] = comments);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _commentsMap[postId] = []);
        }
      }
    }
  }

  Future<void> _submitComment(int postIndex) async {
    final post = _posts[postIndex];
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
          _posts[postIndex] = post.copyWith(commentsCount: post.commentsCount + 1);
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

  // ── Share bottom sheet ────────────────────────────────────────────────────

  Future<void> _openShareSheet(int postIndex) async {
    final l10n = AppLocalizations.of(context);
    final post = _posts[postIndex];

    // Load members (once per sheet open)
    List<AssociationMember> members = [];
    bool loadError = false;
    try {
      members = await _postService.getAssociationMembers();
    } catch (_) {
      loadError = true;
    }

    if (!mounted) return;

    // State local to the bottom sheet
    final Set<int> selected = {};
    final TextEditingController searchCtrl = TextEditingController();
    List<AssociationMember> filtered = List.from(members);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void applySearch(String q) {
              setSheetState(() {
                filtered = members
                    .where((m) => m.name.toLowerCase().contains(q.toLowerCase()))
                    .toList();
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Handle ─────────────────────────────────────────────
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Header ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          l10n.selectRecipients,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Search ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: applySearch,
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.searchMembers,
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderSoft),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderSoft),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Member list ────────────────────────────────────────
                  Expanded(
                    child: loadError
                        ? Center(
                            child: Text(
                              'Failed to load members.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.cdNoMembersFound,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final member = filtered[i];
                                  final isSelected = selected.contains(member.id);
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                      child: Text(
                                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      member.name,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.borderSoft,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    onTap: () {
                                      setSheetState(() {
                                        if (isSelected) {
                                          selected.remove(member.id);
                                        } else {
                                          selected.add(member.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                  ),

                  // ── Share button ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        16, 8, 16, MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: Text(
                          selected.isEmpty
                              ? l10n.share
                              : '${l10n.share} (${selected.length})',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(sheetCtx);
                                try {
                                  await _postService.sharePost(
                                      post.id, selected.toList());
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.shareSuccess),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Share failed: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    searchCtrl.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Returns how many posts in the current feed were shared to the user.
  int get _sharedCount => _sharedPostsInboxCount;

  Widget _buildInboxButton() {
    final count = _sharedCount;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SharedPostsScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.move_to_inbox_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardSurface, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
        actions: [
          _buildInboxButton(),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'posts_fab',
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
    final bool commentsOpen = _expandedComments.contains(post.id);
    final List<PostComment>? comments = _commentsMap[post.id];

    // Ensure controller exists
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
                // ── Shared-by banner ─────────────────────────────────────
                if (post.sharedByName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply, size: 14, color: AppColors.primary),
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
                ],

                // ── Post header ──────────────────────────────────────────
                Row(
                  children: [
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

                // ── Content ──────────────────────────────────────────────
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

                // ── Image ────────────────────────────────────────────────
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

                // ── Interaction row ──────────────────────────────────────
                const SizedBox(height: 16),
                Divider(color: AppColors.borderSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Like
                      _buildLikeButton(index, post, l10n),
                      // Comment
                      _buildInteractionButton(
                        icon: Icons.mode_comment_outlined,
                        activeIcon: Icons.mode_comment,
                        label: l10n.comment,
                        count: post.commentsCount,
                        isActive: commentsOpen,
                        onTap: () => _toggleComments(post.id),
                      ),
                      // Share
                      _buildInteractionButton(
                        icon: Icons.share_outlined,
                        activeIcon: Icons.share,
                        label: l10n.share,
                        count: 0,
                        isActive: false,
                        onTap: () => _openShareSheet(index),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Inline comment section ────────────────────────────────────
          if (commentsOpen) ...[
            Divider(height: 1, color: AppColors.borderSoft),
            _buildCommentsSection(post, comments, ctrl, l10n, index),
          ],
        ],
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
          // ── Comment list ──────────────────────────────────────────────
          if (comments == null)
            const Center(child: Padding(
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

          // ── Compose row ───────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.addComment,
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      borderSide: BorderSide(color: AppColors.primary),
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
                            icon: Icon(Icons.send_rounded,
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
              comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment.content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
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
        return Transform.scale(scale: scale, child: child);
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
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  post.isLikedByUser ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
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

  Widget _buildInteractionButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              count > 0 ? '$label ($count)' : label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
