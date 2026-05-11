// ============================================================
//  medicine_service.dart
//
//  Central service that ties together:
//    1. OCR image processing (camera / gallery)
//    2. Smart medicine-name extraction from OCR text
//    3. Bahrain MOH drug dictionary lookup (local name matching)
//    4. Global API enrichment via MedicineCacheService
//       (OpenFDA → RxNorm → DailyMed, with auto-save to Firestore)
//    5. Full safety check via FirebaseMedicineChecker
//
//  Every unique medicine found is automatically saved to the
//  `medicines` Firestore collection so future lookups are instant.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dosely/models/medicine_model.dart';
import 'package:dosely/Screens/Main Features/api_key.dart';
import 'medicine_cache_service.dart';
import 'firebase_medicine_checker.dart';

class MedicineService {
  static final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // ── Words that are NEVER medicine names (packaging noise) ────────────────
  static const _noiseWords = {
    'lot', 'exp', 'ndc', 'mfg', 'batch', 'ref', 'barcode', 'gtin',
    'manufactured', 'distributed', 'store', 'keep', 'use', 'see',
    'read', 'insert', 'leaflet', 'doctor', 'physician', 'pharmacist',
    'tablet', 'tablets', 'capsule', 'capsules', 'syrup', 'injection',
    'each', 'contains', 'excipient', 'ingredient', 'active', 'inactive',
    'warning', 'caution', 'rx', 'only', 'prescription', 'storage',
    'date', 'dosage', 'dose', 'adults', 'children', 'oral', 'route',
    'reliever', 'strength', 'relief', 'pain', 'fever', 'cold', 'cough',
    'supplement', 'effective', 'extra',
  };

  // ── Known brand name prefixes ──────────────────────
  static const _brandNameIndicators = [
    'panadol', 'tylenol', 'ibuprofen', 'brufen', 'aspirin', 'amoxicillin',
    'augmentin', 'penicillin', 'metformin', 'lisinopril', 'atorvastatin',
    'omeprazole', 'loratadine', 'cetirizine', 'fluconazole', 'azithromycin',
  ];

