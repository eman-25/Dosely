import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';
import 'package:url_launcher/url_launcher.dart';   // ← This is the correct import

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
          // Email Support Card (Chat removed)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.email_outlined, color: AppColors.primaryBlue, size: 28),
              title: Text(
                'send_us_an_email'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'doselysupport@gmail.com',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: _launchEmail,
            ),
          ),

          const SizedBox(height: 32),

          // Frequently Asked Questions
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'frequently_asked_questions'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),

          _buildExpansionTile(
            question: 'faq_q1'.tr(),
            answer: 'faq_a1'.tr(),
          ),
          _buildExpansionTile(
            question: 'faq_q2'.tr(),
            answer: 'faq_a2'.tr(),
          ),
          _buildExpansionTile(
            question: 'can_i_delete_my_account'.tr(),
            answer: 'faq_a3'.tr(),           // Using existing faq_a3 which already mentions Privacy
            initiallyExpanded: true,
          ),
          _buildExpansionTile(
            question: 'faq_q4'.tr(),
            answer: 'faq_a4'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile({
    required String question,
    required String answer,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  // Fixed: Proper email launcher function
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'doselysupport@gmail.com',
      query: 'subject=Support Request from Dosely App',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Optional: Show message if email client fails to open
      // You can add a SnackBar here if you want
    }
  }
}