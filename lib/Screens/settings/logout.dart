// lib/screens/settings/logout.dart
import 'package:flutter/material.dart';
import '/theme.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Log Out'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'Log out from Dosely?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'You will need to sign in again to access your medication analysis and health data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // TODO: Add real sign-out logic (FirebaseAuth, clear UserData, etc.)
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}