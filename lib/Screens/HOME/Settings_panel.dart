import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.settings_rounded, size: 24, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                'settings'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Scrollable Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _sectionTitle('account'.tr()),
              _tile(context, Icons.edit, 'edit_profile'.tr(), '/editProfile'),
              _tile(context, Icons.health_and_safety, 'personal_health_info'.tr(), '/editPersonalHealthInfo'),
              _tile(context, Icons.security, 'security'.tr(), '/security'),
              _tile(context, Icons.privacy_tip, 'privacy'.tr(), '/privacy'),

              const SizedBox(height: 16),
              _sectionTitle('app_preferences'.tr()),
              _tile(context, Icons.language, 'language'.tr(), '/language'),
              _tile(context, Icons.notifications, 'notifications'.tr(), '/notifications'),

              const SizedBox(height: 16),
              _sectionTitle('support_about'.tr()),
              _tile(context, Icons.help_outline, 'help_support'.tr(), '/helpSupport'),
              _tile(context, Icons.info_outline, 'about_us'.tr(), '/aboutUs'),

              const SizedBox(height: 16),
              _sectionTitle('actions'.tr()),
              _tile(context, Icons.report_gmailerrorred, 'report_problem'.tr(), '/reportProblem'),
              _tile(context, Icons.logout, 'logout'.tr(), '/logout'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.black87),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}