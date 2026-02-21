import 'package:flutter/material.dart';
import '/theme.dart';

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
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Medication Reminders'),
            subtitle: const Text('Daily intake alerts'),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          SwitchListTile(
            title: const Text('Health Tips & Insights'),
            subtitle: const Text('Personalized advice from AI'),
            value: _healthTips,
            onChanged: (v) => setState(() => _healthTips = v),
          ),
          SwitchListTile(
            title: const Text('App Updates & News'),
            value: _updates,
            onChanged: (v) => setState(() => _updates = v),
          ),
          const Divider(),
          ListTile(
            title: const Text('Manage system notification permissions'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: open device settings (url_launcher or android_intent_plus)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open device settings → Notifications')),
              );
            },
          ),
        ],
      ),
    );
  }
}