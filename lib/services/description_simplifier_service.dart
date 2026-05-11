import 'package:google_generative_ai/google_generative_ai.dart';
import '../Screens/Main Features/api_key.dart';

class DescriptionSimplifierService {
  /// ✅ ENHANCED - Generate smart, personalized explanation of what the medicine does
  /// Based on user's health profile, but NO DOSAGE in the description
  /// 
  /// Features:
  /// - Explains the medicine's purpose in simple terms
  /// - Contextualizes based on user's conditions & allergies
  /// - Warns about relevant interactions
  /// - NO dosage information (that's a doctor's job)
  static Future<String> generateDetailedExplanation({
    required String medicineName,
    required String genericName,
    required int? ageInYears,
    required double? weightInKg,
    required String allergies,
    required String chronicConditions,
    required String specialConditions,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final fullName = genericName.isNotEmpty 
          ? '$medicineName (generic: $genericName)' 
          : medicineName;

      final String prompt = '''Medicine: $fullName
Patient profile — Age: ${ageInYears != null ? '$ageInYears years old' : 'unknown'}, Allergies: ${allergies.isEmpty || allergies.toLowerCase() == 'none' ? 'none' : allergies}, Chronic conditions: ${chronicConditions.isEmpty || chronicConditions.toLowerCase() == 'none' ? 'none' : chronicConditions}, Special conditions: ${specialConditions.isEmpty || specialConditions.toLowerCase() == 'none' ? 'none' : specialConditions}.

Write ONE short sentence saying only what this medicine is used for. Use simple everyday language.

Rules:
- Start with "Used to treat..." or "Used for..."
- Name the SPECIFIC conditions it treats (e.g. "acne, chest infections, urinary tract infections")
- NO explanation of how it works
- NO patient-profile notes
- NO dosage, frequency, or instructions
- NO "consult a doctor" or "talk to your pharmacist"
- NO extra commentary

Output one sentence only, nothing else.''';

      print('📤 Sending smart prompt to Gemini for: $fullName');

      // ✅ CALL GEMINI API
      final response = await model.generateContent([
        Content.text(prompt)
      ]).timeout(const Duration(seconds: 15));

      final text = response.text?.trim() ?? '';
      
      print('✅ Gemini returned: "$text"');

      if (text.isNotEmpty && text.length > 20) {
        return text;
      }
      
      print('⚠️ Gemini returned empty/short response');
      return _fallbackDescription(medicineName, genericName, ageInYears, allergies, chronicConditions);

    } catch (e) {
      print('❌ ERROR: $e');
      return _fallbackDescription(medicineName, genericName, ageInYears, allergies, chronicConditions);
    }
  }

  /// Enhanced smart fallback (no dosage)
  static String _fallbackDescription(
    String name, 
    String generic,
    int? age,
    String allergies,
    String chronicConditions,
  ) {
    final lower = generic.toLowerCase();
    
    // ═══════════════════════════════════════════════════════════════════════
    // PAIN & FEVER RELIEVERS
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('acetaminophen') || lower.contains('paracetamol')) {
      return 'Used to relieve mild to moderate pain and reduce fever.';
    }

    if (lower.contains('ibuprofen') || lower.contains('brufen')) {
      return 'Used to relieve pain, reduce inflammation, and lower fever — including headaches, muscle aches, and period pain.';
    }

    if (lower.contains('aspirin')) {
      return 'Used to relieve pain and fever, and in low doses to help prevent blood clots, heart attacks, and strokes.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ANTIBIOTICS
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('amoxicillin') || lower.contains('augmentin')) {
      return 'Used to treat bacterial infections such as ear infections, throat infections, chest infections, and pneumonia.';
    }

    if (lower.contains('azithromycin') || lower.contains('zithromax')) {
      return 'Used to treat bacterial infections such as chest infections, throat infections, ear infections, and some sexually transmitted infections.';
    }

    if (lower.contains('ciprofloxacin') || lower.contains('cipro')) {
      return 'Used to treat bacterial infections such as urinary tract infections, kidney infections, and some respiratory and stomach infections.';
    }

    if (lower.contains('doxycycline') || lower.contains('tabocine') || lower.contains('vibramycin')) {
      return 'Used to treat acne, chest and lung infections, urinary tract infections, Lyme disease, and some sexually transmitted infections, and to prevent malaria when traveling.';
    }

