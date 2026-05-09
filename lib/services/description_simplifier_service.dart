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

      // ✅ SMART PROMPT - Focuses on WHAT it does, not HOW to take it
      final String prompt = '''You are a friendly health educator and pharmacist. A patient scanned a medicine and wants to understand what it does.

MEDICINE: $fullName

PATIENT PROFILE:
- Age: ${ageInYears != null ? '$ageInYears years old' : 'Not provided'}
- Weight: ${weightInKg != null ? '${weightInKg.toStringAsFixed(1)} kg' : 'Not provided'}
- Known allergies: ${allergies.isEmpty || allergies.toLowerCase() == 'none' ? 'None reported' : allergies}
- Chronic health conditions: ${chronicConditions.isEmpty || chronicConditions.toLowerCase() == 'none' ? 'None reported' : chronicConditions}
- Special conditions: ${specialConditions.isEmpty || specialConditions.toLowerCase() == 'none' ? 'None' : specialConditions}

YOUR JOB - Generate a simple, friendly explanation (2-3 sentences) about:
1. What health problem(s) this medicine helps with
2. How it works in the body (in very simple terms)
3. Any important special notes for THIS PATIENT based on their profile

IMPORTANT RULES:
✅ DO:
- Use VERY simple everyday language (explain like talking to a 10-year-old)
- Be SPECIFIC about what conditions it treats (e.g., "helps lower blood pressure")
- Mention if it's safe for the patient's age/situation
- Note any special cautions relevant to THEIR health conditions
- Be encouraging and reassuring

❌ DON'T:
- Mention ANY dosage, frequency, or how many tablets
- Suggest when/how to take it (with food, etc.)
- Recommend exact doses for any age/weight
- Give medical advice or tell them to skip doctor
- Include anything the doctor/pharmacist should tell them

GOOD EXAMPLES:
"This medicine helps ease fevers and body pain by reducing inflammation in your body. It works quickly and is generally safe for adults. Since you have a history of stomach sensitivity, mention that to your pharmacist."

"This blood pressure medicine helps your heart pump more efficiently, bringing your blood pressure down. It's especially safe for people with your age and health profile. Take it exactly as your doctor prescribed."

"This antibiotic fights bacterial infections by stopping bacteria from growing. It's safe for children your age. Make sure to complete the full course even if you feel better."

NOW generate the explanation for $fullName:''';

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