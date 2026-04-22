import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dosely/services/user_service.dart';
import 'package:dosely/screens/settings/edit_personalhealthinfo.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _allowAnalytics = true;
  bool _personalizedRecommendations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Security & Privacy Center', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHealthDataCard(),
          const SizedBox(height: 16),
          _buildRightsCard(context),
          const SizedBox(height: 16),
          _buildPrivacyControlsCard(),
          const SizedBox(height: 16),
          _buildAccountManagementCard(context),
        ],
      ),
    );
  }

  Widget _buildHealthDataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('How We Use Your Health Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Ensuring Your Medication Safety',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildRichBullet(
            icon: Icons.medication,
            title: 'AI Medication Safety:',
            text: ' Analyzes your medical history and allergies against new medications to predict potential adverse reactions and ensure safety.',
          ),
          const SizedBox(height: 12),
          _buildRichBullet(
            icon: Icons.error,
            title: 'Personalized Alerts:',
            text: ' Notifies you about potential drug-drug interactions specific to your current medication regimen.',
          ),
          const SizedBox(height: 12),
          _buildRichBullet(
            icon: Icons.sync,
            title: 'App Improvement:',
            text: ' We use anonymized usage data (if enabled below) to refine our features. ',
            boldTail: 'We never sell your data.',
          ),
        ],
      ),
    );
  }

  Widget _buildRichBullet({required IconData icon, required String title, required String text, String? boldTail}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3E84A8)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              children: [
                TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: text),
                if (boldTail != null) TextSpan(text: boldTail, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exercise Your Rights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.pan_tool_outlined, size: 28, color: const Color(0xFF3E84A8)),
              ],
            ),
          ),
          _buildRightTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Download Health Report',
            subtitle: 'Request a copy of your health data as a PDF report.',
            onTap: () => _handleAction(context, 'Generating PDF report...', 'PDF report downloaded successfully!'),
          ),
          _buildRightTile(
            icon: Icons.delete_outline,
            title: 'Manage/Clear History',
            subtitle: 'Review and clear parts of your search history without deleting the account.',
            onTap: () => _handleAction(context, 'Clearing history...', 'History cleared successfully!'),
            bottomRounded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRightTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool bottomRounded = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: bottomRounded ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
             Icon(icon, size: 28, color: const Color(0xFF3E84A8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyControlsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Text('Privacy Controls',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            secondary: const Icon(Icons.bar_chart, size: 28, color: Color(0xFF3E84A8)),
            title: const Text('Allow analytics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: const Text('Help us build safer features (anonymized data only)', style: TextStyle(fontSize: 13)),
            value: _allowAnalytics,
            activeColor: const Color(0xFF3E84A8),
            onChanged: (v) => setState(() => _allowAnalytics = v),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            secondary: const Icon(Icons.accessibility_new, size: 28, color: Color(0xFF3E84A8)),
            title: const Text('Personalized recommendations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: const Text('Use my medical history for customized safety alerts and predictions', style: TextStyle(fontSize: 13)),
            value: _personalizedRecommendations,
            activeColor: const Color(0xFF3E84A8),
            onChanged: (v) => setState(() => _personalizedRecommendations = v),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAccountManagementCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Account Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.manage_accounts_outlined, size: 28, color: const Color(0xFF3E84A8)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDeleteAccountDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('DELETE MY ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String loadingText, String successText) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(loadingText)),
          ],
        ),
      ),
    );

    // Simulate network/processing delay
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successText),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_deletion'.tr()),
        content: Text('delete_account_warning'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!context.mounted) return;
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await UserService.deleteUserAccount();
      await user.delete();

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('account_deleted_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_account_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}