// ============================================================
//  medicine_cache_service.dart
//
//  Cache-first orchestrator.
//
//  Lookup order:
//    1. Firestore (instant, free, offline-capable after first hit)
//       – exact name  → exact generic_name  → aliases array-contains
//    2. If stale or missing → MedicineApiLayer (OpenFDA + RxNorm + DailyMed)
//    3. Save / merge result back into Firestore
//
//  FIX: Smarter OCR token extraction — scores candidate lines instead of
//  blindly taking the first word. Filters out noise like LOT, EXP, NDC,
//  serial numbers, and other non-medicine text commonly found on packaging.
// ============================================================
import 'package:dosely/models/medicine_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medicine_api_layer.dart';

class MedicineCacheService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col           = 'medicines';

  // ── In-process memory cache (per app session) ─────────────────────────────
  static final Map<String, MedicineModel> _memCache = {};

  // ── Words that are NEVER medicine names ───────────────────────────────────
  // Found on nearly every medicine box but mean nothing to our lookup.
  static const _noiseWords = {
    'lot', 'exp', 'ndc', 'mfg', 'batch', 'ref', 'barcode', 'gtin',
    'manufactured', 'distributed', 'store', 'keep', 'use', 'see',
    'read', 'insert', 'leaflet', 'doctor', 'physician', 'pharmacist',
    'tablet', 'tablets', 'capsule', 'capsules', 'syrup', 'injection',
    'each', 'contains', 'excipient', 'ingredient', 'active', 'inactive',
    'warning', 'caution', 'rx', 'only', 'prescription',
  };

  // =========================================================================
  //  PUBLIC API
  // =========================================================================

  /// Main entry point. Returns a fully enriched [MedicineModel] or null.
  static Future<MedicineModel?> getMedicine(String query) async {
    final q = _n(query);
    if (q.isEmpty) return null;

    // ── Memory cache ──────────────────────────────────────────────────────
    if (_memCache.containsKey(q)) return _memCache[q];

    // ── Firestore cache ───────────────────────────────────────────────────
    final cached = await _fromFirestore(q);
    if (cached != null && !cached.isStale) {
      _memCache[q] = cached;
      return cached;
    }

    // ── API fetch (stale or miss) ─────────────────────────────────────────
    final fresh = await MedicineApiLayer.fetchAndEnrich(q);
    if (fresh == null) {
      if (cached != null) return cached; // return stale rather than nothing
      return null;
    }

    await _saveToFirestore(fresh);
    _memCache[_n(fresh.name)] = fresh;
    return fresh;
  }

  /// Call this from your search-by-name screen.
  static Future<MedicineModel?> searchByName(String name) =>
      getMedicine(name);

  /// Call this after OCR — extracts the best candidate token from raw text,
  /// tries multiple candidates if the first one returns nothing.
  static Future<MedicineModel?> searchFromOcr(String ocrText) async {
    final candidates = _extractOcrCandidates(ocrText);

    for (final candidate in candidates) {
      final result = await getMedicine(candidate);
      if (result != null) return result;
    }
    return null;
  }

  // =========================================================================
  //  OCR CANDIDATE EXTRACTION  (the fixed core)
  //
  //  Strategy:
  //   1. Split OCR text into lines.
  //   2. Score each line based on how likely it is to be a medicine name.
  //   3. Return up to 5 candidates in descending score order.
  //      The caller tries each one until a match is found.
  //
  //  Scoring heuristics (higher = better):
  //   +3  Line is ALL-CAPS or Title-Case (brand names usually are)
  //   +2  Line is 3–25 chars (medicine names are rarely longer)
  //   +2  Line matches a known medicine suffix (-il, -in, -ol, -am, -ex, etc.)
  //   +1  Line contains only letters (no digits/special chars)
  //   −3  Line contains a noise word (LOT, EXP, NDC, etc.)
  //   −2  Line is mostly digits (serial number, barcode)
  //   −1  Line is very long (>30 chars, likely a sentence)
  //   −1  Line starts with a digit
  // =========================================================================
  static List<String> _extractOcrCandidates(String ocr) {
    final lines = ocr
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

      // Positive signals
      if (token == token.toUpperCase() || _isTitleCase(token)) score += 3;
      if (token.length >= 3 && token.length <= 25) score += 2;
      if (_hasMedicineSuffix(lower)) score += 2;
      if (RegExp(r'^[a-zA-Z]+$').hasMatch(token)) score += 1;

      // Negative signals
      if (_noiseWords.contains(lower)) score -= 3;
      if (RegExp(r'^\d').hasMatch(token)) score -= 1;
      if (RegExp(r'\d{3,}').hasMatch(token)) score -= 2; // long number run
      if (line.length > 30) score -= 1;

      if (score >= 0) {
        scored.add(MapEntry(token, score));
      }
    }

    // Sort descending by score, deduplicate, return top 5
    scored.sort((a, b) => b.value.compareTo(a.value));
    final seen = <String>{};
    final result = <String>[];
    for (final e in scored) {
      final n = _n(e.key);
      if (seen.add(n)) result.add(n);
      if (result.length >= 5) break;
    }
    return result;
  }

  /// From a single line, extract the most useful token.
  /// Splits on whitespace/digits/punctuation, returns the longest
  /// alphabetic token (medicine names are rarely fragmented).
  static String _bestTokenFromLine(String line) {
    // Remove common label prefixes: "Brand:", "Drug:", etc.
    final clean = line
        .replaceAll(RegExp(r'^[A-Za-z]+:\s*'), '')
        .replaceAll(RegExp(r'[®™©]'), '')
        .trim();

    // Try the full line first (handles single-word brand names like "PANADOL")
    if (RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(clean) && clean.length <= 30) {
      return clean.trim();
    }

    // Otherwise extract the longest purely alphabetic token
    final tokens = RegExp(r'[a-zA-Z]{3,}').allMatches(clean);
    String best = '';
    for (final m in tokens) {
      if (m.group(0)!.length > best.length) best = m.group(0)!;
    }
    return best;
  }

  static bool _isTitleCase(String s) {
    final words = s.split(' ');
    return words.every((w) =>
        w.isEmpty || (w[0] == w[0].toUpperCase() && w.substring(1) == w.substring(1).toLowerCase()));
  }

  /// Common INN/brand name endings for pharmaceuticals.
  static bool _hasMedicineSuffix(String lower) {
    const suffixes = [
      'mab', 'nib', 'vir', 'olol', 'ipril', 'sartan', 'statin',
      'mycin', 'cyclin', 'oxacin', 'prazole', 'pam', 'lam', 'zepam',
      'azole', 'conazole', 'cillin', 'clovir', 'fenac', 'profen',
      'codone', 'morphine', 'pentin', 'vastatin', 'gliptin', 'gliflozin',
      'tide', 'zumab', 'kinase',
    ];
    return suffixes.any((s) => lower.endsWith(s));
  }

  // =========================================================================
  //  FIRESTORE CACHE LAYER
  // =========================================================================

  static Future<MedicineModel?> _fromFirestore(String normQuery) async {
    // 1. Exact name
    final byName = await _db
        .collection(_col)
        .where('name', isEqualTo: normQuery)
        .limit(1)
        .get();
    if (byName.docs.isNotEmpty) {
      return MedicineModel.fromFirestore(byName.docs.first.data());
    }

    // 2. Exact generic_name
    final byGeneric = await _db
        .collection(_col)
        .where('generic_name', isEqualTo: normQuery)
        .limit(1)
        .get();
    if (byGeneric.docs.isNotEmpty) {
      return MedicineModel.fromFirestore(byGeneric.docs.first.data());
    }

    // 3. Aliases array-contains
    final byAlias = await _db
        .collection(_col)
        .where('aliases', arrayContains: normQuery)
        .limit(1)
        .get();
    if (byAlias.docs.isNotEmpty) {
      return MedicineModel.fromFirestore(byAlias.docs.first.data());
    }

    return null;
  }

  static Future<void> _saveToFirestore(MedicineModel m) async {
    final docId = _n(m.name).replaceAll(' ', '_');
    await _db
        .collection(_col)
        .doc(docId)
        .set(m.toFirestore(), SetOptions(merge: true));
  }

  static String _n(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}