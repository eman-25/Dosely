import 'package:google_generative_ai/google_generative_ai.dart';
import '../Screens/Main Features/api_key.dart';

class DescriptionSimplifierService {
  /// ✅ ENHANCED - Generate description + personalized dosage based on user health
  /// Requires user's health info (age, weight, conditions, etc)
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
          ? '$medicineName ($genericName)' 
          : medicineName;

      // ✅ ENHANCED PROMPT - Gets description + dosage
      final String prompt = '''You are a helpful health assistant and pharmacist. A patient scanned a medicine.

MEDICINE: $fullName

PATIENT PROFILE:
- Age: ${ageInYears != null ? '$ageInYears years old' : 'Not provided'}
- Weight: ${weightInKg != null ? '${weightInKg.toStringAsFixed(1)} kg' : 'Not provided'}
- Allergies: ${allergies.isEmpty || allergies.toLowerCase() == 'none' ? 'None reported' : allergies}
- Chronic conditions: ${chronicConditions.isEmpty || chronicConditions.toLowerCase() == 'none' ? 'None reported' : chronicConditions}
- Special conditions: ${specialConditions.isEmpty || specialConditions.toLowerCase() == 'none' ? 'None' : specialConditions}

YOUR JOB:
Generate a helpful explanation in 3-4 sentences about:
1. What this medicine TREATS (specific symptoms/conditions)
2. How many tablets/capsules to take PER DOSE (based on age/weight)
3. How many times per day and how many hours apart
4. Important: Take with food or water? Avoid with anything?

RULES:
- Use SIMPLE everyday words, NO medical jargon
- Be SPECIFIC about dosage (e.g. "1-2 tablets every 6 hours")
- Consider age and weight for appropriate dosage
- Mention if food or water is important
- If any special condition applies, mention caution
- NEVER recommend exceeding standard doses
- For children (under 12): suggest lower doses
- For elderly (65+): suggest checking with pharmacist
- Always end with "Ask your pharmacist or doctor if unsure"

GOOD EXAMPLE OUTPUT:
"This medicine helps ease headaches, fevers, and body pain. For adults (12+), take 1-2 tablets every 4-6 hours, maximum 8 tablets per day. Take with water or food to avoid stomach upset. Do not use for more than 3 days without talking to your doctor. Ask your pharmacist or doctor if unsure."

Generate your response:''';

      print('📤 Sending enhanced prompt to Gemini for: $fullName');

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
      return _fallbackDescription(medicineName, genericName, ageInYears, weightInKg);

    } catch (e) {
      print('❌ ERROR: $e');
      return _fallbackDescription(medicineName, genericName, ageInYears, weightInKg);
    }
  }

  /// Enhanced fallback with dosage info
  static String _fallbackDescription(
    String name, 
    String generic,
    int? age,
    double? weight,
  ) {
    // Determine age group
    String ageGroup = 'adult';
    if (age != null) {
      if (age < 12) {
        ageGroup = 'child';
      } else if (age >= 65) {
        ageGroup = 'elderly';
      }
    }

    // Acetaminophen/Paracetamol
    if (generic.toLowerCase().contains('acetaminophen') || 
        generic.toLowerCase().contains('paracetamol')) {
      if (ageGroup == 'child') {
        return 'Helps ease fevers and pain. For children: usually 1/2 to 1 tablet every 4-6 hours. Take with water or milk. Maximum 4 doses per day. Ask your pharmacist for exact dose based on your child\'s weight. Always ask your doctor before giving to children under 2 years.';
      } else if (ageGroup == 'elderly') {
        return 'Helps ease headaches, fevers, and body pain. For elderly adults: typically 1-2 tablets every 4-6 hours, maximum 8 tablets per day. Take with water and food if stomach upset occurs. Check with your pharmacist about interactions with other medicines. Ask your pharmacist or doctor if unsure.';
      } else {
        return 'Helps ease headaches, fevers, and body pain. For adults: take 1-2 tablets every 4-6 hours, maximum 8 tablets per day. Take with water or food. Do not use for more than 3 days without talking to your doctor. Ask your pharmacist or doctor if unsure.';
      }
    }

    // Ibuprofen/Brufen
    if (generic.toLowerCase().contains('ibuprofen') || 
        generic.toLowerCase().contains('brufen')) {
      if (ageGroup == 'child') {
        return 'Helps ease pain and reduce swelling. For children: usually 1/2 to 1 tablet every 6-8 hours. Take with food or milk to protect stomach. Maximum 3-4 doses per day. Ask your pharmacist for exact dose based on weight.';
      } else if (ageGroup == 'elderly') {
        return 'Helps ease pain and reduce inflammation. For elderly: typically 1-2 tablets every 6-8 hours with food. Maximum 6 tablets per day. Always take with food. Check with pharmacist about interactions. Ask your pharmacist or doctor if unsure.';
      } else {
        return 'Helps ease pain and reduce inflammation. For adults: take 1-2 tablets every 6-8 hours with food, maximum 6 tablets per day. ALWAYS take with food or milk to protect your stomach. Ask your pharmacist or doctor if unsure.';
      }
    }

    // Amoxicillin/Augmentin
    if (generic.toLowerCase().contains('amoxicillin') || 
        generic.toLowerCase().contains('augmentin')) {
      if (ageGroup == 'child') {
        return 'Fights bacterial infections. For children: dosage depends on weight - ask your pharmacist. Usually 1 tablet every 8 hours. Take with or without food. Complete the full course even if you feel better. Do not share with others.';
      } else {
        return 'Fights bacterial infections caused by bacteria. For adults: typically 1 tablet every 8 hours or 1-2 tablets every 12 hours. Take with or without food. Complete the full course even if feeling better in 2-3 days. Ask your pharmacist or doctor if unsure.';
      }
    }

    // Aspirin
    if (generic.toLowerCase().contains('aspirin')) {
      if (ageGroup == 'child') {
        return 'Helps ease pain and reduce fever. For children: NOT recommended under 16 years for fever/pain (use paracetamol instead). Ask your pharmacist or doctor.';
      } else if (ageGroup == 'elderly') {
        return 'Helps ease pain and may protect heart. For elderly: typically 1 tablet every 4-6 hours as needed, maximum 8 tablets per day. Always take with food. Check with pharmacist about interactions with blood thinners. Ask your pharmacist or doctor if unsure.';
      } else {
        return 'Helps ease pain and reduce fever. For adults: take 1-2 tablets every 4-6 hours, maximum 8 tablets per day. Take with food or milk. Do not use for more than 10 days without doctor approval. Ask your pharmacist or doctor if unsure.';
      }
    }

    // Default fallback
    return 'Used to treat health conditions. Dosage depends on age and weight. Take as directed on the package or ask your pharmacist for personalized dosage. Always take with water unless otherwise directed.';
  }

  /// Simple fallback (used in case of no user data)
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