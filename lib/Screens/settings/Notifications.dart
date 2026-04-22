import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _intakeReminders = true;
  bool _appUpdates = false;

  final Color _activeSwitchColor = const Color(0xFF5B459E); // Indigo specifically from the design

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSectionHeader(Icons.medication, 'Critical Medication Alerts'),
          _buildSwitchTile(
            title: 'Intake Reminders',
            desc: 'Notifications for your scheduled doses.',
            value: _intakeReminders,
            onChanged: (v) => setState(() => _intakeReminders = v),
            extraWidget: Row(
              children: [
                const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF2C5E7A)),
                const SizedBox(width: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(text: 'Priority Sound: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Enabled'),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.notifications_active, size: 16, color: Color(0xFF2C5E7A)),
              ],
            ),
          ),

          
          const SizedBox(height: 32),
          _buildSectionHeader(Icons.system_update_alt, 'Application Updates'),
          _buildSwitchTile(
            title: 'New Features & Announcements',
            desc: 'Be the first to know about new app capabilities.',
            value: _appUpdates,
            onChanged: (v) => setState(() => _appUpdates = v),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(thickness: 0.8, color: Colors.black12),
          ),
          
          _buildSystemSettingsCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C5E7A), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? extraWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.normal, color: Colors.black)),
              const SizedBox(height: 4),
              Text('Desc: $desc', style: const TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.25)),
              if (extraWidget != null) ...[
                const SizedBox(height: 8),
                extraWidget,
              ]
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 50,
          child: Transform.scale(
            scale: 0.95,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: _activeSwitchColor,
              trackColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please adjust permissions in device settings.')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Notification Settings',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Adjust critical permissions at the system level for priority alerts and lock-screen display.',
                        style: TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.25),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chevron_right, color: Colors.black, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}