  // =========================================================================
  //  1. IMAGE → OCR TEXT
  //  Processes any image path (camera snapshot or gallery pick).
  //  Returns the raw recognised text string.
  // =========================================================================
  static Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognised = await _recognizer.processImage(inputImage);
    return recognised.text;
  }

  // =========================================================================
  //  2. OCR TEXT → RANKED MEDICINE NAME CANDIDATES (IMPROVED)
  //
  //  Scoring heuristics (higher = better):
  //   +5  Line is 1 word, 3-15 chars (typical brand name like "Panadol")
  //   +3  ALL-CAPS or TitleCase (brand names usually are)
  //   +3  Known brand name (panadol, ibuprofen, etc.)
  //   +2  Length 3–25 chars
  //   +2  Known pharmaceutical INN suffix (-olol, -prazole, -mycin, etc.)
  //   +1  Pure alpha (no digits or special chars)
  //   −5  Line is long (>35 chars, likely a sentence like "Pain Reliever Extra")
  //   −3  Known noise word
  //   −2  Contains a run of 3+ digits (serial / barcode)
  //   −1  Starts with a digit
  // =========================================================================
  static List<String> extractMedicineCandidates(String ocrText) {
    final lines = ocrText
        .split(RegExp(r'[\n\r]+'))
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();

    final scored = <MapEntry<String, int>>[];

    for (final line in lines) {
      final token = _bestTokenFromLine(line);
      if (token.isEmpty || token.length < 3) continue;

      int score = 0;
      final lower = token.toLowerCase();
      final wordCount = token.split(RegExp(r'\s+')).length;

      // ✅ MAJOR BOOST: Short, single-word tokens are almost always brand names
      if (wordCount == 1 && token.length >= 3 && token.length <= 15) {
        score += 5;
      }

      // ✅ Known brand names get a boost
      if (_brandNameIndicators.any((b) => lower.contains(b))) {
        score += 3;
      }

      // Positive signals
      if (token == token.toUpperCase() || _isTitleCase(token)) score += 3;
      if (token.length >= 3 && token.length <= 25) score += 2;
      if (_hasMedicineSuffix(lower)) score += 2;
      if (RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(token)) score += 1;

      // ✅ MAJOR PENALTY: Long descriptive text (Pain Reliever Extra Strength)
      if (line.length > 35 || wordCount > 3) score -= 5;

      // Negative signals
      if (_noiseWords.contains(lower)) score -= 3;
      if (RegExp(r'^\d').hasMatch(token)) score -= 1;
      if (RegExp(r'\d{3,}').hasMatch(token)) score -= 2;

      if (score >= 0) scored.add(MapEntry(token, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final seen = <String>{};
    final result = <String>[];
    for (final e in scored) {
      final n = _normalize(e.key);
      if (seen.add(n)) result.add(n);
      if (result.length >= 5) break;
    }
    return result;
  }

  /// Convenience: returns just the top candidate (for legacy call sites).
  static String extractMedicineName(String ocrText) {
    final candidates = extractMedicineCandidates(ocrText);
    return candidates.isNotEmpty ? candidates.first : '';
  }

  // =========================================================================
  //  AI-POWERED NAME EXTRACTION
  //  Uses Gemini to identify the medicine name from raw OCR text.
  //  Returns null on failure so callers can fall back to the heuristic.
  // =========================================================================
  static Future<String?> aiExtractMedicineName(String ocrText) async {
    if (ocrText.trim().isEmpty) return null;
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt = '''The following text was scanned from a medicine box using OCR:

"""
$ocrText
"""

What is the medicine name? Return ONLY the medicine brand name or generic name (e.g. "Panadol", "Amoxicillin", "Ibuprofen"). No explanation, no extra text, just the name.''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 8));

      final name = (response.text ?? '').trim().split('\n').first.trim();
      if (name.isEmpty || name.length > 40) return null;
      return name;
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  //  3. BAHRAIN MOH DRUG DICTIONARY LOOKUP
  //
  //  The Ministry of Health Bahrain publishes a searchable drug dictionary at:
  //  https://www.moh.gov.bh/HealthInfo/DrugDictionary
  //
  //  The site exposes a JSON endpoint used by its own search widget.
  //  We query it with the candidate name; if a match is found we use the
  //  MOH-approved name as the canonical lookup key (better for local users).
  //
  //  Returns the MOH canonical drug name, or null if not found / unreachable.
  // =========================================================================
  static Future<String?> lookupMohBahrain(String query) async {
    // MOH Bahrain uses this internal API endpoint for the drug dictionary search
    final url = Uri.parse(
      'https://www.moh.gov.bh/api/DrugDictionary/Search'
      '?query=${Uri.encodeComponent(query)}&pageSize=1',
    );

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      // The MOH API typically returns { "items": [ { "tradeName": "...", "genericName": "..." } ] }
      // or { "data": [ ... ] } — we handle both shapes defensively.
      List? items;
      if (data is Map) {
        items = (data['items'] ?? data['data'] ?? data['results']) as List?;
      } else if (data is List) {
        items = data;
      }

      if (items == null || items.isEmpty) return null;

      final first = items.first as Map<String, dynamic>;
      // Prefer trade name (brand) since that's what the user scanned
      final tradeName   = first['tradeName']?.toString().trim();
      final genericName = first['genericName']?.toString().trim();

      return (tradeName?.isNotEmpty == true) ? tradeName : genericName;
    } catch (_) {
      return null; // MOH site unavailable — fall through to global APIs
    }
  }

  // =========================================================================
  //  4. FULL LOOKUP: OCR TEXT → MedicineModel (with auto-save to Firestore)
  //
  //  Pipeline:
  //    a. Extract ranked name candidates from OCR
  //    b. For each candidate: try MOH Bahrain first (local authority)
  //    c. Fall through to MedicineCacheService (Firestore → OpenFDA → RxNorm)
  //    d. First successful result is returned; auto-saved by CacheService
  // =========================================================================
  static Future<MedicineModel?> lookupFromOcr(String ocrText) async {
    // Try AI extraction first — it understands context better than heuristics
    final aiName = await aiExtractMedicineName(ocrText);

    final candidates = [
      if (aiName != null) aiName,
      ...extractMedicineCandidates(ocrText),
    ];
    if (candidates.isEmpty) return null;

    for (final candidate in candidates) {
      // Try MOH Bahrain first — gives us a locally-approved canonical name
      final mohName = await lookupMohBahrain(candidate);
      final queryName = mohName ?? candidate;

      // MedicineCacheService: Firestore → global APIs → auto-save
      final result = await MedicineCacheService.getMedicine(queryName);
      if (result != null) return result;

      // If MOH gave a different name and global lookup still failed,
      // retry with the original candidate
      if (mohName != null && mohName != candidate) {
        final fallback = await MedicineCacheService.getMedicine(candidate);
        if (fallback != null) return fallback;
      }
    }
    return null;
  }

  /// Name-based lookup (search screen). Auto-saves result to Firestore.
  static Future<MedicineModel?> lookupByName(String name) async {
    if (name.trim().isEmpty) return null;
    final mohName = await lookupMohBahrain(name.trim());
    return MedicineCacheService.getMedicine(mohName ?? name.trim());
  }

  // =========================================================================
  //  5. FULL SAFETY CHECK (OCR path)
  //  Combines lookup + safety engine in one call for the scan screen.
  // =========================================================================
  static Future<Map<String, dynamic>?> checkFromOcr({
    required String uid,
    required String ocrText,
  }) =>
      FirebaseMedicineChecker.checkFromOcr(uid: uid, ocrText: ocrText);

  /// Full safety check from a typed/search name.
  static Future<Map<String, dynamic>?> checkByName({
    required String uid,
    required String medicineName,
  }) =>
      FirebaseMedicineChecker.checkByName(uid: uid, medicineName: medicineName);

  // =========================================================================
  //  PRIVATE HELPERS
  // =========================================================================

  static String _bestTokenFromLine(String line) {
    final clean = line
        .replaceAll(RegExp(r'^[A-Za-z]+:\s*'), '') // strip "Brand: " prefix
        .replaceAll(RegExp(r'[®™©]'), '')
        .trim();

    // If the whole line is letters/spaces/hyphens and short → use it as-is
    if (RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(clean) && clean.length <= 30) {
      return clean.trim();
    }

    // ✅ IMPROVED: Extract the FIRST meaningful word (usually the brand name)
    // For "Pain Reliever Extra Strength", prefer "Pain" (short)
    // But prefer even shorter words, so find the shortest
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => RegExp(r'^[a-zA-Z]{3,}$').hasMatch(w))
        .toList();

    if (words.isEmpty) {
      // Fallback: extract the longest purely alphabetic run
      final tokens = RegExp(r'[a-zA-Z]{3,}').allMatches(clean);
      String best = '';
      for (final m in tokens) {
        if (m.group(0)!.length > best.length) best = m.group(0)!;
      }
      return best;
    }

    // ✅ Prefer short words (brand names) over long ones
    // Panadol (7 chars) > Pain Reliever Extra Strength
    words.sort((a, b) => a.length.compareTo(b.length));
    return words.first; // Return the shortest word
  }

  static bool _isTitleCase(String s) {
    final words = s.split(' ');
    return words.isNotEmpty &&
        words.every((w) =>
            w.isEmpty ||
            (w[0] == w[0].toUpperCase() &&
                w.substring(1) == w.substring(1).toLowerCase()));
  }

  static bool _hasMedicineSuffix(String lower) {
    const suffixes = [
      'mab', 'nib', 'vir', 'olol', 'ipril', 'sartan', 'statin',
      'mycin', 'cyclin', 'oxacin', 'prazole', 'pam', 'lam', 'zepam',
      'azole', 'conazole', 'cillin', 'clovir', 'fenac', 'profen',
      'codone', 'pentin', 'vastatin', 'gliptin', 'gliflozin',
      'tide', 'zumab', 'kinase', 'triptan', 'dronate',
    ];
    return suffixes.any((s) => lower.endsWith(s));
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}