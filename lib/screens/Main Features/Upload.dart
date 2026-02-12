import 'package:flutter/material.dart';

class Upload extends StatelessWidget {
  const Upload({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: const Center(child: Text('Upload Screen')),
    );
  }
}