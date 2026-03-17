import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../services/circle_service.dart';
import '../../services/http_auth_service.dart';
import 'circle_details_screen.dart';
import 'create_circle_screen.dart';
import '../../l10n/app_localizations.dart';

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

      if (mounted) {
        setState(() {
          _associationName = data['associationName'];
          _activeMembersCount = data['activeMembersCount'] ?? 0;
          _meetingsCount = data['meetingsCount'] ?? 0;
          _circles = data['circles'] ?? [];
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
                      if ((HttpAuthService.currentUserRole == 'ADMIN' ||
                           HttpAuthService.currentIsInvitedAdmin) &&
                          HttpAuthService.currentUserNeedsSetup)
                        _buildRestrictedAdminBanner(context),
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
      floatingActionButton: ((HttpAuthService.currentUserRole == 'ADMIN' ||
          HttpAuthService.currentIsInvitedAdmin) &&
          HttpAuthService.currentUserNeedsSetup)
          ? null 
          : FloatingActionButton.extended(
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
            ),
    );
  }

  Widget _buildRestrictedAdminBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).cdActionRequired,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).cdActionMsg,
            style: GoogleFonts.inter(
              color: Colors.amber.shade900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile').then((_) {
                  setState(() {});
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.amber,
              ),
              child: Text(
                AppLocalizations.of(context).cdCompleteProfile,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
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
              Navigator.pushNamed(context, '/edit-profile');
            },
            child: Container(
               width: 40,
               height: 40,
               decoration: BoxDecoration(
                 color: AppColors.primary.withValues(alpha: 0.1),
                 shape: BoxShape.circle,
                 border: Border.all(color: AppColors.primary, width: 2),
               ),
               child: const Icon(Icons.person, color: AppColors.primary, size: 24),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('${_circles.length}', AppLocalizations.of(context).cdTotalCircles)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('$_activeMembersCount', AppLocalizations.of(context).cdActiveMembers)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('$_meetingsCount', AppLocalizations.of(context).cdMeetings)),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
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
  }) {
    final bool isActive = status.toLowerCase() == 'active';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          CircleDetailsScreen.routeName,
          arguments: circle,
        );
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? const Color(0xFFCEEAD6) : const Color(0xFFDADCE0)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF137333) : const Color(0xFF5F6368),
                  ),
                ),
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
