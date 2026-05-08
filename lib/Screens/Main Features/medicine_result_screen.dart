import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Pill_Assistant_Home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineResultScreen extends StatefulWidget {
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
  State<MedicineResultScreen> createState() => _MedicineResultScreenState();
}

class _MedicineResultScreenState extends State<MedicineResultScreen> {
  static const Color _c1     = Color(0xFF48466E);
  static const Color _c2     = Color(0xFF3E84A8);
  static const Color _bg     = Color(0xFFF7FBFD);
  static const Color _safe   = Color(0xFF1B8A5A);
  static const Color _warn   = Color(0xFFD97706);
  static const Color _danger = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _trackMedication();
  }

  Future<void> _trackMedication() async {
    try {
      final name = (widget.medicineData['name'] ?? '').toString();
      if (name.isEmpty) return;
      await FirebaseFirestore.instance.collection('medication_events').add({
        'medication_name': name,
        'event_type': widget.imagePath != null ? 'scan/upload' : 'search',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Parsed data ─────────────────────────────────────────────────────────────

  String get _name =>
      _cap((widget.medicineData['name'] ?? 'Unknown Medicine').toString());

  String get _generic =>
      _cap((widget.medicineData['generic_name'] ?? '').toString());

  String get _dosage =>
      (widget.medicineData['dosage'] ?? '').toString().trim();

  String get _status =>
      (widget.medicineData['status'] ?? 'unknown').toString().toLowerCase();

  List<String> get _reasons =>
      List<String>.from(widget.medicineData['reasons'] ?? []);

  String get _allergyTrigger =>
      (widget.medicineData['allergy_trigger'] ?? '').toString().trim().toLowerCase();

  String get _pregnancyWarning =>
      (widget.medicineData['pregnancy_warning'] ?? '').toString().trim().toLowerCase();

  String get _description {
    final raw = (widget.medicineData['description'] ?? '').toString().trim();
    final usable = raw.isNotEmpty &&
        !raw.toLowerCase().contains('see product label') &&
        !raw.toLowerCase().contains('consult your pharmacist') &&
        raw.length > 15;

    if (usable) {
      // Strip junk prefixes, keep only first clean sentence
      String s = raw
          .replaceAll(RegExp(
              r'\b(USES|USES:|DESCRIPTION:|INDICATIONS:|PURPOSE:)\b\s*',
              caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final dot = s.indexOf('.');
      if (dot > 20 && dot < 200) s = s.substring(0, dot + 1);
      if (s.length > 200) s = '${s.substring(0, 200)}...';
      return s;
    }

    // Fallback: build a minimal indication from the generic name
    final generic = (widget.medicineData['generic_name'] ?? '').toString().trim();
    if (generic.isNotEmpty) {
      return 'A medicine containing $generic. Consult the package leaflet for full indications.';
    }
    return 'Consult the package leaflet or your pharmacist for full indications.';
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  Color get _statusColor {
    switch (_status) {
      case 'safe':     return _safe;
      case 'caution':  return _warn;
      case 'not safe': return _danger;
      default:         return _c2;
    }
  }

  Color get _statusBg {
    switch (_status) {
      case 'safe':     return const Color(0xFFEAF7F1);
      case 'caution':  return const Color(0xFFFFF8EB);
      case 'not safe': return const Color(0xFFFFF0F0);
      default:         return const Color(0xFFEAF4FA);
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'safe':     return Icons.check_circle_rounded;
      case 'caution':  return Icons.warning_amber_rounded;
      case 'not safe': return Icons.cancel_rounded;
      default:         return Icons.medication_rounded;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'safe':     return 'Safe for you';
      case 'caution':  return 'Use with caution';
      case 'not safe': return 'Not safe for you';
      default:         return 'Result';
    }
  }

  bool get _canAddToSchedule => _status != 'not safe';

  bool get _hasFlags =>
      (_allergyTrigger.isNotEmpty && _allergyTrigger != 'none') ||
      (_pregnancyWarning == 'caution' || _pregnancyWarning == 'avoid');

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        foregroundColor: _c1,
        centerTitle: true,
        title: const Text(
          'Scan Result',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Scanned image (small) ─────────────────────────────────────
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(widget.imagePath!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── VERDICT CARD — the most important thing ───────────────────
            _verdictCard(),
            const SizedBox(height: 12),

            // ── INDICATIONS FOR USE — always shown ───────────────────────
            _descriptionTile(),
            const SizedBox(height: 8),

            // ── FLAG PILLS (allergy / pregnancy) ─────────────────────────
            if (_hasFlags) ...[
              _flagRow(),
              const SizedBox(height: 12),
            ],

            // ── WHY THIS RESULT ───────────────────────────────────────────
            _reasonsCard(),
            const SizedBox(height: 20),

            // ── ACTION BUTTONS ────────────────────────────────────────────
            _actionButtons(context),
            const SizedBox(height: 14),

            // ── DISCLAIMER ────────────────────────────────────────────────
            _disclaimer(),
          ],
        ),
      ),
    );
  }

  // ── Widget builders ─────────────────────────────────────────────────────────

  Widget _verdictCard() {
    final showDosage = _dosage.isNotEmpty &&
        !_dosage.toLowerCase().contains('see product') &&
        _dosage.length < 80;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusBg,
        border: Border.all(color: _statusColor.withOpacity(0.30), width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Status label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_statusIcon, color: _statusColor, size: 24),
              const SizedBox(width: 8),
              Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // Medicine name
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),

          // Generic name
          if (_generic.isNotEmpty && _generic.toLowerCase() != _name.toLowerCase()) ...[
            const SizedBox(height: 3),
            Text(
              _generic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Dosage pill
          if (showDosage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _dosage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _descriptionTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medication_liquid_rounded,
                  size: 15, color: Color(0xFF3E84A8)),
              SizedBox(width: 6),
              Text(
                'What it\'s used for',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3E84A8),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _description,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (_allergyTrigger.isNotEmpty && _allergyTrigger != 'none')
          _flagPill(
            icon: Icons.warning_rounded,
            label: 'Contains: ${_allergyTrigger}',
            color: Colors.deepOrange,
          ),
        if (_pregnancyWarning == 'avoid')
          _flagPill(
            icon: Icons.pregnant_woman_rounded,
            label: _status == 'not safe'
                ? 'Unsafe in pregnancy'
                : 'Not for use in pregnancy',
            color: _status == 'not safe'
                ? Colors.red.shade700
                : Colors.orange.shade700,
          ),
        if (_pregnancyWarning == 'caution')
          _flagPill(
            icon: Icons.pregnant_woman_rounded,
            label: 'Caution in pregnancy',
            color: Colors.orange.shade700,
          ),
      ],
    );
  }

  Widget _flagPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonsCard() {
    if (_reasons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: _statusColor),
              const SizedBox(width: 6),
              Text(
                'Why this result?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._reasons.map((reason) {
            final isGood = reason.toLowerCase().contains('no issues');
            final icon = isGood
                ? Icons.check_circle_outline_rounded
                : _status == 'not safe'
                    ? Icons.cancel_outlined
                    : Icons.arrow_right_rounded;
            final iconColor = isGood ? _safe : _statusColor;
            final textColor = isGood
                ? _safe
                : const Color(0xFF1E293B);

            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 17, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: textColor,
                        fontWeight:
                            isGood ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _canAddToSchedule ? _c2 : Colors.grey.shade400,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed:
                _canAddToSchedule ? () => _navigateToSchedule(context) : null,
            icon: Icon(
              _canAddToSchedule
                  ? Icons.add_task_rounded
                  : Icons.block_rounded,
              size: 19,
            ),
            label: Text(
              _canAddToSchedule ? 'Add to Schedule' : 'Cannot Add',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _c2,
              side: const BorderSide(color: _c2, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PillAssistantHome(uid: uid),
                ),
              );
            },
            icon: const Icon(Icons.smart_toy_rounded, size: 19),
            label: const Text(
              'Ask Pillo',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFD97706)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'These results are based on your health profile and do not replace a visit to a doctor or pharmacist. Always seek professional medical advice before taking any medication.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSchedule(BuildContext context) {
    // ── Replace with your actual schedule screen navigation ──────────────
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => YourScheduleScreen(
    //     medicineName: widget.medicineData['name'] ?? '',
    //     genericName:  widget.medicineData['generic_name'] ?? '',
    //     dosage:       widget.medicineData['dosage'] ?? '',
    //   ),
    // ));
    final name    = widget.medicineData['name'] ?? '';
    final generic = widget.medicineData['generic_name'] ?? '';
    final dosage  = widget.medicineData['dosage'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Adding $name${generic.isNotEmpty ? " ($generic)" : ""}${dosage.isNotEmpty ? " · $dosage" : ""} to schedule.',
      ),
      backgroundColor: _c2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  static String _cap(String s) => s
      .split(' ')
      .map((w) => w.isEmpty
          ? ''
          : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}