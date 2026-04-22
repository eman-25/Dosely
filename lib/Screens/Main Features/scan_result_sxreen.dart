import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Scan Result Screen
/// ─────────────────
/// 1. Tries to match the scanned text against the medicine_dataset.csv
///    (loaded from assets) for Name, Strength, Category, Indication.
/// 2. Falls back to regex heuristics if no CSV match found.
/// 3. All displayed data is clearly labelled as OCR-derived / dataset-matched.

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final String recognizedText;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.recognizedText,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _loading = true;
  _MedResult? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final result = await _analyzeText(widget.recognizedText);
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  // ── CSV lookup + heuristic fallback ──────────────────────────────────────

  static Future<_MedResult> _analyzeText(String text) async {
    final cleaned = text.replaceAll('\n', ' ').trim();
    final lower = cleaned.toLowerCase();

    // 1. Try CSV dataset match
    try {
      final csv = await rootBundle.loadString('assets/data/medicine_dataset.csv');
      final lines = csv.split('\n');
      // header: Name,Category,Dosage Form,Strength,Manufacturer,Indication,Classification
      for (final line in lines.skip(1)) {
        final cols = line.split(',');
        if (cols.length < 7) continue;
        final name = cols[0].trim();
        if (name.isEmpty) continue;
        if (lower.contains(name.toLowerCase())) {
          return _MedResult(
            name: name,
            dosage: cols[3].trim(),
            category: cols[1].trim(),
            form: cols[2].trim(),
            manufacturer: cols[4].trim(),
            indication: cols[5].trim(),
            classification: cols[6].trim(),
            source: 'Dataset match',
          );
        }
      }
    } catch (_) {
      // asset not bundled — skip silently
    }

    // 2. Known medicine name list fallback
    const knownNames = [
      'Paracetamol', 'Panadol', 'Ibuprofen', 'Aspirin', 'Naproxen',
      'Amoxicillin', 'Augmentin', 'Azithromycin', 'Ciprofloxacin',
      'Metronidazole', 'Omeprazole', 'Pantoprazole', 'Metformin',
      'Atorvastatin', 'Rosuvastatin', 'Amlodipine', 'Lisinopril',
      'Losartan', 'Metoprolol', 'Furosemide', 'Warfarin',
      'Salbutamol', 'Ventolin', 'Budesonide', 'Levothyroxine',
      'Sertraline', 'Fluoxetine', 'Cetirizine', 'Loratadine',
      'Prednisolone', 'Dexamethasone', 'Tramadol', 'Diclofenac',
      'Celecoxib', 'Codeine', 'Morphine', 'Clarithromycin',
      'Doxycycline', 'Cephalexin', 'Vancomycin', 'Digoxin',
      'Clopidogrel', 'Simvastatin', 'Insulin', 'Glipizide',
      'Montelukast', 'Theophylline', 'Carbimazole', 'Ranitidine',
      'Domperidone', 'Loperamide', 'Lactulose', 'Mesalazine',
      'Amitriptyline', 'Venlafaxine', 'Alprazolam', 'Diazepam',
      'Clonazepam', 'Quetiapine', 'Risperidone', 'Lithium',
      'Carbamazepine', 'Valproate', 'Levetiracetam', 'Phenytoin',
      'Donepezil', 'Levodopa', 'Hydroxyzine', 'Allopurinol',
      'Colchicine', 'Hydroxychloroquine', 'Methotrexate', 'Azathioprine',
      'Olfen', 'Artelac', 'Augmentin',
    ];

    String? matchedName;
    for (final n in knownNames) {
      if (lower.contains(n.toLowerCase())) { matchedName = n; break; }
    }

    // 3. Regex dosage extraction
    final dosageReg = RegExp(r'(\d+(\.\d+)?)\s*(mg|mcg|µg|g|ml|IU|SR|drops?)\b', caseSensitive: false);
    final dosageMatch = dosageReg.firstMatch(cleaned);
    final dosage = dosageMatch != null
        ? '${dosageMatch.group(1)} ${dosageMatch.group(3)!.toUpperCase()}'
        : 'Not detected';

    // 4. Heuristic name from OCR lines
    if (matchedName == null) {
      final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (final line in lines.take(12)) {
        if (_looksLikeName(line)) { matchedName = line; break; }
      }
    }

    return _MedResult(
      name: matchedName ?? 'Not detected',
      dosage: dosage,
      category: null,
      form: null,
      manufacturer: null,
      indication: null,
      classification: null,
      source: matchedName != null ? 'OCR + known list' : 'OCR heuristic',
    );
  }

  static bool _looksLikeName(String s) {
    if (s.length < 3 || s.length > 35) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(s)) return false;
    if (RegExp(r'^\W*\d+').hasMatch(s)) return false;
    final low = s.toLowerCase();
    for (final skip in ['tablet', 'capsule', 'syrup', 'injection', 'cream', 'ointment', 'inhaler', 'drops', 'batch', 'exp', 'mfg', 'lot']) {
      if (low.startsWith(skip)) return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F7),
      appBar: AppBar(
        title: const Text('Scan Result',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Scanned image ──────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(widget.imagePath),
                      height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),

                // ── Source badge ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ACED0).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _result!.source,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2A8A8A),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Primary info ───────────────────────────────────────
                _InfoTile(icon: Icons.medication_rounded,
                    title: 'Medicine Name', value: _result!.name),
                const SizedBox(height: 10),
                _InfoTile(icon: Icons.science_rounded,
                    title: 'Strength / Dosage', value: _result!.dosage),

                // ── Dataset-enriched info (only if matched) ────────────
                if (_result!.category != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.category_rounded,
                      title: 'Category', value: _result!.category!),
                ],
                if (_result!.form != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.healing_rounded,
                      title: 'Dosage Form', value: _result!.form!),
                ],
                if (_result!.indication != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.info_outline_rounded,
                      title: 'Indication', value: _result!.indication!),
                ],
                if (_result!.classification != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.verified_user_rounded,
                      title: 'Classification', value: _result!.classification!),
                ],
                if (_result!.manufacturer != null) ...[
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.business_rounded,
                      title: 'Manufacturer', value: _result!.manufacturer!),
                ],

                // ── Disclaimer ─────────────────────────────────────────
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFB8860B), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Results are AI-assisted and may not be fully accurate. Always verify with a pharmacist or physician.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Full OCR text ──────────────────────────────────────
                const SizedBox(height: 20),
                const Text('Full OCR Text',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    widget.recognizedText.trim().isEmpty
                        ? 'No text detected.'
                        : widget.recognizedText,
                    style: const TextStyle(height: 1.45, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

class _MedResult {
  final String name, dosage, source;
  final String? category, form, manufacturer, indication, classification;

  const _MedResult({
    required this.name,
    required this.dosage,
    required this.source,
    this.category,
    this.form,
    this.manufacturer,
    this.indication,
    this.classification,
  });
}

// ── Info Tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  const _InfoTile({required this.icon, required this.title, required this.value});

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
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4ACED0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2A8A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}