import 'package:flutter/material.dart';
import 'Screens/HOME/home_screen.dart';

void main() {
  runApp(const DoselyApp());
}

class DoselyApp extends StatelessWidget {
  const DoselyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dosely',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // optional; if not available, it falls back
      ),
      home: const HomeScreen(),
    );
  }
}