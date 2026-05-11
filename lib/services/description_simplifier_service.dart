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

Write 2–3 plain sentences about what this medicine does and how it helps the patient. Use simple everyday language.

Rules:
- Start DIRECTLY with the medicine's purpose — no greeting, no "Hello", no "I", no introduction
- Focus only on what health problem it treats and how it works in the body
- Add one note relevant to this patient's profile if applicable
- Never mention dosage, frequency, or how to take it
- Never say "consult a doctor" or give medical advice

Output the sentences only, nothing else.''';

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
      String warning = '';
      if (chronicConditions.toLowerCase().contains('liver')) {
        warning = ' Important: Tell your doctor about your liver condition before taking this.';
      }
      return 'This medicine helps ease fevers and body aches by reducing pain signals in your brain. It works gently and is safe for most ages.$warning Ask your pharmacist if you have any health concerns.';
    }

    if (lower.contains('ibuprofen') || lower.contains('brufen')) {
      String warning = '';
      if (chronicConditions.toLowerCase().contains('stomach') || 
          chronicConditions.toLowerCase().contains('ulcer')) {
        warning = ' ⚠️ Since you have a history of stomach issues, talk to your doctor about whether this is safe for you.';
      }
      return 'This medicine reduces pain, swelling, and fever by blocking inflammation in your body. It works well for headaches, muscle aches, and period pain.$warning Take it with food or milk to protect your stomach.';
    }

    if (lower.contains('aspirin')) {
      String warning = '';
      if (allergies.toLowerCase().contains('aspirin')) {
        warning = ' ⚠️ You may have an aspirin allergy — check with your pharmacist.';
      }
      return 'This medicine helps ease pain and can reduce fever. It also helps prevent blood clots, so some people take it for heart health.$warning Always take it with food.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ANTIBIOTICS
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('amoxicillin') || lower.contains('augmentin')) {
      return 'This is an antibiotic that kills bacteria causing infections like ear infections, throat infections, and pneumonia. It\'s been used safely for decades. Always take the complete course even if you feel better after 2-3 days.';
    }

    if (lower.contains('azithromycin') || lower.contains('zithromax')) {
      return 'This antibiotic fights bacterial infections by stopping bacteria from multiplying. It\'s used for chest infections, throat infections, and other bacterial diseases. Complete the full treatment even if you feel better.';
    }

    if (lower.contains('ciprofloxacin') || lower.contains('cipro')) {
      return 'This is a strong antibiotic for serious bacterial infections. It works by preventing bacteria from making DNA, so they die. It\'s commonly used for urinary and respiratory infections.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BLOOD PRESSURE & HEART
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('bisoprol') || lower.contains('concor')) {
      return 'This medicine helps lower blood pressure and makes your heart work more efficiently by slowing your heart rate. It\'s especially helpful for people with heart disease. It helps prevent heart attacks and strokes.';
    }

    if (lower.contains('amlodipine') || lower.contains('norvasc')) {
      return 'This blood pressure medicine relaxes blood vessels, allowing blood to flow easier. This lowers your blood pressure and reduces the workload on your heart. It\'s safe to take for years.';
    }

    if (lower.contains('losartan') || lower.contains('cozaar')) {
      return 'This medicine helps lower blood pressure by relaxing blood vessels. It\'s particularly helpful if you have kidney disease or diabetes. Taking it regularly prevents heart attacks and strokes.';
    }

    if (lower.contains('atorvastatin') || lower.contains('lipitor')) {
      return 'This medicine helps lower cholesterol by reducing the amount your body makes. High cholesterol can block arteries, so this medicine protects your heart and blood vessels. Many people take it every day for years.';
    }

    if (lower.contains('furosemide') || lower.contains('lasix')) {
      return 'This water pill helps remove extra salt and water from your body through urine. It\'s used for heart failure, high blood pressure, and swelling. It reduces the workload on your heart.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STOMACH & DIGESTION
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('omeprazole') || lower.contains('losec')) {
      return 'This medicine reduces stomach acid, helping heal ulcers and acid reflux. It works by blocking the cells that make acid. Many people take it regularly for chronic heartburn.';
    }

    if (lower.contains('esomeprazole') || lower.contains('nexium')) {
      return 'This medicine reduces stomach acid to help with acid reflux, heartburn, and ulcers. It\'s very effective and safe for long-term use. Take it before meals for best results.';
    }

    if (lower.contains('metronidazole') || lower.contains('flagyl')) {
      return 'This antibiotic fights infections caused by parasites and certain bacteria. It\'s commonly used for stomach infections and traveler\'s diarrhea. Complete the full course to avoid the infection returning.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RESPIRATORY
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('salbutamol') || lower.contains('ventolin')) {
      return 'This "rescue" inhaler quickly opens your airways during asthma attacks or when you\'re short of breath. It works within minutes by relaxing the muscles around your airways. Keep it with you when you might need it.';
    }

    if (lower.contains('montelukast') || lower.contains('singulair')) {
      return 'This medicine prevents asthma attacks by reducing inflammation in your airways. It also helps with allergies. Take it regularly even when you feel fine to keep attacks from happening.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ALLERGIES
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('cetirizine') || lower.contains('zyrtec')) {
      return 'This antihistamine stops your body\'s allergic reactions to pollen, dust, and pet dander. It reduces sneezing, itching, and watery eyes. It\'s non-drowsy and safe for regular use.';
    }

    if (lower.contains('loratadine') || lower.contains('claritin')) {
      return 'This allergy medicine blocks histamine, which causes sneezing, itching, and runny nose. It\'s gentle and non-drowsy, so you can take it anytime. Works best when taken every day during allergy season.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DIABETES
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('metformin') || lower.contains('glucophage')) {
      return 'This medicine helps control blood sugar by reducing how much sugar your body makes and improving how it uses insulin. It\'s the first medicine doctors try for type 2 diabetes. It helps prevent diabetes complications.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // THYROID
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('levothyroxine') || lower.contains('eltroxin') || lower.contains('euthyrox')) {
      return 'This replaces thyroid hormone your body isn\'t making enough of. Without thyroid hormone, your metabolism slows down and you feel tired. This medicine helps you feel energetic and normal again.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MENTAL HEALTH
    // ═══════════════════════════════════════════════════════════════════════
    if (lower.contains('alprazolam') || lower.contains('xanax')) {
      return 'This medicine reduces anxiety by calming your nervous system. It\'s used for anxiety disorders and panic attacks. Work with your doctor for safe use, as dependence is possible with long-term use.';
    }

    if (lower.contains('escitalopram') || lower.contains('cipralex')) {
      return 'This medicine helps depression and anxiety by balancing chemicals in your brain. It takes 2-4 weeks to feel better, so be patient. It\'s one of the safest antidepressants and very effective.';
    }

    if (lower.contains('sertraline') || lower.contains('zoloft')) {
      return 'This antidepressant helps with depression, anxiety, and panic disorder by balancing brain chemicals. Most people feel better after 4-6 weeks. It\'s well-tolerated and has few side effects.';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DEFAULT FALLBACK
    // ═══════════════════════════════════════════════════════════════════════
    return 'This medicine is used to treat health conditions and is available in many countries. To understand exactly what it does and how to take it safely, talk to your pharmacist or doctor who knows your full health history.';
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