import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text('help_support'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            icon: Icons.chat_bubble_outline,
            title: 'chat_support'.tr(),
            subtitle: 'chat_support_subtitle'.tr(),
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.email_outlined,
            title: 'email_support'.tr(),
            subtitle: 'email_support_subtitle'.tr(),
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'faq'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          _buildExpansionTile(question: 'faq_q1'.tr(), answer: 'faq_a1'.tr()),
          _buildExpansionTile(question: 'faq_q2'.tr(), answer: 'faq_a2'.tr()),
          _buildExpansionTile(question: 'faq_q3'.tr(), answer: 'faq_a3'.tr()),
          _buildExpansionTile(question: 'faq_q4'.tr(), answer: 'faq_a4'.tr()),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExpansionTile({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('coming_soon'.tr())),
    );
  }
}