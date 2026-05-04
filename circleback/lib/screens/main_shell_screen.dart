import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'circles/circle_dashboard_screen.dart';
import 'posts/posts_screen.dart';
import 'messaging/messages_screen.dart';
import '../services/messaging_service.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  static const routeName = '/main-shell';

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  int _unreadMessages = 0;
  StreamSubscription? _notifSub;

  final List<Widget> _screens = const [
    CircleDashboardScreen(),
    PostsScreen(),
    MessagesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MessagingService.instance.connect();
    _notifSub = MessagingService.instance.onNotification.listen((_) {
      _refreshUnread();
    });
    _refreshUnread();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final convs = await MessagingService.instance.getConversations();
      final total = convs.fold<int>(0, (s, c) => s + c.unreadCount);
      if (mounted) setState(() => _unreadMessages = total);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildCustomTabBar(),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 8
            : 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(0, Icons.dashboard_rounded, 'Dashboard'),
          const SizedBox(width: 8),
          _buildTabItem(1, Icons.dynamic_feed_rounded, 'Posts'),
          const SizedBox(width: 8),
          _buildTabItem(2, Icons.chat_bubble_rounded, 'Messages',
              badge: _unreadMessages),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label, {int badge = 0}) {
    final isSelected = _currentIndex == index;
    final color =
        isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
