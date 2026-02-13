import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// ✅ Import YOUR real home screen file:
import 'Screens/Main Features/Pill_Assistant_Home.dart';

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
      title: 'Dosely',
      theme: ThemeData(useMaterial3: true),
      home: const PillAssistantHome(), // ✅ must match class name in your file
    );
  }
}
