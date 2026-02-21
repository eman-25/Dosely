import 'package:flutter/material.dart';
import '/theme.dart'; // assuming AppColors exists

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Data Collection', [
            'We collect personal health information to provide accurate medication analysis.',
            'Email, username, date of birth, allergies, chronic conditions, current medications.',
          ]),
          _buildSection('Data Usage', [
            'Used only for AI-powered medication safety predictions.',
            'Never sold to third parties.',
          ]),
          _buildSection('Your Rights', [
            'You can request deletion of your data at any time.',
            'Manage permissions in device settings.',
          ]),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Allow analytics'),
            subtitle: const Text('Helps us improve the app'),
            value: true, // TODO: connect to real state
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: const Text('Personalized recommendations'),
            value: true,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('• $b'),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}