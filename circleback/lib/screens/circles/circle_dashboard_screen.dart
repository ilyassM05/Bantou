import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../services/circle_service.dart';
import '../../services/http_auth_service.dart';
import '../../widgets/user_avatar.dart';
import '../posts/user_profile_screen.dart';
import 'circle_details_screen.dart';
import 'create_circle_screen.dart';
import 'pending_requests_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/invite_member_sheet.dart';

/// The actual Circle Dashboard showing statistics and active circles.
class CircleDashboardScreen extends StatefulWidget {
  const CircleDashboardScreen({super.key});

  static const routeName = '/circle-dashboard';

  @override
  State<CircleDashboardScreen> createState() => _CircleDashboardScreenState();
}

class _CircleDashboardScreenState extends State<CircleDashboardScreen> {
  // Read user details similar to HomeScreen
  Map<String, String>? _user;

  // Dynamic backend data
  bool _isLoading = true;
  String? _associationName;
  int _activeMembersCount = 0;
  int _meetingsCount = 0;
  int _pendingRequestsCount = 0;
  List<dynamic> _circles = [];
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_user == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, String>) {
        _user = args;
      }
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final service = CircleService();
      final data = await service.getCircles();

      int pendingCount = 0;
      final bool canViewRequests = HttpAuthService.currentUserRole == 'SA' ||
          HttpAuthService.currentUserRole == 'admin' ||
          HttpAuthService.currentIsInvitedAdmin;

      if (canViewRequests) {
        try {
          final reqData = await service.getPendingRequests();
          pendingCount = (reqData['pendingRequests'] as List?)?.length ?? 0;
        } catch (_) {
          // ignore error to unblock main dashboard
        }
      }

      if (mounted) {
        setState(() {
          _associationName = data['associationName'];
          _activeMembersCount = data['activeMembersCount'] ?? 0;
          _meetingsCount = data['meetingsCount'] ?? 0;
          _circles = data['circles'] ?? [];
          _pendingRequestsCount = pendingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleJoin(Map<String, dynamic> circle) async {
    final id = circle['id'] as int;
    final joined = circle['joinStatus'] == 'Joined';
    try {
      if (joined) {
        await CircleService().leaveCircle(id);
      } else {
        await CircleService().joinCircle(id);
      }
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInviteToCircleDialog(Map<String, dynamic> circle) {
    final emailCtrl = TextEditingController();
    bool sending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text(AppLocalizations.of(context).cdInviteToCircle(circle['name'])),
          content: TextField(
            controller: emailCtrl,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).cdEmailAddress, prefixIcon: const Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cdCancel),
            ),
            ElevatedButton(
              onPressed: sending ? null : () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                setInnerState(() => sending = true);
                try {
                  final msg = await CircleService().inviteToCircle(circle['id'] as int, email);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF34D399)));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
                  }
                } finally {
                  if (ctx.mounted) setInnerState(() => sending = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(AppLocalizations.of(context).cdSend, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => InviteMemberSheet(
        onInvite: (email) async {
          await HttpAuthService().inviteMember(email);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'Bantou User';
    final firstName = name.split(' ').first;

    final filteredCircles = _searchQuery.isEmpty
        ? _circles
        : _circles.where((c) {
            final circleName = (c['name'] as String?)?.toLowerCase() ?? '';
            return circleName.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                : Column(
                    children: [
                      _buildHeader(context),
                      // No setup banner needed — admins stay as admin and don't need to upgrade.

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWelcomeSection(firstName),
                              const SizedBox(height: 24),
                              _buildStatsRow(),
                              const SizedBox(height: 32),
                              _buildCirclesHeader(),
                              const SizedBox(height: 16),
                              _buildSearchBar(),
                              const SizedBox(height: 24),
                              if (_circles.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text(
                                      AppLocalizations.of(context).cdNoCircles,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                              else if (filteredCircles.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text(
                                      AppLocalizations.of(context).cdNoSearchResults,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...filteredCircles.map((circle) {
                                  // Format date properly from ISO string
                                  String formattedDate = circle['createdAt'] ?? '';
                                  if (formattedDate.isNotEmpty) {
                                    try {
                                      final dt = DateTime.parse(formattedDate);
                                      formattedDate = DateFormat('MMM d, yyyy').format(dt);
                                    } catch (_) {}
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: _buildCircleCard(
                                      context: context,
                                      circle: circle,
                                      title: circle['name'] ?? 'Unknown',
                                      location: '${circle['city'] ?? ''}, ${circle['country'] ?? ''}'.trim(),
                                      responsibleName: circle['responsible'] ?? '',
                                      viceResponsibleName: circle['viceResponsible'] ?? '',
                                      meetingDate: formattedDate,
                                      meetingTime: circle['meetingPlanning'] ?? 'TBD',
                                      status: circle['status'] ?? AppLocalizations.of(context).cdActive,
                                      accessStatus: circle['accessStatus'] ?? 'Owner',
                                      visibilityType: circle['visibilityType'] ?? 'Public',
                                    ),
                                  );
                                }),
                              const SizedBox(height: 80), // padding for FAB
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      floatingActionButton: (HttpAuthService.currentUserRole == 'SA' ||
          HttpAuthService.currentUserRole == 'admin' ||
          HttpAuthService.currentIsInvitedAdmin)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, CreateCircleScreen.routeName);
                if (result == true) {
                  _fetchData(); // Refresh list if a circle was created
                }
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                AppLocalizations.of(context).cdNewCircle,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/bantou.png',
            height: 36,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.groups_rounded, color: AppColors.primary, size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   AppLocalizations.of(context).appName,
                   style: GoogleFonts.inter(
                     fontSize: 18,
                     fontWeight: FontWeight.w700,
                     color: AppColors.primaryDark,
                   ),
                 ),
                 Text(
                   AppLocalizations.of(context).appSubtitle,
                   style: GoogleFonts.inter(
                     fontSize: 11,
                     color: AppColors.textSecondary,
                   ),
                 ),
                 ],
               ),
          ),
          if (HttpAuthService.currentUserRole != null)
            IconButton(
              tooltip: 'Invite new Member',
              icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              onPressed: _showInviteMemberDialog,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () async {
              await HttpAuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/edit-profile').then((_) {
                if (mounted) setState(() {});
              });
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: UserAvatar(
                  profilePictureUrl: HttpAuthService.currentUserProfilePicture,
                  name: _user?['name'] ?? 'User',
                  size: 42,
                  animate: false, // Static in header — no logo switching
                  fallbackColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(String firstName) {
    final displayAssociationName = _associationName ?? AppLocalizations.of(context).cdNoAssoc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.apartment_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayAssociationName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${AppLocalizations.of(context).cdWelcome} $firstName',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).cdMeetingsThisWeek(_meetingsCount),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showAssociationMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AssociationMembersModal(),
    );
  }

  void _showTotalCirclesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
              child: Row(
                children: [
                   const Icon(Icons.group_work_outlined, color: AppColors.primary),
                   const SizedBox(width: 8),
                   Text(AppLocalizations.of(context).cdTotalCircles, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                   const Spacer(),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: _circles.isEmpty
                ? Center(child: Text(AppLocalizations.of(context).cdNoCircles, style: GoogleFonts.inter(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _circles.length,
                    itemBuilder: (context, index) {
                      final circle = _circles[index];
                      final name = circle['name'] ?? 'Unknown';
                      final statusLabel = AppLocalizations.of(context).translateStatus(circle['status'] ?? 'Active');
                      final visibilityLabel = AppLocalizations.of(context).translateStatus(circle['visibilityType'] ?? 'Public');
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha:0.1), child: const Icon(Icons.group_work, color: AppColors.primary, size: 20)),
                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        subtitle: Text('$statusLabel • $visibilityLabel', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        onTap: () {
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeetingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
              child: Row(
                children: [
                   const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                   const SizedBox(width: 8),
                   Text(AppLocalizations.of(context).cdMeetings, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                   const Spacer(),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: _circles.isEmpty
                ? Center(child: Text(AppLocalizations.of(context).cdNoCircles, style: GoogleFonts.inter(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _circles.length,
                    itemBuilder: (context, index) {
                      final circle = _circles[index];
                      final name = circle['name'] ?? 'Unknown';
                      
                      String formattedDate = circle['createdAt'] ?? '';
                      if (formattedDate.isNotEmpty) {
                        try {
                           final dt = DateTime.parse(formattedDate);
                           formattedDate = DateFormat('MMM d, yyyy').format(dt);
                        } catch (_) {}
                      }
                      final time = circle['meetingPlanning'] ?? 'TBD';
                      final responsible = circle['responsible'] ?? 'Unknown';
                      final viceResponsible = circle['viceResponsible'] ?? 'Unknown';

                      return ListTile(
                        isThreeLine: true,
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.event, color: AppColors.primary, size: 20),
                        ),
                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$formattedDate • $time', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('${AppLocalizations.of(context).cdResponsibleSmall}: $responsible', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                            Text('${AppLocalizations.of(context).cdViceResponsibleSmall}: $viceResponsible', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final canViewMembers = HttpAuthService.currentUserRole == 'SA' || HttpAuthService.currentUserRole == 'admin' || HttpAuthService.currentIsInvitedAdmin;
    return Row(
      children: [
        Expanded(child: _buildStatItem('${_circles.length}', AppLocalizations.of(context).cdTotalCircles, _showTotalCirclesBottomSheet)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('$_activeMembersCount', AppLocalizations.of(context).cdActiveMembers, canViewMembers ? _showAssociationMembersBottomSheet : null)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('$_meetingsCount', AppLocalizations.of(context).cdMeetings, _showMeetingsBottomSheet)),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCirclesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context).cdAssocCircles,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (HttpAuthService.currentUserRole == 'SA' ||
            HttpAuthService.currentUserRole == 'admin' ||
            HttpAuthService.currentIsInvitedAdmin)
          Badge(
            isLabelVisible: _pendingRequestsCount > 0,
            label: Text(_pendingRequestsCount > 9 ? '9+' : '$_pendingRequestsCount'),
            backgroundColor: Colors.red,
            offset: const Offset(-8, 4),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingRequestsScreen()),
                ).then((_) => _fetchData());
              },
              icon: const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
              label: Text(
                AppLocalizations.of(context).cdRequestsBtn,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
          label: Text(
            AppLocalizations.of(context).cdViewMap,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).cdSearch,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildCircleCard({
    required BuildContext context,
    required Map<String, dynamic> circle,
    required String title,
    required String location,
    required String responsibleName,
    required String viceResponsibleName,
    required String meetingDate,
    required String meetingTime,
    required String status,
    required String accessStatus,
    required String visibilityType,
  }) {
    final bool isActive = status.toLowerCase() == 'active';
    final bool isMember = HttpAuthService.currentUserRole == 'member' || HttpAuthService.currentIsMember;
    final bool canAccess = isMember 
        ? circle['joinStatus'] == 'Joined' 
        : (accessStatus == 'Owner' || accessStatus == 'Approved');

    return GestureDetector(
      onTap: () {
        if (canAccess) {
          Navigator.pushNamed(
            context,
            CircleDetailsScreen.routeName,
            arguments: circle,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMember ? 'You must participate to access this circle.' : 'You must request access to this circle.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: visibilityType == 'Private' ? Colors.deepPurple.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: visibilityType == 'Private' ? Colors.deepPurple.shade200 : Colors.blue.shade200),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translateStatus(visibilityType),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: visibilityType == 'Private' ? Colors.deepPurple : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isActive ? const Color(0xFFCEEAD6) : const Color(0xFFDADCE0)),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translateStatus(status),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF137333) : const Color(0xFF5F6368),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMemberInfo(
                  label: AppLocalizations.of(context).cdResponsibleSmall,
                  name: responsibleName,
                  color: const Color(0xFF4285F4),
                ),
              ),
              Expanded(
                child: _buildMemberInfo(
                  label: AppLocalizations.of(context).cdViceResponsibleSmall,
                  name: viceResponsibleName,
                  color: const Color(0xFFF9AB00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.event_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).cdMeetingLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        meetingDate.isNotEmpty ? meetingDate : AppLocalizations.of(context).cdNoDate,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (meetingTime.isNotEmpty && meetingTime != 'TBD')
                        Text(
                          meetingTime,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (HttpAuthService.currentUserRole == 'member' || HttpAuthService.currentIsMember) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showInviteToCircleDialog(circle),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                    label: Text(AppLocalizations.of(context).cdInviteBtn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleJoin(circle),
                    icon: Icon(circle['joinStatus'] == 'Joined' ? Icons.exit_to_app_rounded : Icons.login_rounded, size: 16),
                    label: Text(circle['joinStatus'] == 'Joined' ? AppLocalizations.of(context).cdLeaveBtn : AppLocalizations.of(context).cdParticipateBtn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: circle['joinStatus'] == 'Joined' ? Colors.red.shade400 : const Color(0xFF34D399),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (canAccess) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showInviteToCircleDialog(circle),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                label: Text(AppLocalizations.of(context).cdInviteToCircleBtn),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ] else if (!canAccess) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: accessStatus == 'None' ? () async {
                  try {
                    await CircleService().requestCircleAccess(circle['id']);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Access request sent successfully!')),
                      );
                      _fetchData(); // Refresh UI
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accessStatus == 'None' ? AppColors.primary : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  accessStatus == 'Pending' ? AppLocalizations.of(context).cdPendingApproval : AppLocalizations.of(context).cdRequestAccess,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildMemberInfo({required String label, required String name, required Color color}) {
    final initials = name.split(' ').map((e) => e[0]).take(2).join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssociationMembersModal extends StatefulWidget {
  const _AssociationMembersModal();

  @override
  State<_AssociationMembersModal> createState() => _AssociationMembersModalState();
}

class _AssociationMembersModalState extends State<_AssociationMembersModal> {
  bool _loading = true;
  String? _error;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await HttpAuthService().getAssociationMembers();
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Association Members', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _loading 
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null 
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _members.isEmpty 
                      ? const Center(child: Text('No members found.'))
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(24),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final m = _members[i];
                            final name = m['name'] ?? 'Unknown';
                            final email = m['email'] ?? '';
                            final role = m['role'] ?? 'member';
                            final profilePic = m['profilePicture'] as String?;
                            final assocLogo = m['associationLogo'] as String?;
                            Color roleColor = role == 'SA' ? const Color(0xFFC9A84C) : role == 'admin' ? const Color(0xFF34D399) : const Color(0xFF818CF8);
                            
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    userId: m['id'] as int,
                                    userName: name,
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSurface,
                                  border: Border.all(color: AppColors.borderSoft),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      profilePictureUrl: profilePic,
                                      associationLogoUrl: assocLogo,
                                      name: name,
                                      size: 44,
                                      animate: true,
                                      fallbackColor: roleColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                          Text(email, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(role == 'SA' ? 'Super Admin' : role == 'admin' ? 'Admin' : 'Member', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: roleColor)),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
