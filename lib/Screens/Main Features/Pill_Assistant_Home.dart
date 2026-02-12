import 'package:flutter/material.dart';

class PillAssistantHome extends StatelessWidget {
  const PillAssistantHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pill Assistant')),
      body: const Center(child: Text('Pill Assistant Screen')),
    );
  }
}