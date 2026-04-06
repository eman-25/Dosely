import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dosely/services/user_service.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text('privacy'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('data_collection'.tr(), [
            'data_collection_1'.tr(),
            'data_collection_2'.tr(),
          ]),
          _buildSection('data_usage'.tr(), [
            'data_usage_1'.tr(),
            'data_usage_2'.tr(),
          ]),
          _buildSection('your_rights'.tr(), [
            'your_rights_1'.tr(),
            'your_rights_2'.tr(),
          ]),

          const SizedBox(height: 24),

          // Analytics & Recommendations switches
          SwitchListTile(
            title: Text('allow_analytics'.tr()),
            subtitle: Text('allow_analytics_subtitle'.tr()),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: Text('personalized_recommendations'.tr()),
            value: true,
            onChanged: (v) {},
          ),

          const SizedBox(height: 32),

          // Delete Account Section
          _buildDeleteAccountSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('• $b'),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  // Delete Account Section
  Widget _buildDeleteAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'account_management'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'delete_account'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_account_description'.tr(),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showDeleteAccountDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('delete_my_account'.tr().toUpperCase()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Show confirmation dialog
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_deletion'.tr()),
        content: Text(
          'delete_account_warning'.tr(),
        ),
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
      await _deleteAccount(context);
    }
  }

  // Actual account deletion logic
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 1. Delete Firestore user document
      await UserService.deleteUserAccount();

      // 2. Delete Firebase Authentication account
      await user.delete();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('account_deleted_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login screen and clear navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Close loading dialog if still open
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