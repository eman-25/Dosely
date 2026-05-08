// ============================================================
//  medicine_lookup_service.dart
//  lib/services/medicine_lookup_service.dart
//
//  THE SINGLE ENTRY POINT for all medicine lookups.
//  Called by Scan.dart, Upload.dart, and Search.dart.
//
//  Pipeline for every lookup:
//  1. OCR text  → extract candidate names (scored ranking)
//  2. For each candidate:
//     a. Check Firestore `medicines` cache first (instant)
//     b. If not cached → DailyMed API (primary, clean data)
//     c. If not found  → OpenFDA API (fallback)
//     d. If not found  → RxNorm approximate search (last resort)
//  3. Save result to Firestore `medicines` (auto-grows the cache)
//  4. Run safety check against user's health profile
//  5. Save scan result to `users/{uid}/scan_results`
//  6. Return complete result map to the UI
// ============================================================

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class MedicineLookupService {
  static final _db = FirebaseFirestore.instance;
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // ── Noise words never found as medicine names ─────────────────────────────
  static const _noise = {
    'lot', 'exp', 'ndc', 'mfg', 'batch', 'ref', 'barcode', 'gtin',
    'manufactured', 'distributed', 'store', 'keep', 'use', 'see', 'read',
    'insert', 'leaflet', 'doctor', 'physician', 'pharmacist', 'tablet',
    'tablets', 'capsule', 'capsules', 'syrup', 'injection', 'each',
    'contains', 'excipient', 'ingredient', 'active', 'inactive', 'warning',
    'caution', 'rx', 'only', 'prescription', 'storage', 'date', 'dosage',
    'dose', 'adults', 'children', 'oral', 'route', 'film', 'coated',
    'modified', 'release', 'extended', 'delayed', 'enteric',
  };

  // ── Brand → Generic name map (Gulf + international brands) ────────────────
  static const _brandToGeneric = <String, String>{
    // Pain / Anti-inflammatory
    'panadol': 'acetaminophen', 'brufen': 'ibuprofen', 'advil': 'ibuprofen',
    'cataflam': 'diclofenac potassium', 'voltaren': 'diclofenac sodium',
    'ponstan': 'mefenamic acid', 'celebrex': 'celecoxib',
    'arcoxia': 'etoricoxib', 'tramal': 'tramadol', 'ultram': 'tramadol',
    // GI / IBD
    'asacol': 'mesalamine', 'mezavant': 'mesalamine',
    'pentasa': 'mesalamine', 'salofalk': 'mesalamine',
    'nexium': 'esomeprazole', 'losec': 'omeprazole', 'zantac': 'ranitidine',
    'imodium': 'loperamide', 'buscopan': 'hyoscine butylbromide',
    'gaviscon': 'alginate',
    // Antibiotics
    'augmentin': 'amoxicillin clavulanate', 'flagyl': 'metronidazole',
    'zithromax': 'azithromycin', 'cipro': 'ciprofloxacin',
    'ceporex': 'cephalexin', 'keflex': 'cephalexin',
    'klacid': 'clarithromycin', 'bactrim': 'trimethoprim sulfamethoxazole',
    // Cardiovascular
    'concor': 'bisoprolol', 'norvasc': 'amlodipine',
    'coversyl': 'perindopril', 'cozaar': 'losartan', 'lasix': 'furosemide',
    'plavix': 'clopidogrel', 'brilinta': 'ticagrelor',
    'inderal': 'propranolol', 'tenormin': 'atenolol',
    'zestril': 'lisinopril', 'tritace': 'ramipril', 'altace': 'ramipril',
    'micardis': 'telmisartan', 'diovan': 'valsartan',
    // Cholesterol
    'lipitor': 'atorvastatin', 'crestor': 'rosuvastatin',
    // Respiratory
    'ventolin': 'salbutamol', 'seretide': 'fluticasone salmeterol',
    'symbicort': 'budesonide formoterol', 'singulair': 'montelukast',
    'spiriva': 'tiotropium', 'nasonex': 'mometasone',
    // Antihistamines
    'zyrtec': 'cetirizine', 'claritin': 'loratadine',
    'aerius': 'desloratadine', 'telfast': 'fexofenadine',
    // Diabetes
    'glucophage': 'metformin', 'januvia': 'sitagliptin',
    'diamicron': 'gliclazide', 'amaryl': 'glimepiride',
    'lantus': 'insulin glargine', 'novorapid': 'insulin aspart',
    'humalog': 'insulin lispro', 'jardiance': 'empagliflozin',
    'forxiga': 'dapagliflozin', 'ozempic': 'semaglutide',
    'victoza': 'liraglutide',
    // Thyroid
    'eltroxin': 'levothyroxine', 'euthyrox': 'levothyroxine',
    // Mental health
    'xanax': 'alprazolam', 'cipralex': 'escitalopram', 'zoloft': 'sertraline',
    // Pregnancy / supplements
    'utrogestan': 'progesterone', 'cyclogest': 'progesterone',
    'ondansetron': 'ondansetron', 'tardyferon': 'ferrous sulfate',
    'folic acid': 'folic acid',
    // Topical
    'fucidin': 'fusidic acid', 'canesten': 'clotrimazole',
    'lamisil': 'terbinafine', 'betnovate': 'betamethasone',
    // Supplements
    'neurobion': 'vitamin b complex', 'centrum': 'multivitamin',
    'caltrate': 'calcium carbonate',
  };

  static const _timeout = Duration(seconds: 12);

  // =========================================================================
  //  PUBLIC ENTRY POINTS
  // =========================================================================

  /// Called by Scan.dart — takes raw OCR text, returns full result map.
  static Future<Map<String, dynamic>?> lookupFromOcr({
    required String uid,
    required String ocrText,
  }) async {
    final candidates = _extractCandidates(ocrText);
    if (candidates.isEmpty) return null;

    for (final candidate in candidates) {
      final medicine = await _fetchMedicine(candidate);
      if (medicine != null) {
        return _runSafetyCheck(uid: uid, medicine: medicine, ocrText: ocrText);
      }
    }
    return null;
  }

  /// Called by Upload.dart — processes image then does lookup.
  static Future<Map<String, dynamic>?> lookupFromImage({
    required String uid,
    required String imagePath,
    void Function(String)? onStatus,
  }) async {
    onStatus?.call('Reading text from image…');
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognised = await _recognizer.processImage(inputImage);
    final ocrText = recognised.text.trim();

    if (ocrText.isEmpty) return null;

    onStatus?.call('Identifying medicine…');
    final candidates = _extractCandidates(ocrText);
    if (candidates.isEmpty) return null;

    for (final candidate in candidates) {
      onStatus?.call('Looking up $candidate…');
      final medicine = await _fetchMedicine(candidate);
      if (medicine != null) {
        onStatus?.call('Checking against your health profile…');
        final result = await _runSafetyCheck(
            uid: uid, medicine: medicine, ocrText: ocrText);
        result['_ocrText'] = ocrText;
        return result;
      }
    }
    return null;
  }

  /// Called by Search.dart — takes a typed name, returns full result map.
  static Future<Map<String, dynamic>?> lookupByName({
    required String uid,
    required String name,
  }) async {
    if (name.trim().isEmpty) return null;
    final medicine = await _fetchMedicine(name.trim().toLowerCase());
    if (medicine == null) return null;
    return _runSafetyCheck(uid: uid, medicine: medicine, ocrText: name);
  }

  // =========================================================================
  //  STEP 1 — OCR CANDIDATE EXTRACTION
  //
  //  Scoring per line/token:
  //   +5  Exact match in brand map (we know this is a medicine)
  //   +4  ALL-CAPS word (brand names are printed in capitals on boxes)
  //   +3  TitleCase word
  //   +3  Known pharmaceutical INN suffix (-olol, -prazole, -mycin etc.)
  //   +2  Length 4–20 chars (medicine names are rarely outside this range)
  //   +1  Pure alphabetic (no digits or special chars)
  //   −5  Known noise word (LOT, EXP, NDC, TABLET, CAPSULE etc.)
  //   −3  Contains a long digit run (serial/barcode number)
  //   −2  Starts with a digit
  //   −1  Line longer than 35 chars (likely a sentence, not a name)
  // =========================================================================
  static List<String> _extractCandidates(String ocrText) {
    final lines = ocrText
        .split(RegExp(r'[\n\r]+'))
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();

    final scored = <MapEntry<String, int>>[];

    for (final line in lines) {
      final token = _bestToken(line);
      if (token.length < 3) continue;
      final lower = token.toLowerCase();
      final normLower = _norm(lower);

      int score = 0;

      // Brand map hit is the strongest possible signal
      if (_brandToGeneric.containsKey(normLower)) {
        score += 5;
      } else {
        // Try prefix match (e.g. "panadol extra" starts with "panadol")
        for (final brand in _brandToGeneric.keys) {
          if (normLower.startsWith(brand)) {
            score += 4;
            break;
          }
        }
      }

      if (token == token.toUpperCase() && token.length > 2) score += 4;
      if (_isTitleCase(token) && token != token.toUpperCase()) score += 3;
      if (_hasMedicineSuffix(lower)) score += 3;
      if (token.length >= 4 && token.length <= 20) score += 2;
      if (RegExp(r'^[a-zA-Z]+$').hasMatch(token)) score += 1;

      if (_noise.contains(lower)) score -= 5;
      if (RegExp(r'^\d').hasMatch(token)) score -= 2;
      if (RegExp(r'\d{3,}').hasMatch(token)) score -= 3;
      if (line.length > 35) score -= 1;

      if (score > 0) scored.add(MapEntry(token, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final seen = <String>{};
    final result = <String>[];
    for (final e in scored) {
      final n = _norm(e.key);
      if (n.length >= 3 && seen.add(n)) result.add(n);
      if (result.length >= 8) break; // try up to 8 candidates
    }
    return result;
  }

  static String _bestToken(String line) {
    final clean = line
        .replaceAll(RegExp(r'^[A-Za-z]+:\s*'), '')
        .replaceAll(RegExp(r'[®™©]'), '')
        .trim();
    if (RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(clean) && clean.length <= 30) {
      return clean.trim();
    }
    final tokens = RegExp(r'[a-zA-Z]{3,}').allMatches(clean);
    String best = '';
    for (final m in tokens) {
      if (m.group(0)!.length > best.length) best = m.group(0)!;
    }
    return best;
  }

  // =========================================================================
  //  STEP 2 — FETCH MEDICINE DATA
  //  Order: Firestore cache → DailyMed → OpenFDA → RxNorm approximate
  // =========================================================================
  static Future<Map<String, dynamic>?> _fetchMedicine(String query) async {
    final q = _norm(query);

    // a. Firestore cache
    final cached = await _fromFirestore(q);
    if (cached != null) {
      // Preserve queried dosage if user specified one (e.g. "concor 5mg")
      final queriedDosage = _extractDosageFromQuery(query);
      if (queriedDosage != null) cached['dosage'] = queriedDosage;
      return cached;
    }

    // Resolve brand name to generic for better API results
    final generic = _resolveGeneric(q);
    final searchQuery = generic ?? q;

    // b. DailyMed (primary — clean structured data)
    final dailyMed = await _fetchDailyMed(searchQuery);
    if (dailyMed != null) {
      if (generic != null) {
        final brandBase = q.replaceAll(
            RegExp(r'\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '').trim();
        dailyMed['name'] = _toTitleCase(brandBase);
      }
      // Preserve the dosage the user actually searched/scanned
      final queriedDosage = _extractDosageFromQuery(query);
      if (queriedDosage != null) dailyMed['dosage'] = queriedDosage;
      await _saveToFirestore(dailyMed);
      return dailyMed;
    }

    // c. OpenFDA (fallback)
    final fda = await _fetchOpenFDA(searchQuery, q);
    if (fda != null) {
      final queriedDosage = _extractDosageFromQuery(query);
      if (queriedDosage != null) fda['dosage'] = queriedDosage;
      await _saveToFirestore(fda);
      return fda;
    }

    // d. RxNorm approximate (last resort)
    final rxn = await _fetchRxNormApprox(searchQuery);
    if (rxn != null) {
      final queriedDosage = _extractDosageFromQuery(query);
      if (queriedDosage != null) rxn['dosage'] = queriedDosage;
      await _saveToFirestore(rxn);
      return rxn;
    }

    return null;
  }

  /// Extracts dosage from a search query like "concor 5mg" → "5 mg"
  static String? _extractDosageFromQuery(String query) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu|%)',
      caseSensitive: false,
    ).firstMatch(query);
    if (match != null) {
      return '${match.group(1)} ${match.group(2)!.toLowerCase()}';
    }
    return null;
  }

  // ── Firestore cache ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _fromFirestore(String query) async {
    final variants = {
      query,                         // normalized lowercase
      _toTitleCase(query),           // Title Case
      query.toUpperCase(),           // UPPERCASE
    };

    for (final field in ['name', 'generic_name']) {
      for (final variant in variants) {
        final snap = await _db
            .collection('medicines')
            .where(field, isEqualTo: variant)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return snap.docs.first.data();
      }
    }

    // Alias array-contains (always normalized lowercase)
    final aliasSnap = await _db
        .collection('medicines')
        .where('aliases', arrayContains: query)
        .limit(1)
        .get();
    if (aliasSnap.docs.isNotEmpty) return aliasSnap.docs.first.data();
    return null;
  }

  static Future<void> _saveToFirestore(Map<String, dynamic> med) async {
    final name = _norm(med['name'] ?? '');
    final generic = _norm(med['generic_name'] ?? '');
    final docId = name.replaceAll(' ', '_');
    if (docId.isEmpty) return;

    // Enrich aliases to maximise future cache hits
    final aliases = <String>{
      ...List<String>.from(med['aliases'] ?? []),
      if (name.isNotEmpty) name,
      if (generic.isNotEmpty) generic,
    };

    // Add brand name if we know the generic (reverse lookup)
    for (final entry in _brandToGeneric.entries) {
      if (entry.value == generic) aliases.add(entry.key);
    }

    med['aliases'] = aliases.where((a) => a.length >= 3).toList();

    await _db
        .collection('medicines')
        .doc(docId)
        .set(med, SetOptions(merge: true));
  }

  // ── DailyMed API ──────────────────────────────────────────────────────────
  // Two-step:
  //   1. Search by drug_name → get setId + title
  //   2. Validate title matches our query (prevents false matches like silicea)
  //   3. Fetch full SPL detail for clean structured fields
  static Future<Map<String, dynamic>?> _fetchDailyMed(String query) async {
    try {
      // Step 1: Search — fetch top 3 results and pick the best match
      final searchUrl =
          'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls.json'
          '?drug_name=${Uri.encodeComponent(query)}&pagesize=3';
      final searchRes =
          await http.get(Uri.parse(searchUrl)).timeout(_timeout);
      if (searchRes.statusCode != 200) return null;

      final searchBody = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final dataList = searchBody['data'] as List?;
      if (dataList == null || dataList.isEmpty) return null;

      // Step 2: Pick the result whose title best matches our query
      // This prevents e.g. searching "mesalamine" and getting a silicea homeopathic hit
      Map<String, dynamic>? bestMatch;
      String bestSetId = '';
      double bestScore = 0;

      for (final item in dataList) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final setId = item['setid']?.toString() ?? '';
        if (setId.isEmpty) continue;

        final score = _titleMatchScore(title, query);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = item as Map<String, dynamic>;
          bestSetId = setId;
        }
      }

      // Require at least a weak match — reject completely unrelated results
      if (bestMatch == null || bestScore < 0.15) return null;

      // Step 3: Fetch full SPL label for structured fields
      final detailUrl =
          'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls/$bestSetId.json';
      final detailRes =
          await http.get(Uri.parse(detailUrl)).timeout(_timeout);
      if (detailRes.statusCode != 200) return null;

      final detail = jsonDecode(detailRes.body) as Map<String, dynamic>;
      final splData = detail['data'] as Map<String, dynamic>?;
      if (splData == null) return null;

      // Step 4: Extract clean fields from structured sections
      final sections = splData['sections'] as List? ?? [];
      String description = '';
      String dosage = '';
      String pregnancyWarning = 'none';
      String allergyTrigger = query;
      final avoidCombinations = <String>[];

      for (final section in sections) {
        final title = (section['title'] ?? '').toString().toLowerCase();
        final text = _cleanText((section['text'] ?? '').toString());

        if (description.isEmpty &&
            (title.contains('description') ||
                title.contains('indications') ||
                title.contains('clinical pharmacology') ||
                title.contains('purpose'))) {
          description = text;
        }
        if (dosage.isEmpty &&
            (title.contains('dosage and administration') ||
                title.contains('dosage form') ||
                title.contains('dose'))) {
          dosage = text.length > 150 ? '${text.substring(0, 150)}...' : text;
        }
        if (title.contains('pregnan') || title.contains('reproduct') ||
            title.contains('lactation')) {
          pregnancyWarning = _classifyPregnancy(text);
        }
        if (title.contains('contraindic') || title.contains('hypersensitiv')) {
          allergyTrigger = _extractAllergyTrigger(text, query);
        }
        if (title.contains('drug interaction')) {
          avoidCombinations.addAll(_extractInteractionNames(text));
        }
      }

      final productTitle = bestMatch['title']?.toString() ?? query;
      final cleanName = _cleanProductName(productTitle);

      return {
        'name': cleanName.isNotEmpty ? cleanName : _toTitleCase(query),
        'generic_name': query,
        'dosage': dosage.isNotEmpty ? dosage : 'See product label',
        'description': description.isNotEmpty
            ? description
            : 'Prescription medicine. Consult your pharmacist for full details.',
        'aliases': [_norm(query), _norm(cleanName)],
        'avoid_combinations': avoidCombinations.toSet().take(10).toList(),
        'allergy_trigger': allergyTrigger,
        'pregnancy_warning': pregnancyWarning,
        '_source': 'DailyMed',
        '_setid': bestSetId,
        '_cached_at': DateTime.now().toIso8601String(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Scores how well a DailyMed result title matches the search query.
  /// Returns 0.0–1.0. Used to reject false matches.
  static double _titleMatchScore(String title, String query) {
    final t = title.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final q = query.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Exact contains is strong signal
    if (t.contains(q)) return 1.0;
    if (q.contains(t)) return 0.9;

    // Token overlap
    final tTokens = t.split(' ').where((s) => s.length >= 3).toSet();
    final qTokens = q.split(' ').where((s) => s.length >= 3).toSet();
    if (qTokens.isEmpty) return 0;

    final matched = qTokens.where(tTokens.contains).length;
    return matched / qTokens.length;
  }

  // ── OpenFDA API ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _fetchOpenFDA(
      String query, String originalQuery) async {
    final endpoints = [
      'https://api.fda.gov/drug/label.json'
          '?search=openfda.generic_name:"${Uri.encodeComponent(query)}"&limit=1',
      'https://api.fda.gov/drug/label.json'
          '?search=openfda.brand_name:"${Uri.encodeComponent(query)}"&limit=1',
      'https://api.fda.gov/drug/label.json'
          '?search=openfda.substance_name:"${Uri.encodeComponent(query)}"&limit=1',
    ];

    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(_timeout);
        if (res.statusCode != 200) continue;
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = body['results'] as List?;
        if (results == null || results.isEmpty) continue;

        final fda = results.first as Map<String, dynamic>;

        // Verify the result actually matches — prevents silicea-type false matches
        if (!_fdaResultMatchesQuery(fda, query)) continue;

        return _parseFDA(fda, originalQuery);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static bool _fdaResultMatchesQuery(Map<String, dynamic> fda, String query) {
    final q = query.replaceAll(RegExp(r'\s+'), '');
    final openfda = (fda['openfda'] as Map<String, dynamic>?) ?? {};
    final names = [
      ..._asList(openfda['brand_name']),
      ..._asList(openfda['generic_name']),
      ..._asList(openfda['substance_name']),
    ];
    for (final name in names) {
      final n = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (n.contains(q) || q.contains(n)) return true;
    }
    return false;
  }

  static Map<String, dynamic> _parseFDA(
      Map<String, dynamic> fda, String originalQuery) {
    final openfda = (fda['openfda'] as Map<String, dynamic>?) ?? {};
    final brandNames = _asList(openfda['brand_name']);
    final genericNames = _asList(openfda['generic_name']);

    final name = brandNames.isNotEmpty
        ? _toTitleCase(brandNames.first)
        : _toTitleCase(originalQuery);
    final genericName =
        genericNames.isNotEmpty ? genericNames.first.toLowerCase() : originalQuery;

    final rawDesc = _firstText([fda['description'], fda['indications_and_usage']]);
    final rawDosage = _firstText([fda['dosage_forms_and_strengths']]);
    final rawWarnings = _firstText([fda['warnings'], fda['contraindications']]);
    final rawInteractions = _firstText([fda['drug_interactions']]);
    final rawPregnancy = _firstText([fda['pregnancy']]);

    return {
      'name': name,
      'generic_name': genericName,
      'dosage': _cleanText(rawDosage, maxLength: 120),
      'description': _cleanText(rawDesc, maxLength: 400),
      'aliases': [_norm(originalQuery), _norm(name), _norm(genericName)],
      'avoid_combinations': _extractInteractionNames(rawInteractions).take(10).toList(),
      'allergy_trigger': _extractAllergyTrigger(rawWarnings, genericName),
      'pregnancy_warning': _classifyPregnancy(rawPregnancy),
      '_source': 'OpenFDA',
      '_cached_at': DateTime.now().toIso8601String(),
    };
  }

  // ── RxNorm approximate ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _fetchRxNormApprox(String query) async {
    try {
      final url =
          'https://rxnav.nlm.nih.gov/REST/approximateTerm.json'
          '?term=${Uri.encodeComponent(query)}&maxEntries=1';
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates =
          body['approximateGroup']?['candidate'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final score =
          int.tryParse(candidates.first['score']?.toString() ?? '0') ?? 0;
      if (score < 70) return null;

      final rxcui = candidates.first['rxcui']?.toString();
      if (rxcui == null) return null;

      // Get display name
      final nameUrl =
          'https://rxnav.nlm.nih.gov/REST/rxcui/$rxcui/property.json'
          '?propName=RxNorm%20Name';
      final nameRes = await http.get(Uri.parse(nameUrl)).timeout(_timeout);
      String resolvedName = query;
      if (nameRes.statusCode == 200) {
        final nd = jsonDecode(nameRes.body) as Map<String, dynamic>;
        final val = nd['propConceptGroup']?['propConcept']?[0]?['propValue'];
        if (val != null) resolvedName = val.toString().toLowerCase();
      }

      return {
        'name': _toTitleCase(query),
        'generic_name': resolvedName,
        'dosage': 'See product label',
        'description':
            'Drug information sourced from RxNorm (NLM). Consult your pharmacist for full details.',
        'aliases': [_norm(query), resolvedName],
        'avoid_combinations': [],
        'allergy_trigger': resolvedName,
        'pregnancy_warning': 'caution',
        '_source': 'RxNorm',
        '_rxcui': rxcui,
        '_cached_at': DateTime.now().toIso8601String(),
      };
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  //  STEP 3 — SAFETY CHECK
  // =========================================================================
  static Future<Map<String, dynamic>> _runSafetyCheck({
    required String uid,
    required Map<String, dynamic> medicine,
    required String ocrText,
  }) async {
    // Load user health profile
    final userDoc = await _db.collection('users').doc(uid).get();
    final raw = userDoc.exists ? (userDoc.data() ?? {}) : {};
    final health = Map<String, dynamic>.from(raw['healthInfo'] ?? {});
    final gender = _norm(raw['gender']?.toString() ?? '');

    final allergies = _toList(health['allergies']);
    final chronicConditions = _toList(health['chronicConditions']);
    final currentMeds = _toList(health['currentMedications']);
    final specialConditions = _toList(health['specialConditions']);

    // Load scheduled medicines
    final tableSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('medicine_table')
        .get();
    final scheduled = <String>[];
    for (final doc in tableSnap.docs) {
      final d = doc.data();
      if (d['medicineName'] != null) scheduled.add(_norm(d['medicineName'].toString()));
      if (d['genericName'] != null) scheduled.add(_norm(d['genericName'].toString()));
    }

    final medName = _norm(medicine['name'] ?? '');
    final genName = _norm(medicine['generic_name'] ?? '');
    final allergyTrigger = _norm(
        medicine['allergy_trigger'] ?? medicine['allergy_ingredient'] ?? '');
    final pregnancyWarn =
        (medicine['pregnancy_warning'] ?? 'none').toString().toLowerCase();
    final avoidList = _toList(medicine['avoid_combinations'])
        .map(_norm)
        .toList();
    final descNorm = _norm(medicine['description'] ?? '');

    String status = 'safe';
    final reasons = <String>[];

    // Rule 1: Allergy conflict
    if (allergyTrigger.isNotEmpty && allergyTrigger != 'none') {
      if (_anyEquiv(allergies, allergyTrigger)) {
        status = 'not safe';
        reasons.add('Allergy conflict: ${medicine['allergy_trigger'] ?? allergyTrigger}');
      }
    }

    // Rule 2: NSAID class allergy
    final isNsaid = _isNsaid(allergyTrigger) || _isNsaid(genName);
    final userAllergyNsaid = allergies.any((a) =>
        _norm(a).contains('nsaid') ||
        _norm(a).contains('aspirin') ||
        _norm(a).contains('ibuprofen'));
    if (isNsaid && userAllergyNsaid && status != 'not safe') {
      status = 'not safe';
      reasons.add('You are allergic to NSAIDs — this medicine belongs to that class');
    }

    // Rule 3: Interactions with current medications
    for (final med in currentMeds) {
      final base = _stripDosage(_norm(med));
      if (base.length >= 4 && _anyEquiv(avoidList, base)) {
        status = 'not safe';
        reasons.add('Interacts with your current medication: ${_titleCase(med)}');
      }
    }

    // Rule 4: Interactions with scheduled medicines
    for (final med in scheduled) {
      final base = _stripDosage(med);
      if (base.length >= 4 && _anyEquiv(avoidList, base)) {
        status = 'not safe';
        reasons.add('Interacts with a scheduled medicine: ${_titleCase(med)}');
      }
    }

    // Rule 5: Duplicate check — requires strong name match, not fuzzy
    // Only flags if the medicine name or generic name is a close match
    // to what's already in the user's list. Uses strict equality to
    // prevent "paracetamol" matching "naproxen" via token overlap.
    final medBase = _stripDosage(medName);
    final genBase = _stripDosage(genName);
    if (medBase.length >= 4 || genBase.length >= 4) {
      bool isDuplicate = false;
      for (final existing in [...currentMeds, ...scheduled]) {
        final existingBase = _stripDosage(_norm(existing));
        if (existingBase.length < 4) continue;
        // Strict: exact match or one fully contains the other (min 6 chars)
        if (existingBase == medBase || existingBase == genBase) {
          isDuplicate = true;
          break;
        }
        if (medBase.length >= 6 && existingBase.contains(medBase)) {
          isDuplicate = true;
          break;
        }
        if (genBase.length >= 6 && existingBase.contains(genBase)) {
          isDuplicate = true;
          break;
        }
        // Also check reverse: existing name inside scanned name
        if (existingBase.length >= 6 &&
            (medBase.contains(existingBase) || genBase.contains(existingBase))) {
          isDuplicate = true;
          break;
        }
      }
      if (isDuplicate && status != 'not safe') {
        status = 'caution';
        reasons.add('This medicine may already be in your medication list');
      }
    }

    // Rule 6: Pregnancy / Breastfeeding
    // For pregnant or breastfeeding females → personal danger warning,
    // affects safety status.
    // For all other users (male, or female not pregnant) → neutral
    // informational note only, does NOT affect status.
    final isFemale = gender != 'male' && gender != 'm';
    final isPregnant = isFemale &&
        specialConditions.any((s) =>
            _norm(s).contains('pregnant') ||
            _norm(s).contains('pregnancy') ||
            _norm(s).contains('trying to conceive'));
    final isBreastfeeding = isFemale &&
        specialConditions.any((s) =>
            _norm(s).contains('breastfeed') ||
            _norm(s).contains('lactat'));

    if (isPregnant) {
      // Personal risk — affects status
      if (pregnancyWarn == 'avoid') {
        status = 'not safe';
        reasons.add('⚠️ Not safe during pregnancy — do not take without consulting your doctor');
      } else if (pregnancyWarn == 'caution' && status != 'not safe') {
        status = 'caution';
        reasons.add('Use with caution during pregnancy — consult your doctor first');
      }
    } else if (isBreastfeeding) {
      if (pregnancyWarn == 'avoid' && status != 'not safe') {
        status = 'caution';
        reasons.add('Not recommended while breastfeeding — consult your doctor');
      } else if (pregnancyWarn == 'caution' && status != 'not safe') {
        status = 'caution';
        reasons.add('Use with caution while breastfeeding — consult your doctor');
      }
    } else if (pregnancyWarn == 'avoid') {
      // Neutral info for all other users (male, or female not pregnant)
      // Does NOT change status — shown as general drug information only
      reasons.add('General info: not recommended for use during pregnancy');
    } else if (pregnancyWarn == 'caution') {
      reasons.add('General info: use with caution in pregnancy');
    }

    // Rule 7: Chronic conditions (curated keyword map)
    // Fires on both 'safe' and 'caution' to add condition-specific warnings
    for (final condition in chronicConditions) {
      final keywords = _conditionKeywords(_norm(condition));
      bool matched = false;
      for (final kw in keywords) {
        if (kw.length >= 5 && descNorm.contains(kw) && status != 'not safe') {
          if (status == 'safe') status = 'caution';
          if (!matched) {
            reasons.add(
                'Check carefully: this medicine may relate to your condition — $condition');
            matched = true;
          }
          break;
        }
      }
    }

    // Rule 8: High-risk conditions
    if (specialConditions.any((s) {
      final v = _norm(s);
      return v.contains('immunocompromis') ||
          v.contains('dialysis') ||
          v.contains('transplant') ||
          v.contains('chemotherapy');
    }) && status == 'safe') {
      status = 'caution';
      reasons.add('You have a high-risk condition — confirm with your doctor');
    }

    if (reasons.isEmpty) reasons.add('No issues found based on your health profile');

    // Save scan result
    await _db.collection('users').doc(uid).collection('scan_results').add({
      'ocrText': ocrText,
      'medicineName': medicine['name'],
      'genericName': medicine['generic_name'],
      'dosage': medicine['dosage'],
      'status': status,
      'reasons': reasons,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      ...medicine,
      'status': status,
      'reasons': reasons,
    };
  }

  // =========================================================================
  //  HELPERS
  // =========================================================================

  static String? _resolveGeneric(String query) {
    final base = query
        .replaceAll(
            RegExp(r'\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '')
        .trim();
    if (_brandToGeneric.containsKey(base)) return _brandToGeneric[base];
    for (final entry in _brandToGeneric.entries) {
      if (base.startsWith(entry.key)) return entry.value;
    }
    return null;
  }

  static String _cleanText(String text, {int maxLength = 400}) {
    if (text.isEmpty) return '';
    String s = text
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(
            RegExp(
                r'\b(DOSAGE|USES|INDICATIONS|DESCRIPTION|PURPOSE|DIRECTIONS|SECTION)\b\s*:?\s*',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final sentences = s.split(RegExp(r'(?<=[.!?])\s+'));
    s = sentences.take(3).join(' ').trim();
    return s.length > maxLength ? '${s.substring(0, maxLength)}...' : s;
  }

  static String _cleanProductName(String raw) {
    return raw
        .replaceAll(RegExp(r'\b\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _classifyPregnancy(String text) {
    final t = text.toLowerCase();
    if (t.contains('contraindicated') ||
        t.contains('category x') ||
        t.contains('do not use') ||
        t.contains('teratogenic')) return 'avoid';
    if (t.contains('category d') ||
        t.contains('category c') ||
        t.contains('caution') ||
        t.contains('risk') ||
        t.contains('not recommended')) return 'caution';
    return 'none';
  }

  static String _extractAllergyTrigger(String text, String fallback) {
    for (final pattern in [
      RegExp(r'hypersensitivity\s+to\s+([\w\s\-]+?)(?:[\.,;]|$)',
          caseSensitive: false),
      RegExp(r'allergic(?:\s+reaction)?\s+to\s+([\w\s\-]+?)(?:[\.,;]|$)',
          caseSensitive: false),
    ]) {
      final m = pattern.firstMatch(text.toLowerCase());
      if (m != null) return m.group(1)!.trim();
    }
    return fallback.isNotEmpty ? fallback : 'none';
  }

  static List<String> _extractInteractionNames(String text) {
    if (text.isEmpty) return [];
    const stops = {
      'This', 'The', 'Use', 'See', 'Tell', 'Take', 'Avoid', 'Do', 'If',
      'When', 'May', 'Not', 'Patients', 'Drug', 'Drugs', 'With', 'For',
      'And', 'Or', 'Should', 'Must', 'Are', 'Been',
    };
    final matches =
        RegExp(r'\b([A-Z][a-z]{3,}(?:\s[A-Z][a-z]{2,})?)\b').allMatches(text);
    final names = <String>{};
    for (final m in matches) {
      if (!stops.contains(m.group(1)!)) names.add(m.group(1)!.toLowerCase());
    }
    return names.take(10).toList();
  }

  static List<String> _conditionKeywords(String condition) {
    const map = <String, List<String>>{
      // Cardiovascular — expanded to catch drug descriptions
      'heart failure':    ['heart failure', 'cardiac failure', 'edema', 'oedema',
                           'fluid retention', 'congestive'],
      'heart disease':    ['cardiac', 'coronary', 'angina', 'myocardial',
                           'heart disease', 'cardiovascular'],
      'coronary':         ['coronary', 'cardiac', 'angina', 'myocardial'],
      'hypertension':     ['hypertension', 'blood pressure', 'antihypertensive'],
      'atrial':           ['atrial fibrillation', 'arrhythmia', 'antiarrhythmic'],
      'cholesterol':      ['cholesterol', 'hyperlipidemia', 'statin'],
      'deep vein':        ['thrombosis', 'anticoagulant', 'thrombo'],
      // Metabolic
      'diabetes':         ['diabetes', 'diabetic', 'hyperglycemia', 'insulin',
                           'glycemic'],
      'thyroid':          ['thyroid', 'hypothyroid', 'hyperthyroid'],
      'gout':             ['gout', 'uric acid', 'xanthine'],
      'obesity':          ['obesity', 'weight loss'],
      // Respiratory
      'asthma':           ['asthma', 'bronchospasm', 'bronchial'],
      'copd':             ['copd', 'chronic obstructive', 'emphysema'],
      'sleep apnea':      ['sleep apnea', 'apnoea'],
      // GI
      'peptic ulcer':     ['peptic ulcer', 'gastric ulcer', 'gastric acid'],
      'crohn':            ['crohn', 'inflammatory bowel'],
      'colitis':          ['colitis', 'ulcerative'],
      'reflux':           ['reflux', 'gerd', 'esophageal'],
      // Kidney / Liver
      'kidney':           ['renal', 'nephro', 'kidney'],
      'liver':            ['hepatic', 'cirrhosis', 'liver'],
      // Neurological
      'epilepsy':         ['epilepsy', 'seizure', 'anticonvulsant'],
      'migraine':         ['migraine'],
      'parkinson':        ['parkinson', 'dopamine'],
      'multiple sclerosis': ['multiple sclerosis', 'demyelinating'],
      // Mental health
      'depression':       ['depression', 'antidepressant', 'ssri'],
      'anxiety':          ['anxiety', 'anxiolytic'],
      'bipolar':          ['bipolar', 'mood stabilizer'],
      'schizophrenia':    ['schizophrenia', 'antipsychotic'],
      // Musculoskeletal
      'osteoporosis':     ['osteoporosis', 'bone density'],
      'arthritis':        ['arthritis', 'rheumatoid', 'anti-inflammatory'],
      'lupus':            ['lupus', 'sle', 'autoimmune'],
      // Blood
      'anemia':           ['anemia', 'anaemia', 'iron deficiency'],
      'hemophilia':       ['hemophilia', 'coagulation', 'clotting'],
      'hiv':              ['hiv', 'antiretroviral'],
      // Eye
      'glaucoma':         ['glaucoma', 'intraocular'],
    };

    final c = condition.toLowerCase();
    for (final entry in map.entries) {
      if (c.contains(entry.key)) return entry.value;
    }

    // Fallback: extract meaningful words only
    const stops = {
      'disease', 'disorder', 'syndrome', 'condition', 'history',
      'chronic', 'deficiency', 'failure', 'related', 'coronary',
      'artery', 'pressure', 'high', 'low',
    };
    return condition
        .split(' ')
        .where((w) => w.length >= 6 && !stops.contains(w))
        .take(2)
        .toList();
  }

  static bool _isNsaid(String s) =>
      s.contains('nsaid') ||
      s.contains('ibuprofen') ||
      s.contains('aspirin') ||
      s.contains('diclofenac') ||
      s.contains('naproxen') ||
      s.contains('celecoxib') ||
      s.contains('brufen') ||
      s.contains('cataflam') ||
      s.contains('voltaren');

  static bool _anyEquiv(List<String> list, String value) {
    if (value.length < 3) return false;
    for (final item in list) {
      if (_equiv(_norm(item), _norm(value))) return true;
    }
    return false;
  }

  static bool _equiv(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.length >= 5 && b.length >= 5) {
      if (a.contains(b) || b.contains(a)) return true;
    }
    return _tokenOverlap(a, b) >= 0.80;
  }

  static double _tokenOverlap(String a, String b) {
    final aT = a.split(' ').where((t) => t.length >= 4).toSet();
    final bT = b.split(' ').where((t) => t.length >= 4).toSet();
    if (aT.isEmpty || bT.isEmpty) return 0;
    return aT.where(bT.contains).length / aT.length;
  }

  static String _stripDosage(String name) => name
      .replaceAll(
          RegExp(r'\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    List<String> raw;
    if (v is List) {
      raw = v.map((e) => e.toString().trim()).toList();
    } else {
      raw = v.toString().split(',').map((e) => e.trim()).toList();
    }
    final result = <String>[];
    for (final item in raw) {
      if (item.isEmpty || item.toLowerCase() == 'none') continue;
      // Strip parenthetical brand/generic alternatives e.g. "Naproxen (Aleve)"
      // Keep both the main name AND the parenthetical as separate entries
      final parenMatch = RegExp(r'^(.+?)\s*\((.+?)\)').firstMatch(item);
      if (parenMatch != null) {
        final main = parenMatch.group(1)!.trim();
        final paren = parenMatch.group(2)!.trim();
        if (main.isNotEmpty) result.add(main);
        if (paren.isNotEmpty && paren.toLowerCase() != 'none') result.add(paren);
      } else {
        result.add(item);
      }
    }
    return result;
  }

  static List<String> _asList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [v.toString()];
  }

  static String _firstText(List<dynamic?> fields) {
    for (final f in fields) {
      if (f == null) continue;
      if (f is List && f.isNotEmpty) return f.first.toString().trim();
      if (f is String && f.isNotEmpty) return f.trim();
    }
    return '';
  }

  static bool _isTitleCase(String s) {
    final words = s.split(' ');
    return words.isNotEmpty &&
        words.every((w) =>
            w.isEmpty ||
            (w[0] == w[0].toUpperCase() &&
                (w.length == 1 ||
                    w.substring(1) == w.substring(1).toLowerCase())));
  }

  static bool _hasMedicineSuffix(String lower) {
    const suffixes = [
      'mab', 'nib', 'vir', 'olol', 'ipril', 'sartan', 'statin', 'mycin',
      'cyclin', 'oxacin', 'prazole', 'pam', 'lam', 'azole', 'cillin',
      'fenac', 'profen', 'vastatin', 'gliptin', 'gliflozin', 'triptan',
    ];
    return suffixes.any((s) => lower.endsWith(s));
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static String _titleCase(String s) => _toTitleCase(s);
}