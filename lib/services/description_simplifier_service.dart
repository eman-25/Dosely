import 'package:google_generative_ai/google_generative_ai.dart';
import '../Screens/Main Features/api_key.dart'; // Your real API key

class DescriptionSimplifierService {
  // Static instance of Gemini model (reuse for efficiency)
  static late final GenerativeModel _model;
  static bool _initialized = false;

  /// Initialize the Gemini model once (call this in main.dart or app startup)
  static void initialize() {
    if (_initialized) return;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey, // Your real API key from api_key.dart
    );
    _initialized = true;
  }

  /// ✅ REAL CALL TO GEMINI - Generates simple explanation of what medicine treats
  /// Example: "Panadol" → Gemini returns → "Helps ease headaches, fevers, and body pain"
  static Future<String> generateSimpleExplanation({
    required String medicineName,
    required String genericName,
  }) async {
    try {
      // Ensure model is initialized
      if (!_initialized) initialize();

      final fullName = genericName.isNotEmpty 
          ? '$medicineName ($genericName)' 
          : medicineName;

      // THIS IS THE REAL PROMPT SENT TO GEMINI
      final prompt = '''You are a helpful health assistant. A user scanned a medicine package.

Medicine name: $fullName

Your job: Write ONE SHORT sentence (max 15 words) explaining what this medicine TREATS or HELPS WITH. Use simple everyday words. NO medical jargon.

Examples of good answers:
- "Helps ease headaches, fevers, and body pain"
- "Fights bacterial infections"  
- "Relieves cold and cough symptoms"
- "Helps with allergies and itching"

Generate just the answer, nothing else:''';

      // ✅ ACTUAL API CALL TO GEMINI
      final response = await _model.generateContent([
        Content.text(prompt)
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Gemini API timeout'),
      );

      // Extract the response text
      final text = response.text?.trim() ?? '';

      print('✅ Gemini Response: $text'); // Debug log

      if (text.isNotEmpty && text.length > 5) {
        return text;
      }
    } catch (e) {
      // Log the actual error
      print('❌ Gemini API Error: $e');
    }

    // Fallback only if Gemini fails
    return _buildFallbackDescription(medicineName, genericName);
  }

  /// Fallback when API fails
  static String _buildFallbackDescription(String name, String generic) {
    if (generic.isNotEmpty) {
      return 'Used to help treat health conditions.';
    }
    return 'A medicine to help with your health.';
  }
}