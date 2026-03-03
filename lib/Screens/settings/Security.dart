// lib/screens/settings/Security.dart
import 'package:flutter/material.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricsEnabled = true;
  bool _appLockEnabled = false;
  bool _twoFactorAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security status card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFE8F5E9),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.shield, color: AppColors.primaryGreen, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your account is protected',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Last password change: 14 days ago',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Login & Access',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Biometric authentication'),
            subtitle: const Text('Use fingerprint or face recognition'),
            secondary: const Icon(Icons.fingerprint, color: AppColors.primaryBlue),
            value: _biometricsEnabled,
            onChanged: (v) => setState(() => _biometricsEnabled = v),
          ),

          SwitchListTile(
            title: const Text('App lock'),
            subtitle: const Text('Require PIN or pattern'),
            secondary: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
            value: _appLockEnabled,
            onChanged: (v) => setState(() => _appLockEnabled = v),
          ),

          SwitchListTile(
            title: const Text('Two-factor authentication'),
            subtitle: const Text('Extra security with SMS / authenticator'),
            secondary: const Icon(Icons.phonelink_lock, color: AppColors.primaryBlue),
            value: _twoFactorAuth,
            onChanged: (v) => setState(() => _twoFactorAuth = v),
          ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.password, color: AppColors.primaryBlue),
            title: const Text('Change password', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),

          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primaryBlue),
            title: const Text('Login activity', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('See recent logins'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLoginHistory(context),
          ),

          const SizedBox(height: 40),

          // Red danger button - using your existing CustomButton
          CustomButton(
            text: 'Sign out from all devices',
            color: Colors.redAccent,           // ← This is the correct parameter
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign out everywhere?'),
                  content: const Text('This will log you out from all devices.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        //TODO: Add real sign-out logic later (Firebase, etc.)
                        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                      },
                      child: const Text('Sign out all', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLoginHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent login activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 16),
            ListTile(leading: Icon(Icons.smartphone), title: Text('iPhone 14 • Bahrain'), subtitle: Text('Today at 01:49 AM • This device')),
            ListTile(leading: Icon(Icons.laptop), title: Text('Chrome on Windows'), subtitle: Text('February 19, 2026')),
          ],
        ),
      ),
    );
  }
}