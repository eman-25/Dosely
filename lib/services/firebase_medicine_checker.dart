import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMedicineChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> checkMedicine({
    required String uid,
    required String ocrText,
  }) async {
    final normalizedOcr = _normalize(ocrText);
    final ocrLines = _extractUsefulLines(ocrText);
    final ocrDosages = _extractDosages(ocrText);

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final userData = userDoc.data() ?? {};
    final healthInfo = Map<String, dynamic>.from(userData['healthInfo'] ?? {});

    final allergies = _splitTextList(healthInfo['allergies']);
    final chronicConditions = _splitTextList(healthInfo['chronicConditions']);
    final currentMedications = _splitTextList(healthInfo['currentMedications']);
    final specialConditions = _splitTextList(healthInfo['specialConditions']);

    final medTableSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('medicine_table')
        .get();

    final scheduledMedicines = <String>[];
    for (final doc in medTableSnap.docs) {
      final data = doc.data();
      if (data['medicineName'] != null) {
        scheduledMedicines.add(_normalize(data['medicineName'].toString()));
      }
      if (data['genericName'] != null) {
        scheduledMedicines.add(_normalize(data['genericName'].toString()));
      }
    }

    final medsSnap = await _firestore.collection('medicines').get();

    Map<String, dynamic>? matchedMedicine;
    double bestScore = 0;

    for (final doc in medsSnap.docs) {
      final med = doc.data();
      final score = _scoreMedicine(
        med: med,
        normalizedOcr: normalizedOcr,
        ocrLines: ocrLines,
        ocrDosages: ocrDosages,
      );

      if (score > bestScore) {
        bestScore = score;
        matchedMedicine = med;
      }
    }

    if (matchedMedicine == null || bestScore < 0.58) {
      return null;
    }

    String status = 'safe';
    final reasons = <String>[];

    final allergyIngredient =
        _normalize((matchedMedicine['allergy_ingredient'] ?? '').toString());
    final pregnancyWarning =
        (matchedMedicine['pregnancy_warning'] ?? '').toString().trim().toLowerCase();
    final avoidCombinations = _splitTextList(matchedMedicine['avoid_combinations']);

    final normalizedMedicineName =
        _normalize((matchedMedicine['name'] ?? '').toString());
    final normalizedGenericName =
        _normalize((matchedMedicine['generic_name'] ?? '').toString());
    final medDescription =
        _normalize((matchedMedicine['description'] ?? '').toString());

    if (allergyIngredient.isNotEmpty &&
        allergyIngredient != 'none' &&
        _containsEquivalent(allergies, allergyIngredient)) {
      status = 'not safe';
      reasons.add('Allergy conflict: ${matchedMedicine['allergy_ingredient']}');
    }

    for (final med in currentMedications) {
      if (_matchesAnyMedicineToken(avoidCombinations, med)) {
        status = 'not safe';
        reasons.add('Interacts with current medication: $med');
      }
    }

    for (final med in scheduledMedicines) {
      if (_matchesAnyMedicineToken(avoidCombinations, med)) {
        status = 'not safe';
        reasons.add('Interacts with scheduled medicine: $med');
      }
    }

    if (_containsEquivalent(currentMedications, normalizedMedicineName) ||
        _containsEquivalent(currentMedications, normalizedGenericName) ||
        _containsEquivalent(scheduledMedicines, normalizedMedicineName) ||
        _containsEquivalent(scheduledMedicines, normalizedGenericName)) {
      if (status != 'not safe') {
        status = 'caution';
      }
      reasons.add('This medicine may already exist in the user medication list');
    }

    if (_containsEquivalent(specialConditions, 'pregnant') ||
        _containsEquivalent(specialConditions, 'pregnancy')) {
      if (pregnancyWarning == 'avoid') {
        status = 'not safe';
        reasons.add('Not safe during pregnancy');
      } else if (pregnancyWarning == 'caution' && status != 'not safe') {
        status = 'caution';
        reasons.add('Use with caution during pregnancy');
      }
    }

    for (final condition in chronicConditions) {
      if (condition.isNotEmpty && medDescription.contains(condition) && status == 'safe') {
        status = 'caution';
        reasons.add('Check carefully with chronic condition: $condition');
      }
    }

    if (_containsEquivalent(allergies, 'nsaids') && allergyIngredient == 'nsaids') {
      status = 'not safe';
      reasons.add('User is allergic to NSAIDs');
    }

    if (reasons.isEmpty) {
      reasons.add('No issues found based on stored user data');
    }

    final result = {
      ...matchedMedicine,
      'score': bestScore,
      'status': status,
      'reasons': reasons,
      'matched_dosages': ocrDosages.toList(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scan_results')
        .add({
      'ocrText': ocrText,
      'medicineName': matchedMedicine['name'],
      'genericName': matchedMedicine['generic_name'],
      'dosage': matchedMedicine['dosage'],
      'status': status,
      'reasons': reasons,
      'score': bestScore,
      'matchedDosages': ocrDosages.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return result;
  }

  static double _scoreMedicine({
    required Map<String, dynamic> med,
    required String normalizedOcr,
    required List<String> ocrLines,
    required Set<String> ocrDosages,
  }) {
    final name = _normalize((med['name'] ?? '').toString());
    final genericName = _normalize((med['generic_name'] ?? '').toString());
    final dosage = _normalizeDosage((med['dosage'] ?? '').toString());
    final aliases = _splitTextList(med['aliases']);

    double score = 0;

    if (name.isNotEmpty) {
      if (normalizedOcr.contains(name)) {
        score += 0.60;
      } else {
        score += _bestLineMatchScore(name, ocrLines) * 0.50;
      }
    }

    if (genericName.isNotEmpty) {
      if (normalizedOcr.contains(genericName)) {
        score += 0.22;
      } else {
        score += _bestLineMatchScore(genericName, ocrLines) * 0.18;
      }
    }

    double bestAliasScore = 0;
    for (final alias in aliases) {
      if (alias.isEmpty) continue;
      double aliasScore = 0;
      if (normalizedOcr.contains(alias)) {
        aliasScore = 0.28;
      } else {
        aliasScore = _bestLineMatchScore(alias, ocrLines) * 0.24;
      }
      if (aliasScore > bestAliasScore) {
        bestAliasScore = aliasScore;
      }
    }
    score += bestAliasScore;

    if (dosage.isNotEmpty && ocrDosages.isNotEmpty) {
      if (ocrDosages.contains(dosage)) {
        score += 0.18;
      } else if (_hasLooseDosageMatch(dosage, ocrDosages)) {
        score += 0.10;
      }
    }

    if (name.isNotEmpty &&
        genericName.isNotEmpty &&
        _bestLineMatchScore(name, ocrLines) > 0.6 &&
        _bestLineMatchScore(genericName, ocrLines) > 0.45) {
      score += 0.05;
    }

    return score > 1.0 ? 1.0 : score;
  }

  static double _bestLineMatchScore(String target, List<String> ocrLines) {
    if (target.isEmpty || ocrLines.isEmpty) return 0;

    double best = 0;
    for (final line in ocrLines) {
      final score = _tokenOverlapScore(target, line);
      if (score > best) best = score;
    }
    return best;
  }

  static double _tokenOverlapScore(String a, String b) {
    final aTokens = _meaningfulTokens(a);
    final bTokens = _meaningfulTokens(b);

    if (aTokens.isEmpty || bTokens.isEmpty) return 0;

    int matched = 0;
    for (final token in aTokens) {
      if (bTokens.contains(token)) matched++;
    }

    return matched / aTokens.length;
  }

  static Set<String> _meaningfulTokens(String text) {
    return _normalize(text)
        .split(' ')
        .where((e) => e.isNotEmpty && e.length > 1)
        .toSet();
  }

  static List<String> _extractUsefulLines(String text) {
    return text
        .split(RegExp(r'[\n\r]+'))
        .map(_normalize)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static Set<String> _extractDosages(String text) {
    final matches = RegExp(
      r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu|%)',
      caseSensitive: false,
    ).allMatches(text);

    return matches
        .map((m) => '${m.group(1)} ${m.group(2)!.toLowerCase()}')
        .toSet();
  }

  static bool _hasLooseDosageMatch(String medicineDosage, Set<String> ocrDosages) {
    final medicineCompact = medicineDosage.replaceAll(' ', '');
    for (final d in ocrDosages) {
      final compact = d.replaceAll(' ', '');
      if (compact == medicineCompact) return true;
      if (compact.contains(medicineCompact) || medicineCompact.contains(compact)) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesAnyMedicineToken(List<String> haystack, String value) {
    final normalizedValue = _normalize(value);
    for (final item in haystack) {
      if (_areEquivalentMedicineNames(item, normalizedValue)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsEquivalent(List<String> items, String value) {
    final normalizedValue = _normalize(value);
    for (final item in items) {
      if (_areEquivalentMedicineNames(item, normalizedValue)) {
        return true;
      }
    }
    return false;
  }

  static bool _areEquivalentMedicineNames(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    if (left.contains(right) || right.contains(left)) return true;
    return _tokenOverlapScore(left, right) >= 0.75;
  }

  static List<String> _splitTextList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => _normalize(e.toString()))
          .where((e) => e.isNotEmpty && e != 'none')
          .toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'none') return [];

    return text
        .split(RegExp(r'[,/;|]'))
        .map((e) => _normalize(e))
        .where((e) => e.isNotEmpty && e != 'none')
        .toList();
  }

  static String _normalizeDosage(String input) {
    final normalized = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|iu|%)').firstMatch(normalized);
    if (match != null) {
      return '${match.group(1)} ${match.group(2)}';
    }
    return _normalize(input);
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
