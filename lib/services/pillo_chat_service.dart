import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Screens/Main Features/api_key.dart'; // your const apiKey = 'YOUR_KEY';

class PilloChatService {
  static final _firestore = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // Load user context (profile + scan history) from Firestore
  // Called on app init to populate Pillo's context
  // ──────────────────────────────────────────────────────────────────────────
  static Future<PilloContext> loadUserContext(String uid) async {
    try {
      // Fetch user profile document
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userProfile = userDoc.data() ?? {};

      // Fetch scan history (last 10 scans)
      final scansSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scan_results')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final scanHistory = scansSnap.docs
          .map((doc) => doc.data())
          .toList();

      return PilloContext(
        userProfile: userProfile,
        scanHistory: scanHistory,
        memory: {},
      );
    } catch (e) {
      // Return empty context on error — app will still work
      print('⚠️ Error loading user context: $e');
      return const PilloContext();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Send message to Gemini with patient context
  // ──────────────────────────────────────────────────────────────────────────
  static Future<String> send(
    String message, {
    List<Map<String, String>> previousMessages = const [],
    Map<String, dynamic> userProfile = const {},
    List<Map<String, dynamic>> scanHistory = const [],
    bool hasImage = false,
  }) async {
    // ── Trim conversation history to last 10 messages ──────────────────────
    final trimmedHistory = previousMessages.length > 10
        ? previousMessages.sublist(previousMessages.length - 10)
        : previousMessages;

    final historyText = trimmedHistory
        .map((m) => '${(m['role'] ?? 'user').trim()}: ${(m['content'] ?? '').trim()}')
        .where((l) => l.trim().isNotEmpty)
        .join('\n');

    // ── Extract and format user profile ────────────────────────────────────
    final health = userProfile['healthInfo'] as Map<String, dynamic>? ?? {};
    final username = (userProfile['username'] ?? userProfile['name'] ?? '').toString().trim();
    final dob      = (userProfile['dob'] ?? '').toString().trim();
    final gender   = (userProfile['gender'] ?? '').toString().trim();

    // Calculate age from DOB
    String age = '';
    if (dob.isNotEmpty) {
      try {
        final born = DateTime.parse(dob);
        age = '${DateTime.now().difference(born).inDays ~/ 365} years old';
      } catch (_) {}
    }

    String healthVal(String key) => (health[key] ?? '').toString().trim();

    final allergies         = healthVal('allergies');
    final chronicConditions = healthVal('chronicConditions');
    final currentMeds       = healthVal('currentMedications');
    final specialConditions = healthVal('specialConditions');

    // Build profile section for Pillo
    final profileLines = <String>[];
    if (username.isNotEmpty) profileLines.add('- Name: $username');
    if (age.isNotEmpty)      profileLines.add('- Age: $age');
    if (gender.isNotEmpty)   profileLines.add('- Gender: $gender');
    if (allergies.isNotEmpty && allergies.toLowerCase() != 'none')
      profileLines.add('- ALLERGIES: $allergies');
    if (chronicConditions.isNotEmpty && chronicConditions.toLowerCase() != 'none')
      profileLines.add('- Chronic conditions: $chronicConditions');
    if (currentMeds.isNotEmpty && currentMeds.toLowerCase() != 'none')
      profileLines.add('- Current medications: $currentMeds');
    if (specialConditions.isNotEmpty && specialConditions.toLowerCase() != 'none')
      profileLines.add('- Special conditions: $specialConditions');
    
    final profileText = profileLines.isEmpty ? '- No profile data yet.' : profileLines.join('\n');

    // ── Build scanned medicines section ────────────────────────────────────
    String scanText = '- No medicines scanned yet.';
    if (scanHistory.isNotEmpty) {
      final lines = <String>[];
      for (final s in scanHistory) {
        final name    = (s['medicineName'] ?? '').toString();
        final generic = (s['genericName'] ?? '').toString();
        final dosage  = (s['dosage'] ?? '').toString();
        final status  = (s['status'] ?? '').toString();
        final score   = (s['score']?.toString() ?? '');
        final reasons = (s['reasons'] as List?)?.map((r) => r.toString()).join(', ') ?? '';
        final matched = (s['matchedDosages'] as List?)?.map((d) => d.toString()).join(', ') ?? '';
        
        lines.add(
          '- $name ($generic) | dosage: $dosage | matched dosages: $matched'
          ' | status: $status | safety score: $score'
          '${reasons.isNotEmpty ? " | notes: $reasons" : ""}',
        );
      }
      scanText = lines.join('\n');
    }

    // ── Compose the system prompt for Pillo ────────────────────────────────
    final promptText = '''
You are Pillo, a clinical medicine assistant in a mobile health app.
You reason like an experienced doctor — thorough, caring, and specific to this patient.

PATIENT PROFILE:
$profileText

PATIENT SCANNED MEDICINES (their personal medicine history):
$scanText

CLINICAL RULES:
1. Always cross-check any medicine against the patient's allergies, conditions, age, gender, and special conditions.
2. When recommending, pick the BEST option from their scanned history if relevant, explain why it fits them personally.
3. ALWAYS specify: how many TABLETS/CAPSULES per dose (e.g. '1 tablet', '2 tablets'), the strength per tablet (mg), how many times per day, hours apart, and for how many days. Use the matchedDosages from their scan history to determine the right tablet count.
4. ALWAYS mention what to take it with (food, water, milk) and what to avoid (alcohol, other drugs, foods).
5. Warn clearly (with ⚠️) if a medicine conflicts with their allergies, conditions, or other medications.
6. If pregnant: apply strict pregnancy safety rules — flag anything unsafe.
7. If hypertension: warn about NSAIDs, decongestants, high-sodium drugs.
8. Mention how long until the medicine starts working.
9. Mention what to do if they miss a dose.
10. Never say a medicine is 100% safe.

RESPONSE FORMAT — USE THIS EXACT STRUCTURE FOR MEDICINE QUESTIONS:
✅ Best option: [medicine name] — [why it suits THIS patient specifically]

💊 Dosage:
• Tablets: [e.g. 1 tablet / 2 tablets per dose]
• Strength: [e.g. 500mg per tablet]
• Frequency: [e.g. every 6–8 hours, max 4 tablets/day]
• Duration: [e.g. 3–5 days, or as needed]
• Take with: [e.g. a full glass of water, with food]

⏱ Works in: [e.g. 30–60 minutes]

🚫 Avoid: [alcohol / specific foods / other medicines that interact]

⚠️ Watch out: [specific risk for THIS patient based on their profile, or "No major concerns for your profile"]

📋 If you miss a dose: [what to do]

🩺 Always confirm with your doctor or pharmacist before use.

For simple conversational questions (greetings, non-medicine topics): reply in 1-3 friendly sentences only, no format needed.

CONVERSATION SO FAR:
${historyText.isEmpty ? 'None.' : historyText}

PATIENT SAYS:
$message${hasImage ? '\n[Patient attached an image]' : ''}
''';

    // ── Try multiple models with graceful fallback ──────────────────────────
    const modelsToTry = [
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-1.5-flash',
    ];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );
        final response = await model.generateContent([Content.text(promptText)]);
        final text = response.text;
        if (text != null && text.trim().isNotEmpty) return text.trim();
      } catch (e) {
        final err = e.toString().toLowerCase();
        
        // Check if it's a quota/rate limit error (temporary)
        final isQuotaOrBusy = err.contains('quota') ||
            err.contains('429') ||
            err.contains('resource exhausted') ||
            err.contains('overloaded') ||
            err.contains('503') ||
            err.contains('unavailable');
        
        // If it's not temporary, report immediately instead of trying next model
        if (!isQuotaOrBusy) {
          return 'Pillo error: $e';
        }
        // Otherwise try next model
      }
    }

    // All models failed due to quota
    return 'Pillo is very busy right now. Please try again in a moment.';
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Data model: Holds user context for Pillo
// ──────────────────────────────────────────────────────────────────────────

class PilloContext {
  final Map<String, dynamic> userProfile;
  final List<Map<String, dynamic>> scanHistory;
  final Map<String, String> memory;

  const PilloContext({
    this.userProfile = const {},
    this.scanHistory = const [],
    this.memory = const {},
  });

  factory PilloContext.fromFirestore({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> scans,
  }) {
    return PilloContext(
      userProfile: userData,
      scanHistory: scans,
      memory: {},
    );
  }
}