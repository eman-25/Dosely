import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  final double topSpacing;
  final double bottomSpacing;

  const SettingsPanel({
    super.key,
    this.topSpacing = 12,
    this.bottomSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    // This widget is meant to be placed INSIDE the settings sheet area.
    // So we keep it clean (no outer rounded container), just spacing + list.
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topSpacing, 16, bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 18, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _sectionTitle('Account'),
                _tile(Icons.edit, 'Edit profile'),
                _tile(Icons.health_and_safety, 'Personal Health Information'),
                _tile(Icons.security, 'Security'),

                const SizedBox(height: 10),
                _sectionTitle('App Preferences'),
                _tile(Icons.language, 'Language'),
                _tile(Icons.notifications, 'Notifications'),

                const SizedBox(height: 10),
                _sectionTitle('Support & About'),
                _tile(Icons.help_outline, 'Help & Support'),
                _tile(Icons.info_outline, 'About Us'),

                const SizedBox(height: 10),
                _sectionTitle('Actions'),
                _tile(Icons.report_gmailerrorred, 'Report a problem'),
                _tile(Icons.logout, 'Log out'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  static Widget _tile(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        leading: Icon(icon, size: 18, color: Colors.black87),
        title: Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
        onTap: () {},
      ),
    );
  }
}
