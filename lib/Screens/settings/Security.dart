import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
        title: Text('security'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFE8F5E9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: AppColors.primaryGreen, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('account_protected'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('last_password_change'.tr(),
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('login_access'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text('biometric_auth'.tr()),
            subtitle: Text('biometric_subtitle'.tr()),
            secondary: const Icon(Icons.fingerprint, color: AppColors.primaryBlue),
            value: _biometricsEnabled,
            onChanged: (v) => setState(() => _biometricsEnabled = v),
          ),
          SwitchListTile(
            title: Text('app_lock'.tr()),
            subtitle: Text('app_lock_subtitle'.tr()),
            secondary: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
            value: _appLockEnabled,
            onChanged: (v) => setState(() => _appLockEnabled = v),
          ),
          SwitchListTile(
            title: Text('two_factor'.tr()),
            subtitle: Text('two_factor_subtitle'.tr()),
            secondary: const Icon(Icons.phonelink_lock, color: AppColors.primaryBlue),
            value: _twoFactorAuth,
            onChanged: (v) => setState(() => _twoFactorAuth = v),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.password, color: AppColors.primaryBlue),
            title: Text('change_password_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('change_password_subtitle'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primaryBlue),
            title: Text('login_activity'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('login_activity_subtitle'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLoginHistory(context),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: 'sign_out_all'.tr(),
            color: Colors.redAccent,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('sign_out_everywhere'.tr()),
                  content: Text('sign_out_all_desc'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                      },
                      child: Text('sign_out_all_btn'.tr(),
                          style: const TextStyle(color: Colors.red)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('recent_login_activity'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: Text('device_iphone'.tr()),
              subtitle: Text('device_iphone_time'.tr()),
            ),
            ListTile(
              leading: const Icon(Icons.laptop),
              title: Text('device_chrome'.tr()),
              subtitle: Text('device_chrome_time'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}