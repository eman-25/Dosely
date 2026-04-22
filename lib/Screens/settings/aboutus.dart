import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '/theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text('about_us'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/dosely_logo.png',
              height: 100,
            ),
            const SizedBox(height: 8),
            Text(
              'about_us_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Text(
              'our_mission'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'our_mission_text'.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text('version'.tr()),
            const SizedBox(height: 32),
            const Text(
              'Contact Founders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: AppColors.primaryBlue),
              ),
              title: const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('doselysupport@gmail.com'),
              onTap: () async {
                final url = Uri.parse('mailto:doselysupport@gmail.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryBlue),
              ),
              title: const Text('Instagram', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('@dosely.bh'),
              onTap: () async {
                final url = Uri.parse('https://www.instagram.com/dosely.bh?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}