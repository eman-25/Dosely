import 'package:flutter/material.dart';

import 'screens/Main Features/Scan.dart';
import 'screens/Main Features/Upload.dart';
import 'screens/Main Features/Search.dart';
import 'screens/Main Features/Pill_Assistant_Home.dart';

void main() {
  runApp(const MedAIApp());
}

class MedAIApp extends StatelessWidget {
  const MedAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DOSELY',
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
      appBar: AppBar(title: const Text('Dosely')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _goTo(context, const Scan()),
              child: const Text('Scan'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _goTo(context, const Upload()),
              child: const Text('Upload'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _goTo(context, const Search()),
              child: const Text('Search'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _goTo(context, const PillAssistantHome()),
              child: const Text('Pill Assistant Home'),
            ),
            const SizedBox(height: 12),
            
          ],
        ),
      ),
    );
  }
}


