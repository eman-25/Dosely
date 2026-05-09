import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Pill_Assistant_Home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/description_simplifier_service.dart';

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

  String? _simplifiedDescription;
  bool _isSimplifying = false;

  @override
  void initState() {
    super.initState();
    _trackMedication();
    _simplifyDescriptionOnLoad();
  }

  // ✅ ENHANCED: Generate explanation + personalized dosage based on user health
  Future<void> _simplifyDescriptionOnLoad() async {
    setState(() {
      _isSimplifying = true;
    });

    int? ageInYears;
    if (widget.medicineData['dob'] != null && (widget.medicineData['dob'] as String).isNotEmpty) {
      try {
        final dob = DateTime.parse(widget.medicineData['dob'] as String);
        ageInYears = DateTime.now().difference(dob).inDays ~/ 365;
      } catch (_) {}
    }

    double? weightInKg;

    final simplified = await DescriptionSimplifierService.generateDetailedExplanation(
      medicineName: _name,
      genericName: _generic,
      ageInYears: ageInYears,
      weightInKg: weightInKg,
      allergies: widget.medicineData['allergies'] ?? '',
      chronicConditions: widget.medicineData['chronicConditions'] ?? '',
      specialConditions: widget.medicineData['specialConditions'] ?? '',
    );

    if (mounted) {
      setState(() {
        _simplifiedDescription = simplified;
        _isSimplifying = false;
      });
    }
  }

  Future<void> _trackMedication() async {
    try {
      // ✅ FIXED: Use 'name' field (brand name), not generic name
      final name = (widget.medicineData['name'] ?? '').toString();
      if (name.isEmpty) return;
      
      await FirebaseFirestore.instance.collection('medication_events').add({
        'medication_name': name,  // ✅ Brand name (e.g., "Panadol Extra")
        'generic_name': widget.medicineData['generic_name'] ?? '',  // Also save generic for reference
        'event_type': widget.imagePath != null ? 'scan/upload' : 'search',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Parsed data ─────────────────────────────────────────────────────────────

  // Brand label as printed on the box. Already cleaned & title-cased by
  // the lookup service, so we display it as-is (preserves "500mg", "5%", etc.)
  String get _name {
    final raw = (widget.medicineData['name'] ?? 'Unknown Medicine').toString().trim();
    return raw.isEmpty ? 'Unknown Medicine' : raw;
  }

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

  // ✅ UPDATED: Always show simplified description
  String get _description {
    if (_simplifiedDescription != null && _simplifiedDescription!.isNotEmpty) {
      return _simplifiedDescription!;
    }
    return 'Loading explanation...';
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

  bool get _hasFlags {
    final hasRealAllergyConflict = _allergyTrigger.isNotEmpty && 
        _allergyTrigger != 'none' && 
        _status == 'not safe';
    
    final hasPregnancyWarning = _pregnancyWarning == 'caution' || 
        _pregnancyWarning == 'avoid';
    
    return hasRealAllergyConflict || hasPregnancyWarning;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        foregroundColor: _c1,
        centerTitle: false,
        title: const Text(
          'Medicine Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Scanned image ─────────────────────────────────────
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ✅ MODERN CARD: Brand Name + Dosage + Status + Generic Name
            _modernMedicineCard(),
            const SizedBox(height: 16),

            // ── Description with AI explanation ────────────────────────────
            _descriptionTile(),
            const SizedBox(height: 16),

            // ── Flags if needed ───────────────────────────────────────────
            if (_hasFlags) ...[
              _flagRow(),
              const SizedBox(height: 16),
            ],

            // ── Why this result ───────────────────────────────────────────
            if (_reasons.isNotEmpty) ...[
              _reasonsCard(),
              const SizedBox(height: 20),
            ],

            // ── Action buttons ────────────────────────────────────────────
            _actionButtons(context),
            const SizedBox(height: 14),

            // ── Disclaimer ────────────────────────────────────────────────
            _disclaimer(),
          ],
        ),
      ),
    );
  }

  // ✅ Card: Status FIRST (big banner) → Brand from box → Generic → Dosage
  Widget _modernMedicineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1️⃣ STATUS BANNER (top, full width, most prominent) ──────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _statusColor.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor.withValues(alpha: 0.75),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── 2️⃣ BRAND NAME (as printed on the box) ──────────────────────
          Text(
            'Name on box',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _c1,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 14),

          // ── 3️⃣ GENERIC NAME (from drug databases) ──────────────────────
          Text(
            'Generic name',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _generic.isNotEmpty ? _generic : 'Not available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _generic.isNotEmpty ? _c2 : Colors.grey.shade500,
              fontStyle:
                  _generic.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── 4️⃣ DOSAGE ──────────────────────────────────────────────────
          Text(
            'Dosage',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dosage.isNotEmpty &&
                    !_dosage.toLowerCase().contains('see product')
                ? _dosage
                : 'Check package',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _c1,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Updated: Description with loading indicator
  Widget _descriptionTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _c2.withValues(alpha: 0.15), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outlined, size: 16, color: _c2),
              const SizedBox(width: 6),
              Text(
                'What it does',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _c2,
                ),
              ),
              if (_isSimplifying) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_c2),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagRow() {
    final hasRealAllergyConflict = _allergyTrigger.isNotEmpty && 
        _allergyTrigger != 'none' && 
        _status == 'not safe';
    
    final hasPregnancyWarning = _pregnancyWarning == 'caution' || 
        _pregnancyWarning == 'avoid';

    return Row(
      children: [
        if (hasRealAllergyConflict)
          _flagPill(
            icon: Icons.warning_rounded,
            label: 'Allergy Alert',
            color: Colors.red.shade700,
          ),
        if (hasRealAllergyConflict && hasPregnancyWarning)
          const SizedBox(width: 8),
        if (_pregnancyWarning == 'avoid')
          _flagPill(
            icon: Icons.pregnant_woman_rounded,
            label: 'Not for use in pregnancy',
            color: Colors.red.shade700,
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
        border: Border.all(color: _statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: _statusColor),
              const SizedBox(width: 6),
              Text(
                'Safety Check',
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
        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.6)),
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