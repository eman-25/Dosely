import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';

void main() => runApp(const HealthScanAIApp());

class HealthScanAIApp extends StatelessWidget {
  const HealthScanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthScanAI',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthScanAI')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Scan a medicine box to check interactions, allergies, and warnings.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => _goTo(context, const ScanScreen()),
              child: const Text('Start Live Scan'),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => _goTo(context, const ProfileScreen()),
              child: const Text('Medical Profile'),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => _goTo(context, const HistoryScreen()),
              child: const Text('Scan History'),
            ),
          ],
        ),
      ),
    );
  }
}
