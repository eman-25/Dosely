import 'package:flutter/material.dart';

class Scan extends StatelessWidget {
  const Scan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: const Center(child: Text('Scan Screen')),
    );
  }
}