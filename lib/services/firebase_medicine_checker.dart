import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMedicineChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> checkMedicine({
    required String uid,
    required String ocrText,
  }) async {
    final normalizedOcr = _normalize(ocrText);

    // 1) Get user
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final userData = userDoc.data() ?? {};
    final healthInfo = Map<String, dynamic>.from(userData['healthInfo'] ?? {});

    final allergies = _splitTextList(healthInfo['allergies']);
    final chronicConditions = _splitTextList(healthInfo['chronicConditions']);
    final currentMedications = _splitTextList(healthInfo['currentMedications']);
    final specialConditions = _splitTextList(healthInfo['specialConditions']);

    // 2) Get user's medicine table (if exists)
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

    // 3) Get medicines from Firestore
    final medsSnap = await _firestore.collection('medicines').get();

    Map<String, dynamic>? matchedMedicine;
    double bestScore = 0;

    for (final doc in medsSnap.docs) {
      final med = doc.data();

      final name = (med['name'] ?? '').toString();
      final genericName = (med['generic_name'] ?? '').toString();
      final dosage = (med['dosage'] ?? '').toString();

      final normalizedName = _normalize(name);
      final normalizedGeneric = _normalize(genericName);
      final normalizedDosage = _normalize(dosage);

      double score = 0;

      if (normalizedName.isNotEmpty && normalizedOcr.contains(normalizedName)) {
        score += 0.6;
      }

      if (normalizedGeneric.isNotEmpty &&
          normalizedOcr.contains(normalizedGeneric)) {
        score += 0.25;
      }

      if (normalizedDosage.isNotEmpty &&
          normalizedOcr.contains(normalizedDosage)) {
        score += 0.15;
      }

      if (score > bestScore) {
        bestScore = score;
        matchedMedicine = med;
      }
    }

    if (matchedMedicine == null || bestScore < 0.6) {
      return null;
    }

    // 4) Safety check
    String status = 'safe';
    final reasons = <String>[];

    final allergyIngredient =
        _normalize((matchedMedicine['allergy_ingredient'] ?? '').toString());

    final pregnancyWarning =
        (matchedMedicine['pregnancy_warning'] ?? '').toString().trim().toLowerCase();

    final avoidCombinations = _splitTextList(
      matchedMedicine['avoid_combinations'],
    );

    // Allergy
    if (allergyIngredient.isNotEmpty &&
        allergyIngredient != 'none' &&
        allergies.contains(allergyIngredient)) {
      status = 'not safe';
      reasons.add('Allergy conflict: $allergyIngredient');
    }

    // Current meds
    for (final med in currentMedications) {
      if (avoidCombinations.contains(med)) {
        status = 'not safe';
        reasons.add('Interacts with current medication: $med');
      }
    }

    // Scheduled meds from medicine_table
    for (final med in scheduledMedicines) {
      if (avoidCombinations.contains(med)) {
        status = 'not safe';
        reasons.add('Interacts with scheduled medicine: $med');
      }
    }

    // Pregnancy / special conditions
    if (specialConditions.contains('pregnant') ||
        specialConditions.contains('pregnancy')) {
      if (pregnancyWarning == 'avoid') {
        status = 'not safe';
        reasons.add('Not safe during pregnancy');
      } else if (pregnancyWarning == 'caution' && status != 'not safe') {
        status = 'caution';
        reasons.add('Use with caution during pregnancy');
      }
    }

    // Extra simple warning for NSAIDs if user already has NSAID allergy
    if (allergies.contains('nsaids') &&
        allergyIngredient == 'nsaids') {
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
    };

    // 5) Save scan result
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scan_results')
        .add({
      'ocrText': ocrText,
      'medicineName': matchedMedicine['name'],
      'dosage': matchedMedicine['dosage'],
      'status': status,
      'reasons': reasons,
      'score': bestScore,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return result;
  }

  static List<String> _splitTextList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => _normalize(e.toString()))
          .where((e) => e.isNotEmpty && e != 'none')
          .toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'none') return [];

    return text
        .split(RegExp(r'[,/;]'))
        .map((e) => _normalize(e))
        .where((e) => e.isNotEmpty && e != 'none')
        .toList();
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}