    if (lower.contains('clarithromycin') || lower.contains('klacid')) {
      return 'Used to treat chest infections, ear infections, throat infections, and stomach ulcers caused by H. pylori bacteria.';
    }

    if (lower.contains('cephalexin') || lower.contains('keflex')) {
      return 'Used to treat skin infections, ear infections, urinary tract infections, and respiratory infections.';
    }

    if (lower.contains('clindamycin') || lower.contains('dalacin')) {
      return 'Used to treat skin infections, dental infections, bone infections, and severe acne.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BLOOD PRESSURE & HEART
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('bisoprol') || lower.contains('concor')) {
      return 'Used to treat high blood pressure, heart failure, and irregular heartbeat.';
    }

    if (lower.contains('amlodipine') || lower.contains('norvasc')) {
      return 'Used to treat high blood pressure and chest pain (angina).';
    }

    if (lower.contains('losartan') || lower.contains('cozaar')) {
      return 'Used to treat high blood pressure and to protect the kidneys in people with diabetes.';
    }

    if (lower.contains('atorvastatin') || lower.contains('lipitor')) {
      return 'Used to lower high cholesterol and reduce the risk of heart attacks and strokes.';
    }

    if (lower.contains('furosemide') || lower.contains('lasix')) {
      return 'Used to treat fluid retention (swelling) and high blood pressure, often in heart failure and kidney problems.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STOMACH & DIGESTION
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('omeprazole') || lower.contains('losec')) {
      return 'Used to treat acid reflux, heartburn, and stomach ulcers.';
    }

    if (lower.contains('esomeprazole') || lower.contains('nexium')) {
      return 'Used to treat acid reflux, heartburn, and stomach ulcers.';
    }

    if (lower.contains('metronidazole') || lower.contains('flagyl')) {
      return 'Used to treat infections caused by certain bacteria and parasites, including stomach infections and dental infections.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RESPIRATORY
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('salbutamol') || lower.contains('ventolin')) {
      return 'Used to relieve asthma attacks and shortness of breath by opening the airways.';
    }

    if (lower.contains('montelukast') || lower.contains('singulair')) {
      return 'Used to prevent asthma attacks and relieve allergy symptoms.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ALLERGIES
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('cetirizine') || lower.contains('zyrtec')) {
      return 'Used to relieve allergy symptoms such as sneezing, itching, runny nose, and watery eyes.';
    }

    if (lower.contains('loratadine') || lower.contains('claritin')) {
      return 'Used to relieve allergy symptoms such as sneezing, itching, and runny nose.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DIABETES
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('metformin') || lower.contains('glucophage')) {
      return 'Used to control blood sugar in type 2 diabetes.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // THYROID
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('levothyroxine') || lower.contains('eltroxin') || lower.contains('euthyrox')) {
      return 'Used to treat an underactive thyroid (hypothyroidism).';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MENTAL HEALTH
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('alprazolam') || lower.contains('xanax')) {
      return 'Used to treat anxiety disorders and panic attacks.';
    }

    if (lower.contains('escitalopram') || lower.contains('cipralex')) {
      return 'Used to treat depression and anxiety.';
    }

    if (lower.contains('sertraline') || lower.contains('zoloft')) {
      return 'Used to treat depression, anxiety, panic disorder, and OCD.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DEFAULT FALLBACK — try to detect drug class from name suffix
    // ═══════════════════════════════════════════════════════════════════════
    // Antibiotic suffixes
    if (lower.endsWith('cycline') || lower.endsWith('mycin') ||
        lower.endsWith('cillin') || lower.endsWith('oxacin') ||
        lower.endsWith('cef') || lower.startsWith('cef')) {
      return 'Used to treat bacterial infections.';
    }
    // Antifungals
    if (lower.endsWith('azole') || lower.endsWith('conazole')) {
      return 'Used to treat fungal infections.';
    }
    // Painkillers / NSAIDs
    if (lower.endsWith('profen') || lower.endsWith('fenac')) {
      return 'Used to relieve pain, swelling, and fever.';
    }
    // Blood pressure / heart
    if (lower.endsWith('olol')) {
      return 'Used to treat high blood pressure and heart conditions.';
    }
    if (lower.endsWith('sartan') || lower.endsWith('ipril')) {
      return 'Used to treat high blood pressure.';
    }
    // Cholesterol
    if (lower.endsWith('statin') || lower.endsWith('vastatin')) {
      return 'Used to lower high cholesterol.';
    }
    // Stomach acid
    if (lower.endsWith('prazole')) {
      return 'Used to reduce stomach acid and treat heartburn, acid reflux, and ulcers.';
    }

    // Generic last-resort fallback
    final displayName = name.isNotEmpty ? name : 'This medicine';
    return 'Information about what $displayName is used for is not available.';
  }

