import 'package:flutter/material.dart';

import 'screens/scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const MedAIApp());
}

class MedAIApp extends StatelessWidget {
  const MedAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedAI',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedAI')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _goTo(context, const ScanScreen()),
              child: const Text('Scan'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _goTo(context, const ProfileScreen()),
              child: const Text('Profile'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _goTo(context, const HistoryScreen()),
              child: const Text('History'),
            ),
          ],
        ),
      ),
    );
  }
}
