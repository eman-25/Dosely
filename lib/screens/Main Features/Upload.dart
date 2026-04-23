import 'package:flutter/material.dart';

class Upload extends StatelessWidget {
  const Upload({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medicine'),
      ),
      body: const Center(
        child: Text(
          'Upload screen here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}