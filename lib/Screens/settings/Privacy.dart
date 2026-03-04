import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text('privacy'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('data_collection'.tr(), [
            'data_collection_1'.tr(),
            'data_collection_2'.tr(),
          ]),
          _buildSection('data_usage'.tr(), [
            'data_usage_1'.tr(),
            'data_usage_2'.tr(),
          ]),
          _buildSection('your_rights'.tr(), [
            'your_rights_1'.tr(),
            'your_rights_2'.tr(),
          ]),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text('allow_analytics'.tr()),
            subtitle: Text('allow_analytics_subtitle'.tr()),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: Text('personalized_recommendations'.tr()),
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