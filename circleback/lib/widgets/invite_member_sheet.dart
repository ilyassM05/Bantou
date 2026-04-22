import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class InviteMemberSheet extends StatefulWidget {
  final Future<void> Function(String email) onInvite;

  const InviteMemberSheet({super.key, required this.onInvite});

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  bool get _isValidEmail {
    final text = _emailCtrl.text.trim();
    if (text.isEmpty) return false;
    final emailExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailExp.hasMatch(text);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    if (!_isValidEmail) return;
    setState(() => _isLoading = true);
    try {
      await widget.onInvite(_emailCtrl.text.trim());
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 64),
            const SizedBox(height: 16),
            Text('Invitation sent successfully', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('An email has been sent to ${_emailCtrl.text.trim()} with instructions to sign up.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _emailCtrl.clear();
                  setState(() => _isSuccess = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Invite Another Member', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Close', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Text('Invite a Member', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Send an invitation to join your association. They will receive an email with instructions to sign up.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter member email address',
              hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderSoft)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderSoft)),
              fillColor: AppColors.inputFill,
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValidEmail && !_isLoading ? _handleInvite : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Send Invitation', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
