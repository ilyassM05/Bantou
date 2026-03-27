import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        title: Text(
          'Posts feed',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCreatePostMockup(context),
          const SizedBox(height: 24),
          _buildMockPost(
            userName: 'Sarah Jenkins',
            userRole: 'Admin • Design Circle',
            timeAgo: '2 hours ago',
            content: 'Just finished setting up our new community guidelines for the Q3 events. Let me know what you think!',
            imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&q=80&w=800',
            likesCount: 12,
            commentsCount: 4,
          ),
          const SizedBox(height: 16),
          _buildMockPost(
            userName: 'Michael Chen',
            userRole: 'Member • General Circle',
            timeAgo: '5 hours ago',
            content: 'Does anyone have the link to the recording from last week\'s all-hands meeting? Missed it due to a client call.',
            likesCount: 3,
            commentsCount: 1,
          ),
          const SizedBox(height: 16),
          _buildMockPost(
            userName: 'Alisha Singh',
            userRole: 'Super Admin • Leadership',
            timeAgo: '1 day ago',
            content: 'Welcome to all our new joiners this week! Make sure to update your profiles and introduce yourselves in the main circles.',
            imageUrl: 'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&q=80&w=800',
            likesCount: 34,
            commentsCount: 8,
          ),
          const SizedBox(height: 80), // Padding for tab bar scroll
        ],
      ),
    );
  }

  Widget _buildCreatePostMockup(BuildContext context) {
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
          Row(
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
                    'Share an update with your circle...',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPostAction(Icons.image_outlined, 'Photo', const Color(0xFF4285F4)),
              _buildPostAction(Icons.videocam_outlined, 'Video', const Color(0xFF34A853)),
              _buildPostAction(Icons.event_outlined, 'Event', const Color(0xFFEA4335)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, Color color) {
    return Row(
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
    );
  }

  Widget _buildMockPost({
    required String userName,
    required String userRole,
    required String timeAgo,
    required String content,
    String? imageUrl,
    required int likesCount,
    required int commentsCount,
  }) {
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  userName.substring(0, 1),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userRole,
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
                          timeAgo,
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
              IconButton(
                icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              height: 1.5,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
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
          const SizedBox(height: 16),
          Divider(color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInteractionButton(Icons.thumb_up_alt_outlined, 'Like', likesCount),
                _buildInteractionButton(Icons.mode_comment_outlined, 'Comment', commentsCount),
                _buildInteractionButton(Icons.share_outlined, 'Share', 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, int count) {
    return Row(
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
    );
  }
}
