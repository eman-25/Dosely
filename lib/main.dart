import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

<<<<<<< HEAD
// ✅ Import YOUR real home screen file:
import 'Screens/Main Features/Pill_Assistant_Home.dart';
=======
import 'screens/Main Features/Scan.dart';
import 'screens/Main Features/Upload.dart';
import 'screens/Main Features/Search.dart';
import 'screens/Main Features/Pill_Assistant_Home.dart';
>>>>>>> f46e6a8bb0301bc39b6bf097968c513fe8a8a1fa

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // works fine on Android
  runApp(const DoselyApp());
}

class DoselyApp extends StatelessWidget {
  const DoselyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
      title: 'Dosely',
      theme: ThemeData(useMaterial3: true),
      home: const PillAssistantHome(), // ✅ must match class name in your file
=======
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
>>>>>>> f46e6a8bb0301bc39b6bf097968c513fe8a8a1fa
    );
  }
}


