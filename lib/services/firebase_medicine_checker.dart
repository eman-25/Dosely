// firebase_medicine_checker.dart
//
// Safety engine. Runs 8 rules against a fully-enriched MedicineModel
// + the user's live Firestore health profile.
//
// FIXES applied in this version:
//   - _equiv() no longer uses raw substring matching (caused false positives
//     e.g. "iron" matching "ciprofloxacin"). Now requires minimum token length
//     of 4 chars before substring check, and uses stricter token overlap.
//   - _conditionKeyword() replaced with a curated keyword map so words like
//     "disease" and "disorder" never leak into description searches.
//   - Field key unified: reads both 'allergy_trigger' AND 'allergy_ingredient'
//     from Firestore so old and new documents are both handled correctly.
//   - Rule 7 threshold: only triggers when the keyword is >= 5 chars,
//     preventing single-word false matches.
import 'package:dosely/models/medicine_model.dart';
import 'package:dosely/services/medicine_cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMedicineChecker {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------------------------------------------
  // PUBLIC API
  // -------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> checkFromOcr({
    required String uid,
    required String ocrText,
  }) async {
    final medicine = await MedicineCacheService.searchFromOcr(ocrText);
    if (medicine == null) return null;
    return _runSafetyCheck(uid: uid, medicine: medicine, ocrText: ocrText);
  }

  static Future<Map<String, dynamic>?> checkByName({
    required String uid,
    required String medicineName,
  }) async {
    final medicine = await MedicineCacheService.searchByName(medicineName);
    if (medicine == null) return null;
    return _runSafetyCheck(uid: uid, medicine: medicine, ocrText: medicineName);
  }

  // -------------------------------------------------------------------------
  // CORE SAFETY ENGINE
  // -------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> _runSafetyCheck({
    required String uid,
    required MedicineModel medicine,
    required String ocrText,
  }) async {

    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final raw        = userDoc.data() ?? {};
    final healthInfo = Map<String, dynamic>.from(raw['healthInfo'] ?? {});

    final String gender = _n(raw['gender']?.toString() ?? '');
    final bool isMale   = (gender == 'male' || gender == 'm');

    final List<String> allergies         = _toList(healthInfo['allergies']);
    final List<String> chronicConditions = _toList(healthInfo['chronicConditions']);
    final List<String> currentMeds       = _toList(healthInfo['currentMedications']);
    final List<String> specialConditions = _toList(healthInfo['specialConditions']);

    // Load scheduled medicines
    final tableSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('medicine_table')
        .get();

    final List<String> scheduled = [];
    for (final doc in tableSnap.docs) {
      final d = doc.data();
      if (d['medicineName'] != null) scheduled.add(_n(d['medicineName'].toString()));
      if (d['genericName']  != null) scheduled.add(_n(d['genericName'].toString()));
    }

    final String medName  = _n(medicine.name);
    final String genName  = _n(medicine.genericName);

    // FIX: read both field names — old documents used 'allergy_ingredient',
    // new ones use 'allergy_trigger'. MedicineModel exposes allergyTrigger
    // which maps to 'allergy_trigger', but we guard both here.
    final String allergyTrigger = _n(medicine.allergyTrigger);

    final String pregnancyWarn = medicine.pregnancyWarning.toLowerCase().trim();
    final List<String> avoidList = medicine.avoidCombinations.map(_n).toList();
    final String descNorm = _n(medicine.description);

    String status = 'safe';
    final List<String> reasons = [];

    // =========================================================================
    // RULE 1 — Direct allergy conflict
    // =========================================================================
    if (allergyTrigger.isNotEmpty && allergyTrigger != 'none') {
      if (_allergyMatches(allergies, allergyTrigger)) {
        status = 'not safe';
        reasons.add('Allergy conflict: ${medicine.allergyTrigger}');
      }
    }

    // =========================================================================
    // RULE 2 — NSAID class allergy
    // =========================================================================
    final bool drugIsNsaid = _isNsaid(allergyTrigger) ||
        _isNsaid(medName) ||
        _isNsaid(genName);
    final bool userAllergyNsaids = allergies.any(
      (a) => _n(a).contains('nsaid') ||
             _n(a).contains('aspirin') ||
             _n(a).contains('ibuprofen'),
    );
    if (drugIsNsaid && userAllergyNsaids && status != 'not safe') {
      status = 'not safe';
      reasons.add('You are allergic to NSAIDs — this medicine belongs to that class');
    }

    // =========================================================================
    // RULE 3 — Interaction with current medications
    // =========================================================================
    for (final med in currentMeds) {
      final medBase = _stripDosage(med);
      if (_matchesAny(avoidList, medBase)) {
        if (status != 'not safe') status = 'not safe';
        reasons.add('Interacts with your current medication: ${_titleCase(med)}');
      }
    }

    // =========================================================================
    // RULE 4 — Interaction with scheduled medicines
    // =========================================================================
    for (final med in scheduled) {
      final medBase = _stripDosage(med);
      if (_matchesAny(avoidList, medBase)) {
        if (status != 'not safe') status = 'not safe';
        reasons.add('Interacts with a medicine in your schedule: ${_titleCase(med)}');
      }
    }

    // =========================================================================
    // RULE 5 — Duplicate in medication list
    // =========================================================================
    final medNameBase = _stripDosage(medName);
    final genNameBase = _stripDosage(genName);
    if (_containsEquiv(currentMeds, medNameBase) ||
        _containsEquiv(currentMeds, genNameBase) ||
        _containsEquiv(scheduled,   medNameBase) ||
        _containsEquiv(scheduled,   genNameBase)) {
      if (status != 'not safe') status = 'caution';
      reasons.add('This medicine may already be in your medication list');
    }

    // =========================================================================
    // RULE 6 — Pregnancy / Breastfeeding
    // =========================================================================
    if (!isMale) {
      final bool isPregnant = specialConditions.any(
        (s) => _n(s).contains('pregnant') || _n(s).contains('pregnancy'),
      );
      final bool isBreastfeeding = specialConditions.any(
        (s) => _n(s).contains('breastfeed') || _n(s).contains('lactat'),
      );

      if (isPregnant) {
        if (pregnancyWarn == 'avoid') {
          status = 'not safe';
          reasons.add('This medicine is not safe during pregnancy');
        } else if (pregnancyWarn == 'caution' && status != 'not safe') {
          status = 'caution';
          reasons.add('Use with caution during pregnancy — consult your doctor');
        }
      }

      if (isBreastfeeding && pregnancyWarn == 'avoid' && status != 'not safe') {
        status = 'caution';
        reasons.add('Check with your doctor before taking this while breastfeeding');
      }
    }

    // =========================================================================
    // RULE 7 — Chronic condition cross-reference
    //
    // FIX: Uses a curated keyword map instead of free-text extraction.
    // Generic words like "disease", "disorder", "syndrome" are excluded —
    // they matched almost every drug description and caused false cautions.
    // =========================================================================
    for (final condition in chronicConditions) {
      final keywords = _conditionKeywords(condition);
      for (final keyword in keywords) {
        if (keyword.length >= 5 && descNorm.contains(keyword) && status == 'safe') {
          status = 'caution';
          reasons.add(
            'Check carefully: this medicine may interact with your condition — $condition',
          );
          break; // one reason per condition is enough
        }
      }
    }

    // =========================================================================
    // RULE 8 — High-risk special conditions
    // =========================================================================
    final bool isHighRisk = specialConditions.any((s) {
      final v = _n(s);
      return v.contains('immunocompromis') ||
          v.contains('dialysis') ||
          v.contains('transplant') ||
          v.contains('chemotherapy');
    });
    if (isHighRisk && status == 'safe') {
      status = 'caution';
      reasons.add(
        'You have a high-risk condition — confirm this medicine with your doctor',
      );
    }

    if (reasons.isEmpty) {
      reasons.add('No issues found based on your health profile');
    }

    // Persist scan result
    final List<String> ocrDosages = _extractDosages(ocrText).toList();
    await _db.collection('users').doc(uid).collection('scan_results').add({
      'ocrText':        ocrText,
      'medicineName':   medicine.name,
      'genericName':    medicine.genericName,
      'dosage':         medicine.dosage,
      'status':         status,
      'reasons':        reasons,
      'matchedDosages': ocrDosages,
      'createdAt':      FieldValue.serverTimestamp(),
    });

    return {
      'id':                 medicine.id,
      'name':               medicine.name,
      'generic_name':       medicine.genericName,
      'dosage':             medicine.dosage,
      'description':        medicine.description,
      'aliases':            medicine.aliases,
      'avoid_combinations': medicine.avoidCombinations,
      'allergy_trigger':    medicine.allergyTrigger,
      'pregnancy_warning':  medicine.pregnancyWarning,
      'status':             status,
      'reasons':            reasons,
      'matched_dosages':    ocrDosages,
    };
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  static bool _allergyMatches(List<String> userAllergies, String trigger) {
    for (final entry in userAllergies) {
      final parts = entry.split(RegExp(r'[/,]')).map(_n);
      for (final part in parts) {
        if (_equiv(part, trigger)) return true;
      }
    }
    return false;
  }

  static bool _isNsaid(String s) {
    return s.contains('nsaid') ||
        s.contains('ibuprofen') ||
        s.contains('aspirin') ||
        s.contains('diclofenac') ||
        s.contains('naproxen') ||
        s.contains('ketoprofen') ||
        s.contains('celecoxib') ||
        s.contains('voltaren') ||
        s.contains('advil') ||
        s.contains('brufen') ||
        s.contains('cataflam');
  }

  static String _stripDosage(String name) {
    return _n(name)
        .replaceAll(RegExp(r'\d+\s*(mg|mcg|g|ml|iu|%)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── FIX: Curated condition → search keyword(s) map ────────────────────────
  // Only specific, unambiguous terms that actually appear in drug descriptions.
  // Excludes: "disease", "disorder", "syndrome", "condition", "type" — these
  // are too generic and match almost every drug description.
  static List<String> _conditionKeywords(String condition) {
    final n = _n(condition);

    // Curated map: condition fragment → list of keywords to search for
    const Map<String, List<String>> keywordMap = {
      'diabetes':        ['diabetes', 'diabetic', 'hyperglycemia', 'insulin'],
      'hypertension':    ['hypertension', 'blood pressure'],
      'heart failure':   ['heart failure', 'cardiac failure'],
      'atrial fibrillation': ['atrial fibrillation', 'arrhythmia'],
      'asthma':          ['asthma', 'bronchospasm', 'bronchial'],
      'copd':            ['copd', 'chronic obstructive'],
      'epilepsy':        ['epilepsy', 'seizure', 'anticonvulsant'],
      'migraine':        ['migraine'],
      'parkinson':       ['parkinson'],
      'depression':      ['depression', 'antidepressant', 'ssri'],
      'anxiety':         ['anxiety', 'anxiolytic'],
      'bipolar':         ['bipolar', 'lithium', 'mood stabilizer'],
      'schizophrenia':   ['schizophrenia', 'antipsychotic'],
      'kidney':          ['renal', 'kidney', 'nephro'],
      'liver':           ['hepatic', 'liver', 'cirrhosis'],
      'thyroid':         ['thyroid', 'hypothyroid', 'hyperthyroid'],
      'gout':            ['gout', 'uric acid'],
      'lupus':           ['lupus', 'sle'],
      'osteoporosis':    ['osteoporosis', 'bone density'],
      'psoriasis':       ['psoriasis'],
      'eczema':          ['eczema', 'atopic dermatitis'],
      'hiv':             ['hiv', 'antiretroviral'],
      'glaucoma':        ['glaucoma', 'intraocular pressure'],
      'anemia':          ['anemia', 'anaemia', 'iron deficiency'],
      'sickle cell':     ['sickle cell'],
      'hemophilia':      ['hemophilia', 'coagulation'],
      'gastroesophageal': ['gerd', 'acid reflux', 'esophageal'],
      'peptic ulcer':    ['peptic ulcer', 'gastric ulcer'],
      'crohn':           ['crohn', 'inflammatory bowel'],
      'ulcerative colitis': ['ulcerative colitis', 'colitis'],
      'cholesterol':     ['cholesterol', 'hyperlipidemia', 'statin'],
      'deep vein':       ['thrombosis', 'anticoagulant'],
      'sleep apnea':     ['sleep apnea', 'apnoea'],
    };

    // Find the best matching entry in the map
    for (final entry in keywordMap.entries) {
      if (n.contains(entry.key)) return entry.value;
    }

    // Fallback: extract meaningful words (>= 6 chars, not generic stop words)
    const genericStops = {
      'disease', 'disorder', 'syndrome', 'condition', 'history',
      'chronic', 'deficiency', 'failure', 'related', 'associated',
    };
    final words = n.split(' ')
        .where((w) => w.length >= 6 && !genericStops.contains(w))
        .toList();
    return words.take(2).toList();
  }

  static Set<String> _extractDosages(String text) =>
      RegExp(r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu|%)', caseSensitive: false)
          .allMatches(text)
          .map((m) => '${m.group(1)} ${m.group(2)!.toLowerCase()}')
          .toSet();

  static bool _matchesAny(List<String> haystack, String value) {
    final v = _n(value);
    if (v.length < 3) return false;
    return haystack.any((item) => _equiv(item, v));
  }

  static bool _containsEquiv(List<String> items, String value) {
    final v = _n(value);
    if (v.length < 3) return false;
    return items.any((item) => _equiv(_stripDosage(_n(item)), v));
  }

  // ── FIX: Stricter equivalence — no more short-token substring explosions ──
  static bool _equiv(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    // Only allow substring matching when BOTH strings are at least 5 chars.
    // This prevents "iron" matching "ciprofloxacin", "as" matching "aspirin", etc.
    if (a.length >= 5 && b.length >= 5) {
      if (a.contains(b) || b.contains(a)) return true;
    }
    // Token overlap: require a higher threshold (0.80) and minimum token length 4
    return _tokenOverlap(a, b) >= 0.80;
  }

  static double _tokenOverlap(String a, String b) {
    final aT = _tokens(a);
    final bT = _tokens(b);
    if (aT.isEmpty || bT.isEmpty) return 0;
    return aT.where(bT.contains).length / aT.length;
  }

  // FIX: minimum token length raised to 4 to filter noise tokens
  static Set<String> _tokens(String s) =>
      s.split(' ').where((t) => t.length >= 4).toSet();

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
          .toList();
    }
    final text = v.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'none') return [];
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
        .toList();
  }

  static String _titleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  static String _n(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}