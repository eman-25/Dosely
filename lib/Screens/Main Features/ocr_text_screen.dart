import 'dart:io';
import 'package:flutter/material.dart';

class OcrTextScreen extends StatelessWidget {
  final String imagePath;
  final String text;

  const OcrTextScreen({
    super.key,
    required this.imagePath,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Result'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(imagePath),
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Text extracted from image:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              text.trim().isEmpty ? 'No text detected.' : text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}