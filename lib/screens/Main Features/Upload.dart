import 'dart:io';
import 'package:flutter/material.dart';
import 'Pill_Assistant_Home.dart';

class MedicineResultScreen extends StatelessWidget {
  final Map<String, dynamic> medicineData;
  final String? imagePath;
  final String? ocrText;

  const MedicineResultScreen({
    super.key,
    required this.medicineData,
    this.imagePath,
    this.ocrText,
  });

  @override
  Widget build(BuildContext context) {
    final String medicineName =
        (medicineData['name'] ?? 'Unknown Medicine').toString();
    final String genericName =
        (medicineData['generic_name'] ?? 'Unknown').toString();
    final String dosage =
        (medicineData['dosage'] ?? 'Unknown').toString();
    final String description =
        (medicineData['description'] ?? 'No description available').toString();

    final String status =
        (medicineData['status'] ?? 'unknown').toString();

    final List<String> reasons =
        List<String>.from(medicineData['reasons'] ?? []);

    final double score = medicineData['score'] is num
        ? (medicineData['score'] as num).toDouble()
        : 0.0;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    if (status == 'safe') {
      statusColor = Colors.green;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'This medicine looks safe';
    } else if (status == 'caution') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'Use caution';
    } else if (status == 'not safe') {
      statusColor = Colors.red;
      statusIcon = Icons.dangerous_rounded;
      statusTitle = 'This medicine is not safe';
    } else {
      statusColor = const Color(0xFF3E84A8);
      statusIcon = Icons.medication_rounded;
      statusTitle = 'Medicine Identified';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(medicineName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (imagePath != null && imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(imagePath!),
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.12),
              ),
              child: Icon(
                statusIcon,
                size: 90,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              statusTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _buildInfoCard('Medicine Name', medicineName),
            _buildInfoCard('Generic Name', genericName),
            _buildInfoCard('Dosage', dosage),
            _buildInfoCard('Description', description),

            if (status != 'unknown')
              _buildInfoCard('Safety Status', status.toUpperCase()),

            if (reasons.isNotEmpty)
              _buildInfoCard('Reasons', reasons.join('\n• ')),

            _buildInfoCard('Match Score', score.toStringAsFixed(3)),

            if (ocrText != null && ocrText!.isNotEmpty)
              _buildInfoCard('OCR Text', ocrText!),

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