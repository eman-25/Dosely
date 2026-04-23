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

  static const Color _c1 = Color(0xFF48466E);
  static const Color _c2 = Color(0xFF3E84A8);
  static const Color _bg = Color(0xFFF7FBFD);

  @override
  Widget build(BuildContext context) {
    final String medicineName =
        (medicineData['name'] ?? 'Unknown Medicine').toString();
    final String genericName =
        (medicineData['generic_name'] ?? 'Unknown').toString();
    final String dosage = (medicineData['dosage'] ?? 'Unknown').toString();
    final String description =
        (medicineData['description'] ?? 'No description available').toString();
    final String status = (medicineData['status'] ?? 'unknown').toString();
    final List<String> reasons =
        List<String>.from(medicineData['reasons'] ?? const <String>[]);
    final double score = medicineData['score'] is num
        ? (medicineData['score'] as num).toDouble()
        : 0.0;

    final _StatusUi statusUi = _getStatusUi(status);
    final bool canAddToSchedule = status.toLowerCase() != 'not safe';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        foregroundColor: _c1,
        centerTitle: true,
        title: const Text(
          'Scan Result',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null && imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  File(imagePath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusUi.softColor, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: statusUi.color.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: statusUi.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusUi.icon, size: 42, color: statusUi.color),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    statusUi.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusUi.color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    medicineName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _c1,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.medication_rounded, dosage),
                      _infoChip(
                        Icons.analytics_rounded,
                        'Score ${score.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Medicine Details'),
            _buildInfoCard(
              'Medicine Name',
              medicineName,
              icon: Icons.local_pharmacy_rounded,
            ),
            _buildInfoCard(
              'Generic Name',
              genericName,
              icon: Icons.science_rounded,
            ),
            _buildInfoCard(
              'Dosage',
              dosage,
              icon: Icons.straighten_rounded,
            ),
            _buildInfoCard(
              'Description',
              description,
              icon: Icons.description_rounded,
            ),
            if (status != 'unknown')
              _buildInfoCard(
                'Safety Status',
                status.toUpperCase(),
                icon: statusUi.icon,
                accentColor: statusUi.color,
              ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              _sectionTitle('Why this result?'),
              ...reasons.map(
                (reason) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: statusUi.color.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: statusUi.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _c1,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!canAddToSchedule) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red.withOpacity(0.22)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.block_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This medicine cannot be added to your schedule because it is marked as not safe.',
                        style: TextStyle(
                          color: _c1,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAddToSchedule ? _c2 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    onPressed: canAddToSchedule
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to your schedule'),
                              ),
                            );
                          }
                        : null,
                    icon: Icon(
                      canAddToSchedule
                          ? Icons.add_task_rounded
                          : Icons.block_rounded,
                    ),
                    label: Text(
                      canAddToSchedule
                          ? 'Add to Schedule'
                          : 'Cannot Add to Schedule',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _c1,
                      side: BorderSide(color: _c2.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PillAssistantHome(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.smart_toy_rounded),
                    label: const Text(
                      'Ask Pillo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _c1,
        ),
      ),
    );
  }

  static Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _c2),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _c1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoCard(
    String title,
    String value, {
    required IconData icon,
    Color? accentColor,
  }) {
    final Color displayColor = accentColor ?? _c2;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: displayColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: displayColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _c1,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static _StatusUi _getStatusUi(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return const _StatusUi(
          title: 'This medicine looks safe',
          color: Colors.green,
          softColor: Color(0xFFEAF8EF),
          icon: Icons.verified_rounded,
        );
      case 'caution':
        return const _StatusUi(
          title: 'Use caution',
          color: Colors.orange,
          softColor: Color(0xFFFFF4E5),
          icon: Icons.warning_amber_rounded,
        );
      case 'not safe':
        return const _StatusUi(
          title: 'This medicine is not safe',
          color: Colors.red,
          softColor: Color(0xFFFFEBEE),
          icon: Icons.dangerous_rounded,
        );
      default:
        return const _StatusUi(
          title: 'Medicine Identified',
          color: _c2,
          softColor: Color(0xFFEAF4FA),
          icon: Icons.medication_rounded,
        );
    }
  }
}

class _StatusUi {
  final String title;
  final Color color;
  final Color softColor;
  final IconData icon;

  const _StatusUi({
    required this.title,
    required this.color,
    required this.softColor,
    required this.icon,
  });
}
