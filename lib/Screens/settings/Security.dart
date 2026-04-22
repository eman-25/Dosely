import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  void _sendResetLink() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('check_email'.tr()),
            content: Text('reset_link_sent'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ok'.tr()),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found for current user.')),
       );
    }
  }

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
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your health and data are secure',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('last_password_change'.tr(),
                          style: const TextStyle(color: Colors.black87, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.shield, color: Color(0xFF4ACED0), size: 48),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Security Tips & Guidelines',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E84A8),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.lock_outline,
            title: 'Privacy Protection',
            subtitle: 'Medication details are encrypted and invisible to third parties.',
          ),
          _buildInfoCard(
            icon: Icons.people_outline,
            title: 'Do Not Share PIN',
            subtitle: 'Dosely team will never request your secret PIN.',
            badgeIcon: Icons.cancel,
            badgeColor: Colors.redAccent,
          ),
          _buildInfoCard(
            icon: Icons.sync,
            title: 'Update App',
            subtitle: 'Regular application updates protect you from vulnerabilities.',
          ),
          _buildInfoCard(
            icon: Icons.fingerprint,
            title: 'Secure Your Phone',
            subtitle: 'Ensure your phone screen is locked with a PIN or biometric.',
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password, color: Color(0xFF3E84A8), size: 28),
            title: Text('change_password_title'.tr(),
                 style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            subtitle: Text('change_password_subtitle'.tr(), style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, color: Colors.black, size: 28),
            onTap: _sendResetLink,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'sign_out_all'.tr(),
            color: const Color(0xFFFF5252),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? badgeIcon,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: const Color(0xFF3E84A8), size: 28),
              if (badgeIcon != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(badgeIcon, color: badgeColor, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}