  /// Simple version when user has no health data
  static Future<String> generateSimpleExplanation({
    required String medicineName,
    required String genericName,
  }) async {
    return generateDetailedExplanation(
      medicineName: medicineName,
      genericName: genericName,
      ageInYears: null,
      weightInKg: null,
      allergies: '',
      chronicConditions: '',
      specialConditions: '',
    );
  }
}

// ── AI-powered medicine name + dosage cleaner ─────────────────────────────────
class MedicineNameCleaner {
  /// Takes raw name/dosage strings from drug databases (e.g. OpenFDA) and
  /// returns a clean, short, human-readable name and dosage using Gemini.
  static Future<Map<String, String>> clean({
    required String rawName,
    required String rawDosage,
  }) async {
    // Fast path: already short and clean
    final trimmedName = rawName.trim();
    final trimmedDosage = rawDosage.trim();
    if (trimmedName.length <= 30 && !trimmedName.contains('•') &&
        !trimmedName.contains('\n') && !trimmedName.contains('[')) {
      return {
        'name': _capitalize(trimmedName),
        'dosage': _extractShortDosage(trimmedDosage),
      };
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final prompt = '''You are extracting clean medicine data from raw drug-database text.

Raw name: "$rawName"
Raw dosage: "$rawDosage"

Return ONLY a JSON object with two keys:
- "name": the clean, short brand or generic medicine name (e.g. "Panadol", "Acetaminophen", "Amoxicillin"). Max 4 words. No store brand prefixes like "basic care" or "good sense". No dosage in the name.
- "dosage": just the strength (e.g. "500mg", "250mg/5ml", "10mg"). Empty string if unknown.

Example output: {"name":"Acetaminophen","dosage":"500mg"}

Output JSON only, no explanation.''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 8));

      final text = (response.text ?? '').trim();
      // Strip markdown code fences if present
      final jsonStr = text.replaceAll(RegExp(r'```[a-z]*'), '').replaceAll('```', '').trim();
      final decoded = jsonStr.isNotEmpty
          ? Map<String, dynamic>.from(
              (jsonStr.startsWith('{') ? _parseJson(jsonStr) : null) ?? {})
          : <String, dynamic>{};

      final name = (decoded['name'] as String? ?? '').trim();
      final dosage = (decoded['dosage'] as String? ?? '').trim();

      return {
        'name': name.isNotEmpty ? _capitalize(name) : _capitalize(trimmedName),
        'dosage': dosage.isNotEmpty ? dosage : _extractShortDosage(trimmedDosage),
      };
    } catch (_) {
      return {
        'name': _capitalize(trimmedName),
        'dosage': _extractShortDosage(trimmedDosage),
      };
    }
  }

  static Map<String, dynamic>? _parseJson(String s) {
    try {
      // Simple JSON decode — dart:convert
      // ignore: avoid_dynamic_calls
      final result = <String, dynamic>{};
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(s);
      final dosageMatch = RegExp(r'"dosage"\s*:\s*"([^"]*)"').firstMatch(s);
      if (nameMatch != null) result['name'] = nameMatch.group(1);
      if (dosageMatch != null) result['dosage'] = dosageMatch.group(1);
      return result.isNotEmpty ? result : null;
    } catch (_) {
      return null;
    }
  }

  static String _extractShortDosage(String raw) {
    if (raw.isEmpty) return '';
    // Pull first mg/ml/mcg/g strength from the string
    final match = RegExp(r'\d+\.?\d*\s*(mg|ml|mcg|g|%)', caseSensitive: false)
        .firstMatch(raw);
    if (match != null) return match.group(0)!.trim();
    // If the raw dosage is already short, return it
    if (raw.length <= 15) return raw;
    return '';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}