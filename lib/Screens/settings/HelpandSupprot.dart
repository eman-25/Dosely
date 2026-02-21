// lib/screens/helpandsupport.dart
import 'package:flutter/material.dart';
import '/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick actions
          _buildCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat with Support',
            subtitle: 'Get help from our team in real-time',
            onTap: () {
              // TODO: open chat (Intercom, Crisp, or custom form)
              _showComingSoon(context);
            },
          ),
          const SizedBox(height: 12),

          _buildCard(
            icon: Icons.email_outlined,
            title: 'Send us an email',
            subtitle: 'support@dosely.app',
            onTap: () {
              // TODO: url_launcher → mailto:support@dosely.app
              _showComingSoon(context);
            },
          ),
          const SizedBox(height: 24),

          // FAQ section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),

          _buildExpansionTile(
            question: 'How does Dosely analyze my medications?',
            answer:
                'We combine your personal health information (allergies, chronic conditions, current medications) with up-to-date pharmacological data and AI models to detect potential interactions, contraindications, and safer alternatives.',
          ),

          _buildExpansionTile(
            question: 'Is my health data safe?',
            answer:
                'Yes. All data is encrypted in transit and at rest. We follow best practices (GDPR/CCPA compliant where applicable) and never sell your personal information.',
          ),

          _buildExpansionTile(
            question: 'Can I delete my account?',
            answer:
                'Yes — go to Settings → Privacy → Request data deletion. Your account and health data will be permanently removed within 30 days.',
          ),

          _buildExpansionTile(
            question: 'Why do I need to provide health information?',
            answer:
                'Providing accurate allergies, conditions and medications allows Dosely to give much more personalized and safer recommendations.',
          ),
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
      const SnackBar(content: Text('Feature coming soon • We are working on it')),
    );
  }
}