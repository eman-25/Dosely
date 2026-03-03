import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanResultScreen extends StatelessWidget {
  final String imagePath;
  final String recognizedText;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.recognizedText,
  });

  // ====== SIMPLE heuristics to guess medicine name & dosage ======
  // You can improve later by using a medicine database.
  String guessDosage(String text) {
    final t = text.replaceAll('\n', ' ').toLowerCase();

    // common dosage patterns: 500mg, 5 mg, 10ml, 250 mcg, 1g
    final reg = RegExp(r'(\d+(\.\d+)?)\s*(mg|mcg|µg|g|ml)\b', caseSensitive: false);
    final m = reg.firstMatch(t);
    if (m == null) return 'Not found';
    return '${m.group(1)} ${m.group(3)!.toUpperCase()}';
  }

  String guessMedicineName(String text) {
    // Strategy:
    // 1) take first few non-empty lines
    // 2) ignore lines that are mostly numbers/symbols
    // 3) prefer lines with letters and short length (like a product name)
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    bool looksLikeName(String s) {
      if (s.length < 3 || s.length > 30) return false;
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(s);
      if (!hasLetters) return false;
      final tooNumeric = RegExp(r'^\W*\d+').hasMatch(s);
      if (tooNumeric) return false;
      // avoid "tablet", "capsule", "dosage form" lines if possible
      final low = s.toLowerCase();
      if (low.contains('tablet') || low.contains('capsule') || low.contains('syrup')) {
        return false;
      }
      return true;
    }

    for (final line in lines.take(12)) {
      if (looksLikeName(line)) return line;
    }
    return 'Not found';
  }

  @override
  Widget build(BuildContext context) {
    final name = guessMedicineName(recognizedText);
    final dosage = guessDosage(recognizedText);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(imagePath), height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),

          _InfoTile(title: 'Medicine name (guess)', value: name),
          const SizedBox(height: 10),
          _InfoTile(title: 'Dosage (guess)', value: dosage),

          const SizedBox(height: 18),
          const Text(
            'Full text read',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              recognizedText.trim().isEmpty ? 'No text detected.' : recognizedText,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5, color: Colors.black54)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}