import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _reminders = true;
  bool _healthTips = true;
  bool _updates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text('notifications'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text('medication_reminders_title'.tr()),
            subtitle: Text('medication_reminders_subtitle'.tr()),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          SwitchListTile(
            title: Text('health_tips_title'.tr()),
            subtitle: Text('health_tips_subtitle'.tr()),
            value: _healthTips,
            onChanged: (v) => setState(() => _healthTips = v),
          ),
          SwitchListTile(
            title: Text('app_updates_title'.tr()),
            value: _updates,
            onChanged: (v) => setState(() => _updates = v),
          ),
          const Divider(),
          ListTile(
            title: Text('manage_notifications'.tr()),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('open_device_settings'.tr())),
              );
            },
          ),
        ],
      ),
    );
  }
}