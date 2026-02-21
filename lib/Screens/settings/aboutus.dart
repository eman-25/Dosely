import 'package:flutter/material.dart';
import '/theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: const Icon(Icons.medical_services, size: 60, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dosely',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Medication Analysis Using AI and Patient Medical History',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'Our Mission',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'We help patients and healthcare providers avoid medication errors by combining personal health data with AI-powered analysis.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text('Version 1.0.0 • © 2026 Dosely'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}