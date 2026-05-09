// ============================================================
//  medicine_api_layer.dart
//
//  Three authoritative, completely FREE government/NIH APIs:
//
//  1. OpenFDA  — drug labels, brand names, dosages, warnings
//     https://open.fda.gov/apis/drug/label/
//
//  2. RxNorm (NLM) — resolves a drug name → RxCUI (stable concept ID)
//     https://rxnav.nlm.nih.gov/REST/rxcui.json?name=ibuprofen
//
//  3. RxNorm Interaction API (NLM) — authoritative drug-drug interactions
//     https://rxnav.nlm.nih.gov/REST/interaction/interaction.json?rxcui=5640
//
//  4. DailyMed (NIH/NLM) — structured pregnancy / lactation warnings
//     https://dailymed.nlm.nih.gov/dailymed/app-support-web-services.cfm
//
//  FIX: Added RxNorm approximate search as fallback for brands not in OpenFDA
//  (Gulf/Middle-Eastern brands like Panadol, Brufen, Cataflam, Concor, etc.)
//  FIX: Added a Gulf brand → generic name mapping table so we always resolve
//  to a searchable generic before hitting any API.
//  FIX: Multiple OpenFDA search strategies tried in sequence.
// ============================================================
import 'package:dosely/models/medicine_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MedicineApiLayer {
  static const _short = Duration(seconds: 6);
  static const _long  = Duration(seconds: 12);

  // ✅ NEW: Filter out descriptive product names
  static const _descriptiveWords = {
    'pain', 'reliever', 'relief', 'strength', 'extra', 'strong', 
    'maximum', 'regular', 'gentle', 'fast', 'acting', 'action',
    'caplet', 'tablet', 'capsule', 'syrup', 'liquid', 'formula',
  };

  // =========================================================================
  //  GULF / MIDDLE-EAST BRAND → GENERIC NAME MAP
  //  Add any brand sold in Bahrain / GCC that OpenFDA won't recognise.
  //  Keys are lower-cased brand prefixes (dosage stripped before lookup).
  // =========================================================================
  static const Map<String, String> _brandToGeneric = {
    // Pain / Anti-inflammatory
    'panadol':       'acetaminophen',
    'brufen':        'ibuprofen',
    'advil':         'ibuprofen',
    'cataflam':      'diclofenac potassium',
    'voltaren':      'diclofenac sodium',
    'ponstan':       'mefenamic acid',
    // Antibiotics
    'augmentin':     'amoxicillin clavulanate',
    'flagyl':        'metronidazole',
    'zithromax':     'azithromycin',
    'cipro':         'ciprofloxacin',
    'ceporex':       'cephalexin',
    // Cardiovascular
    'concor':        'bisoprolol',
    'norvasc':       'amlodipine',
    'coversyl':      'perindopril',
    'cozaar':        'losartan',
    'lasix':         'furosemide',
    'plavix':        'clopidogrel',
    'brilinta':      'ticagrelor',
    // Cholesterol
    'lipitor':       'atorvastatin',
    'crestor':       'rosuvastatin',
    // GI
    'nexium':        'esomeprazole',
    'losec':         'omeprazole',
    'imodium':       'loperamide',
    'buscopan':      'hyoscine butylbromide',
    // Respiratory
    'ventolin':      'salbutamol',
    'seretide':      'fluticasone salmeterol',
    'symbicort':     'budesonide formoterol',
    'singulair':     'montelukast',
    // Antihistamines
    'zyrtec':        'cetirizine',
    'claritin':      'loratadine',
    'aerius':        'desloratadine',
    'telfast':       'fexofenadine',
    // Diabetes
    'glucophage':    'metformin',
    'januvia':       'sitagliptin',
    'diamicron':     'gliclazide',
    'amaryl':        'glimepiride',
    // Thyroid
    'eltroxin':      'levothyroxine',
    'euthyrox':      'levothyroxine',
    'carbimazole':   'carbimazole',
    // Mental health
    'xanax':         'alprazolam',
    'cipralex':      'escitalopram',
    'zoloft':        'sertraline',
    // Steroids
    'prednisolone':  'prednisolone',
    'nasonex':       'mometasone',
    // Pregnancy / supplements
    'utrogestan':    'progesterone',
    'cyclogest':     'progesterone',
    'ondansetron':   'ondansetron',
    'tardyferon':    'ferrous sulfate',
    'folic acid':    'folic acid',
    // GI / IBD
    'asacol':        'mesalamine',
    'mezavant':      'mesalamine',
    'pentasa':       'mesalamine',
    'salofalk':      'mesalamine',
    'zantac':        'ranitidine',
    'gaviscon':      'alginate',
    // More antibiotics
    'keflex':        'cephalexin',
    'bactrim':       'trimethoprim sulfamethoxazole',
    'doxycycline':   'doxycycline',
    'klacid':        'clarithromycin',
    // More cardiovascular
    'inderal':       'propranolol',
    'tenormin':      'atenolol',
    'zestril':       'lisinopril',
    'prinivil':      'lisinopril',
    'altace':        'ramipril',
    'tritace':       'ramipril',
    'micardis':      'telmisartan',
    'diovan':        'valsartan',
    // More pain
    'celebrex':      'celecoxib',
    'arcoxia':       'etoricoxib',
    'tramal':        'tramadol',
    'ultram':        'tramadol',
    'codeine':       'codeine',
    // Diabetes
    'lantus':        'insulin glargine',
    'novorapid':     'insulin aspart',
    'humalog':       'insulin lispro',
    'victoza':       'liraglutide',
    'jardiance':     'empagliflozin',
    'forxiga':       'dapagliflozin',
    'ozempic':       'semaglutide',
    // More respiratory
    'spiriva':       'tiotropium',
    'atrovent':      'ipratropium',
    'pulmicort':     'budesonide',
    'flixotide':     'fluticasone',
    // Skin / topical
    'fucidin':       'fusidic acid',
    'canesten':      'clotrimazole',
    'lamisil':       'terbinafine',
    'elocon':        'mometasone',
    'betnovate':     'betamethasone',
    // Supplements
    'calcichew':     'calcium carbonate',
    'caltrate':      'calcium carbonate',
    'neurobion':     'vitamin b complex',
    'centrum':       'multivitamin',
  };

  // =========================================================================
  //  PUBLIC ENTRY POINT
  // =========================================================================
  static Future<MedicineModel?> fetchAndEnrich(String query) async {
    final q = _n(query);
    if (q.isEmpty) return null;

    // Resolve brand → generic BEFORE hitting any API.
    // This dramatically improves OpenFDA hit-rate for Gulf brands.
    final resolvedGeneric = _resolveGeneric(q);

    // Step 1 — OpenFDA label
    MedicineModel? medicine = await _fetchOpenFDA(resolvedGeneric ?? q);

    // If OpenFDA failed with the resolved generic, try the raw query too
    if (medicine == null && resolvedGeneric != null && resolvedGeneric != q) {
      medicine = await _fetchOpenFDA(q);
    }

    // Step 2 — RxNorm approximate search as final fallback
    // This handles any drug that OpenFDA simply doesn't have.
    if (medicine == null) {
      medicine = await _buildFromRxNorm(resolvedGeneric ?? q);
    }

    if (medicine == null) return null;

    // Step 3 — RxNorm: resolve name → RxCUI for interactions
    final rxcui = await _resolveRxcui(
      medicine.genericName.isNotEmpty ? medicine.genericName : medicine.name,
    );

    if (rxcui != null) {
      medicine = medicine.copyWith(rxcui: rxcui);

      // Step 4 — RxNorm Interaction API
      final interactions = await _fetchRxNormInteractions(rxcui);
      if (interactions.isNotEmpty) {
        final merged = <String>{
          ...medicine.avoidCombinations,
          ...interactions,
        }.toList()..sort();
        medicine = medicine.copyWith(avoidCombinations: merged);
      }

      // Step 5 — DailyMed pregnancy/lactation warning
      final pregnancyWarning = await _fetchDailyMedPregnancy(
        medicine.genericName.isNotEmpty ? medicine.genericName : medicine.name,
      );
      if (pregnancyWarning != null) {
        medicine = medicine.copyWith(pregnancyWarning: pregnancyWarning);
      }
    }

    return medicine;
  }

  // =========================================================================
  //  BRAND → GENERIC RESOLVER
  // =========================================================================
  /// Strips dosage suffix from the query, then looks up the generic.
  /// "glucophage 500mg" → "glucophage" → "metformin"
  static String? _resolveGeneric(String query) {
    final base = query
        .replaceAll(RegExp(r'\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Try exact match first
    if (_brandToGeneric.containsKey(base)) return _brandToGeneric[base];

    // Try prefix match (handles "panadol extra", "panadol night", etc.)
    for (final entry in _brandToGeneric.entries) {
      if (base.startsWith(entry.key)) return entry.value;
    }
    return null;
  }

  // =========================================================================
  //  LAYER 1 — OpenFDA Drug Label
  // =========================================================================
  static Future<MedicineModel?> _fetchOpenFDA(String query) async {
    final encodedQuery = Uri.encodeComponent(query);

    // Strategies 1-3: precise field searches — result is trusted as-is
    final preciseEndpoints = [
      'https://api.fda.gov/drug/label.json'
          '?search=openfda.brand_name:"$encodedQuery"&limit=1',
      'https://api.fda.gov/drug/label.json'
          '?search=openfda.generic_name:"$encodedQuery"&limit=1',
      'https://api.fda.gov/drug/label.json'
          '?search=openfda.substance_name:"$encodedQuery"&limit=1',
    ];

    for (final url in preciseEndpoints) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(_long);
        if (res.statusCode != 200) continue;
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = body['results'] as List?;
        if (results == null || results.isEmpty) continue;
        return _parseFDALabel(results.first as Map<String, dynamic>, query);
      } catch (_) {
        continue;
      }
    }

    // Strategy 4: broad full-text search — ONLY accepted if the returned
    // medicine name actually contains the query token. This prevents
    // "silicea" (an inactive ingredient) from matching as the drug name.
    try {
      final broadUrl = 'https://api.fda.gov/drug/label.json'
          '?search=$encodedQuery&limit=3'; // fetch 3, pick best match
      final res = await http.get(Uri.parse(broadUrl)).timeout(_long);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = body['results'] as List? ?? [];
        for (final result in results) {
          final fda = result as Map<String, dynamic>;
          if (_resultMatchesQuery(fda, query)) {
            return _parseFDALabel(fda, query);
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Verifies that an OpenFDA result actually represents the queried drug.
  /// Checks brand names, generic names, and substance names against the query.
  static bool _resultMatchesQuery(Map<String, dynamic> fda, String query) {
    final q = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final openfda = (fda['openfda'] as Map<String, dynamic>?) ?? {};

    final namesToCheck = [
      ..._asList(openfda['brand_name']),
      ..._asList(openfda['generic_name']),
      ..._asList(openfda['substance_name']),
    ];

    for (final name in namesToCheck) {
      final n = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (n.contains(q) || q.contains(n)) return true;
    }
    return false;
  }

  static MedicineModel _parseFDALabel(Map<String, dynamic> fda, String originalQuery) {
    final openfda = (fda['openfda'] as Map<String, dynamic>?) ?? {};

    final brandNames   = _asList(openfda['brand_name']);
    final genericNames = _asList(openfda['generic_name']);
    final substances   = _asList(openfda['substance_name']);

    // For Gulf brands: preserve the user's original brand name as `name`
    // even if OpenFDA knows it by a different brand.
    final resolvedBrand = _resolveOriginalBrand(originalQuery);
    
    // ✅ FIXED: Use _getBestBrandName to filter out descriptive names
    final name = resolvedBrand ?? _getBestBrandName(brandNames);
    final genericName = _firstOf(genericNames).toLowerCase();

    final aliasSet = <String>{};
    for (final n in [...brandNames, ...substances]) {
      final v = n.toLowerCase().trim();
      if (v.isNotEmpty && v != name) aliasSet.add(v);
    }
    // Always include the original query as an alias so future lookups hit cache
    aliasSet.add(_n(originalQuery));
    if (resolvedBrand != null) aliasSet.add(resolvedBrand);

    final dosage = _cleanField(
      _firstText([fda['dosage_forms_and_strengths'], fda['dosage_and_administration']]),
      120,
    );

    final description = _cleanField(
      _firstText([fda['description'], fda['purpose'], fda['indications_and_usage']]),
      500,
    );

    final interactionText = _firstText([fda['drug_interactions']]);
    final avoidFromFda    = _extractDrugNamesFromText(interactionText);

    final warningText    = _firstText([fda['warnings'], fda['contraindications']]);
    final allergyTrigger = _extractAllergyTrigger(warningText, genericName);

    final pregnancyText    = _firstText([fda['pregnancy'], fda['teratogenic_effects']]);
    final pregnancyWarning = _classifyPregnancy(pregnancyText);

    return MedicineModel(
      id:                _n(name).replaceAll(' ', '_'),
      name:              name,
      genericName:       genericName,
      dosage:            dosage,
      description:       description,
      aliases:           aliasSet.toList(),
      avoidCombinations: avoidFromFda,
      allergyTrigger:    allergyTrigger,
      pregnancyWarning:  pregnancyWarning,
    );
  }

  /// If the original query maps to a known Gulf brand, return that brand name
  /// so the stored document uses the familiar brand (not the FDA brand name).
  static String? _resolveOriginalBrand(String query) {
    final base = query
        .replaceAll(RegExp(r'\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '')
        .trim();
    if (_brandToGeneric.containsKey(base)) return base;
    return null;
  }

  /// ✅ NEW: Get brand name, but filter out descriptive ones
  /// Prefer actual brand names like "Panadol", not "Pain Reliever Extra Strength"
  static String _getBestBrandName(List<String> brandNames) {
    if (brandNames.isEmpty) return '';
    
    // ✅ Filter: keep only names that aren't pure descriptive text
    final filtered = <String>[];
    for (final name in brandNames) {
      final lower = name.toLowerCase();
      
      // Count how many descriptive words are in this name
      final descriptiveCount = _descriptiveWords
          .where((word) => lower.contains(word))
          .length;
      
      // If 2+ descriptive words: it's "Pain Reliever Extra Strength" ❌
      // If 0-1 descriptive words: it's "Panadol Extra" ✅
      if (descriptiveCount <= 1 && name.length <= 50) {
        filtered.add(name);
      }
    }
    
    // If we filtered everything, use the shortest name
    if (filtered.isEmpty) {
      brandNames.sort((a, b) => a.length.compareTo(b.length));
      return brandNames.first.toLowerCase();
    }
    
    // Use the shortest filtered name (real brand names are short)
    filtered.sort((a, b) => a.length.compareTo(b.length));
    return filtered.first.toLowerCase();
  }

  // =========================================================================
  //  LAYER 2b — RxNorm fallback model builder
  //  When OpenFDA has no label, build a minimal but functional MedicineModel
  //  from RxNorm data alone. This covers any drug in the RxNorm vocabulary.
  // =========================================================================
  static Future<MedicineModel?> _buildFromRxNorm(String query) async {
    // Use approximate match — handles spelling variation and partial names
    final approxUrl =
        'https://rxnav.nlm.nih.gov/REST/approximateTerm.json'
        '?term=${Uri.encodeComponent(query)}&maxEntries=1';

    try {
      final res = await http.get(Uri.parse(approxUrl)).timeout(_short);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = body['approximateGroup']?['candidate'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final rxcui = candidates.first['rxcui']?.toString();
      final score = int.tryParse(candidates.first['score']?.toString() ?? '0') ?? 0;

      // Only trust high-confidence approximate matches
      if (rxcui == null || score < 70) return null;

      // Get the display name for this RxCUI
      final nameUrl =
          'https://rxnav.nlm.nih.gov/REST/rxcui/$rxcui/property.json?propName=RxNorm%20Name';
      final nameRes = await http.get(Uri.parse(nameUrl)).timeout(_short);
      String resolvedName = query;
      if (nameRes.statusCode == 200) {
        final nd = jsonDecode(nameRes.body) as Map<String, dynamic>;
        final val = nd['propConceptGroup']?['propConcept']?[0]?['propValue'];
        if (val != null) resolvedName = val.toString().toLowerCase();
      }

      // Build a minimal model — interactions and pregnancy will be enriched
      // by the subsequent RxNorm Interaction + DailyMed calls in fetchAndEnrich
      return MedicineModel(
        id:                _n(resolvedName).replaceAll(' ', '_'),
        name:              _resolveOriginalBrand(query) ?? resolvedName,
        genericName:       resolvedName,
        dosage:            '',
        description:       'Drug information sourced from RxNorm (NLM). '
                           'Consult your pharmacist for full prescribing details.',
        aliases:           [_n(query), resolvedName],
        avoidCombinations: [],
        allergyTrigger:    resolvedName,
        pregnancyWarning:  'caution', // conservative default when unknown
        rxcui:             rxcui,
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  //  LAYER 2 — RxNorm: name → RxCUI
  // =========================================================================
  static Future<String?> _resolveRxcui(String name) async {
    if (name.isEmpty) return null;
    final url =
        'https://rxnav.nlm.nih.gov/REST/rxcui.json'
        '?name=${Uri.encodeComponent(name)}&search=1';
    try {
      final res = await http.get(Uri.parse(url)).timeout(_short);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final idGroup = body['idGroup'] as Map<String, dynamic>?;
      final rxnormId = idGroup?['rxnormId'];
      if (rxnormId is List && rxnormId.isNotEmpty) {
        return rxnormId.first.toString();
      }
    } catch (_) {}
    return null;
  }

  // =========================================================================
  //  LAYER 3 — RxNorm Interaction API
  // =========================================================================
  static Future<List<String>> _fetchRxNormInteractions(String rxcui) async {
    final url =
        'https://rxnav.nlm.nih.gov/REST/interaction/interaction.json'
        '?rxcui=$rxcui&sources=ONCHigh+DrugBank';
    try {
      final res = await http.get(Uri.parse(url)).timeout(_long);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      final interactionTypeGroup = body['interactionTypeGroup'] as List? ?? [];
      final names = <String>{};

      for (final group in interactionTypeGroup) {
        final interactionTypes =
            (group as Map<String, dynamic>)['interactionType'] as List? ?? [];
        for (final type in interactionTypes) {
          final pairs =
              (type as Map<String, dynamic>)['interactionPair'] as List? ?? [];
          for (final pair in pairs) {
            final concepts =
                (pair as Map<String, dynamic>)['interactionConcept'] as List? ?? [];
            for (final concept in concepts) {
              final item = (concept as Map<String, dynamic>)['minConceptItem']
                  as Map<String, dynamic>?;
              final name = item?['name']?.toString().toLowerCase().trim();
              if (name != null && name.isNotEmpty) names.add(name);
            }
          }
        }
      }
      return names.toList();
    } catch (_) {
      return [];
    }
  }

  // =========================================================================
  //  LAYER 4 — DailyMed Pregnancy / Lactation Warning
  // =========================================================================
  static Future<String?> _fetchDailyMedPregnancy(String name) async {
    final searchUrl =
        'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls.json'
        '?drug_name=${Uri.encodeComponent(name)}&pagesize=1';
    try {
      final searchRes = await http.get(Uri.parse(searchUrl)).timeout(_short);
      if (searchRes.statusCode != 200) return null;
      final searchBody = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final data = searchBody['data'] as List?;
      if (data == null || data.isEmpty) return null;

      final setId = data.first['setid']?.toString();
      if (setId == null) return null;

      final detailUrl =
          'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls/$setId.json';
      final detailRes = await http.get(Uri.parse(detailUrl)).timeout(_long);
      if (detailRes.statusCode != 200) return null;

      final detail = jsonDecode(detailRes.body) as Map<String, dynamic>;
      final sections = detail['data']?['sections'] as List? ?? [];

      for (final section in sections) {
        final title = (section['title'] ?? '').toString().toLowerCase();
        final text  = (section['text']  ?? '').toString().toLowerCase();
        if (title.contains('pregnan') || title.contains('reproduct')) {
          return _classifyPregnancy(text);
        }
      }
    } catch (_) {}
    return null;
  }

  // =========================================================================
  //  SHARED PARSING HELPERS
  // =========================================================================

  static String _firstText(List<dynamic?> fields) {
    for (final f in fields) {
      if (f == null) continue;
      if (f is List && f.isNotEmpty) return f.first.toString().trim();
      if (f is String && f.isNotEmpty) return f.trim();
    }
    return '';
  }

  static List<String> _asList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [v.toString()];
  }

  static String _firstOf(List<String> l) =>
      l.isNotEmpty ? l.first.trim() : '';

  static String _cleanField(String text, int max) {
    if (text.isEmpty) return '';
    String s = text
        // Strip repeated section-header words that OpenFDA leaves in raw text
        .replaceAll(RegExp(r'\b(DOSAGE|USES|INDICATIONS|DESCRIPTION|PURPOSE|DIRECTIONS)\b\s*:?\s*',
            caseSensitive: false), '')
        // Collapse repeated words at the start (e.g. "USES USES:")
        .replaceAll(RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false), r'\1')
        // Strip asterisks used as footnote markers
        .replaceAll(RegExp(r'\*+'), '')
        // Collapse whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Take first 3 sentences for description, otherwise just truncate
    final sentences = s.split(RegExp(r'(?<=[.!?])\s+'));
    s = sentences.take(3).join(' ').trim();
    if (s.length > max) s = '${s.substring(0, max)}...';
    return s;
  }

  static String _truncate(String text, int max) {
    final c = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return c.length > max ? '${c.substring(0, max)}...' : c;
  }

  static List<String> _extractDrugNamesFromText(String text) {
    if (text.isEmpty) return [];
    const stopWords = {
      'This','The','Use','See','Tell','Take','Avoid','Do','If','When',
      'May','Not','Patients','Drug','Drugs','With','For','And','Or',
      'Should','Must','Are','Been','Has','Have','Can','Could','Will',
    };
    final matches =
        RegExp(r'\b([A-Z][a-z]{3,}(?:\s[A-Z][a-z]{2,})?)\b').allMatches(text);
    final names = <String>{};
    for (final m in matches) {
      final word = m.group(1)!;
      if (!stopWords.contains(word)) names.add(word.toLowerCase());
    }
    return names.take(15).toList();
  }

  static String _classifyPregnancy(String text) {
    if (text.isEmpty) return 'none';
    final t = text.toLowerCase();
    if (t.contains('contraindicated') ||
        t.contains('should not be used') ||
        t.contains('do not use') ||
        t.contains('category x') ||
        t.contains('teratogenic')) {
      return 'avoid';
    }
    if (t.contains('category d') ||
        t.contains('category c') ||
        t.contains('caution') ||
        t.contains('risk') ||
        t.contains('consult') ||
        t.contains('not recommended')) {
      return 'caution';
    }
    return 'none';
  }

  static String _extractAllergyTrigger(String text, String fallback) {
    final lower = text.toLowerCase();
    for (final pattern in [
      RegExp(r'hypersensitivity\s+to\s+([\w\s\-]+?)(?:[\.,;]|$)', caseSensitive: false),
      RegExp(r'allergic(?:\s+reaction)?\s+to\s+([\w\s\-]+?)(?:[\.,;]|$)', caseSensitive: false),
    ]) {
      final m = pattern.firstMatch(lower);
      if (m != null) return m.group(1)!.trim();
    }
    return fallback.isNotEmpty ? fallback : 'none';
  }

  static String _n(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}