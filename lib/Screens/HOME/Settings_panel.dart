// lib/screens/HOME/Settings_panel.dart
import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Icon(Icons.settings_rounded, size: 24, color: Colors.black87),
              SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
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
              _sectionTitle('Account'),
              _tile(context, Icons.edit, 'Edit profile', '/editProfile'),
              _tile(context, Icons.health_and_safety, 'Personal Health Information', '/editPersonalHealthInfo'),
              _tile(context, Icons.security, 'Security', '/security'),
              _tile(context, Icons.privacy_tip, 'Privacy', '/privacy'),

              const SizedBox(height: 16),
              _sectionTitle('App Preferences'),
              _tile(context, Icons.language, 'Language', '/language'),
              _tile(context, Icons.notifications, 'Notifications', '/notifications'),

              const SizedBox(height: 16),
              _sectionTitle('Support & About'),
              _tile(context, Icons.help_outline, 'Help & Support', '/helpSupport'),
              _tile(context, Icons.info_outline, 'About Us', '/aboutUs'),

              const SizedBox(height: 16),
              _sectionTitle('Actions'),
              _tile(context, Icons.report_gmailerrorred, 'Report a problem', '/reportProblem'),
              _tile(context, Icons.logout, 'Log out', '/logout'),
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