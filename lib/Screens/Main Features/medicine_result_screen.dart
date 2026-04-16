import 'dart:io';
import 'package:flutter/material.dart';
import 'Pill_Assistant_Home.dart';

class MedicineResultScreen extends StatelessWidget {
  final Map<String, dynamic> medicineData;
  final String imagePath;
  final String ocrText;

  const MedicineResultScreen({
    super.key,
    required this.medicineData,
    required this.imagePath,
    required this.ocrText,
  });

  @override
  Widget build(BuildContext context) {
    final String medicineName =
        (medicineData['name'] ?? 'Unknown Medicine').toString();
    final String genericName =
        (medicineData['generic_name'] ?? 'Unknown').toString();
    final String dosage = (medicineData['dosage'] ?? 'Unknown').toString();
    final String description =
        (medicineData['description'] ?? 'No description available').toString();

    final double score = medicineData['score'] is num
        ? (medicineData['score'] as num).toDouble()
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(medicineName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(imagePath),
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3E84A8).withOpacity(0.12),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 90,
                color: Color(0xFF3E84A8),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Medicine Identified',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E84A8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _buildInfoCard('Medicine Name', medicineName),
            _buildInfoCard('Generic Name', genericName),
            _buildInfoCard('Dosage', dosage),
            _buildInfoCard('Description', description),
            _buildInfoCard('Match Score', score.toStringAsFixed(3)),
            _buildInfoCard('OCR Text', ocrText.isEmpty ? 'No text found' : ocrText),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Added to your schedule'),
                        ),
                      );
                    },
                    child: const Text('Add to Schedule'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PillAssistantHome(),
                        ),
                      );
                    },
                    child: const Text('Ask Pillo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}