import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

import '../../services/circle_service.dart';
import '../../l10n/app_localizations.dart';
class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await CircleService().getPendingRequests();
      if (mounted) {
        setState(() {
          _requests = data['pendingRequests'] ?? [];
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

  Future<void> _handleRequest(int requestId, String status, String requestType) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      await CircleService().respondToRequest(requestId, status, requestType: requestType);
      
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).prRequestAction(status))),
        );
        _fetchRequests(); // refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: Text(
          AppLocalizations.of(context).prTitle,
          style: GoogleFonts.inter(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                )
              : _requests.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).prNoRequests,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final req = _requests[index];
                        return _buildRequestCard(req);
                      },
                    ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final isAssociation = req['requestType'] == 'association';
    final isInvitation = req['requestType'] == 'invitation';
    
    String requestLabel = 'Circle Access Request';
    if (isAssociation) requestLabel = 'Association Join Request';
    if (isInvitation) requestLabel = 'Member Invitation';
    
    Color labelColor = Colors.purple.shade50;
    Color borderColor = Colors.purple.shade200;
    Color textColor = Colors.purple.shade700;
    
    if (isAssociation) {
      labelColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      textColor = Colors.blue.shade700;
    } else if (isInvitation) {
      labelColor = const Color(0xFFC9A84C).withValues(alpha: 0.1);
      borderColor = const Color(0xFFC9A84C).withValues(alpha: 0.3);
      textColor = const Color(0xFFC9A84C);
    }
      
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              requestLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isAssociation) ...[
             Text(
              'User: ${req['user_name'] ?? 'Unknown'} (${req['user_email'] ?? ''})',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
             Text(
              'Invited by: ${req['inviter_name'] ?? 'Unknown'}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            if (isInvitation) ...[
               Text(
                'Invited Email: ${req['user_email'] ?? ''}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
               Text(
                'Invited by: ${req['inviter_name'] ?? 'Unknown'}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if ((req['circle_name'] ?? '').isNotEmpty)
                Text(
                  'Circle: ${req['circle_name']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF818CF8),
                  ),
                ),
            ] else ...[
               Text(
                'Circle: ${req['circle_name'] ?? 'Unknown'}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
               Text(
                '${AppLocalizations.of(context).prAdmin}: ${req['user_name'] ?? 'Unknown'} (${req['user_email'] ?? ''})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleRequest(req['id'], 'Rejected', req['requestType'] ?? 'circle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context).prReject, style: GoogleFonts.inter()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRequest(req['id'], 'Approved', req['requestType'] ?? 'circle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context).prApprove, style: GoogleFonts.inter()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
