import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Screens/Main Features/api_key.dart';

// ── Return type ───────────────────────────────────────────────────────────────
class PilloResponse {
  final String text;

  /// Non-null when Pillo recommends a specific medicine the user can schedule.
  final Map<String, String>? suggestedMedicine;

  const PilloResponse(this.text, {this.suggestedMedicine});
}

class PilloChatService {
  static final _firestore = FirebaseFirestore.instance;

  // ── Load user context ─────────────────────────────────────────────────────
  static Future<PilloContext> loadUserContext(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userProfile = userDoc.data() ?? {};

      final scansSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scan_results')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return PilloContext(
        userProfile: userProfile,
        scanHistory: scansSnap.docs.map((d) => d.data()).toList(),
        memory: {},
      );
    } catch (_) {
      return const PilloContext();
    }
  }

  // ── Send message to Gemini ────────────────────────────────────────────────
  static Future<PilloResponse> send(
    String message, {
    List<Map<String, String>> previousMessages = const [],
    Map<String, dynamic> userProfile = const {},
    List<Map<String, dynamic>> scanHistory = const [],
    bool hasImage = false,
    String? ocrResultText, // OCR scan result from an uploaded image
  }) async {
    final trimmedHistory = previousMessages.length > 10
        ? previousMessages.sublist(previousMessages.length - 10)
        : previousMessages;

    final historyText = trimmedHistory
        .map((m) => '${(m['role'] ?? 'user').trim()}: ${(m['content'] ?? '').trim()}')
        .where((l) => l.trim().isNotEmpty)
        .join('\n');

    // ── User profile ──────────────────────────────────────────────────────
    final health   = userProfile['healthInfo'] as Map<String, dynamic>? ?? {};
    final username = (userProfile['username'] ?? userProfile['name'] ?? '').toString().trim();
    final dob      = (userProfile['dob'] ?? '').toString().trim();
    final gender   = (userProfile['gender'] ?? '').toString().trim();

    String age = '';
    if (dob.isNotEmpty) {
      try {
        final born = DateTime.parse(dob);
        age = '${DateTime.now().difference(born).inDays ~/ 365} years old';
      } catch (_) {}
    }

    String hv(String key) => (health[key] ?? '').toString().trim();

    final profileLines = <String>[];
    if (username.isNotEmpty) profileLines.add('- Name: $username');
    if (age.isNotEmpty)      profileLines.add('- Age: $age');
    if (gender.isNotEmpty)   profileLines.add('- Gender: $gender');
    final allergies = hv('allergies');
    final chronic   = hv('chronicConditions');
    final special   = hv('specialConditions');
    if (allergies.isNotEmpty && allergies.toLowerCase() != 'none') {
      profileLines.add('- ALLERGIES: $allergies');
    }
    if (chronic.isNotEmpty && chronic.toLowerCase() != 'none') {
      profileLines.add('- Chronic conditions: $chronic');
    }
    if (special.isNotEmpty && special.toLowerCase() != 'none') {
      profileLines.add('- Special conditions: $special');
    }
    final profileText = profileLines.isEmpty ? '- No profile data.' : profileLines.join('\n');

    // ── Scan history ──────────────────────────────────────────────────────
    String scanText = '- No medicines scanned yet.';
    if (scanHistory.isNotEmpty) {
      final lines = scanHistory.map((s) {
        final name    = s['medicineName'] ?? '';
        final generic = s['genericName'] ?? '';
        final dosage  = s['dosage'] ?? '';
        final status  = s['status'] ?? '';
        final reasons = (s['reasons'] as List?)?.join(', ') ?? '';
        return '- $name ($generic) | $dosage | status: $status${reasons.isNotEmpty ? " | $reasons" : ""}';
      });
      scanText = lines.join('\n');
    }

    // ── OCR context ───────────────────────────────────────────────────────
    final ocrSection = ocrResultText != null && ocrResultText.isNotEmpty
        ? '\nSCANNED MEDICINE FROM IMAGE:\n$ocrResultText\n'
        : '';

    // ── System prompt ─────────────────────────────────────────────────────
    final promptText = '''You are Pillo 🌿, a warm and caring medicine companion in a health app.
You're like a knowledgeable friend — reassuring, clear, and never overwhelming.
Always personalise to this patient. Keep responses concise and uplifting.

PATIENT PROFILE:
$profileText

PATIENT SCAN HISTORY:
$scanText
$ocrSection
RULES:
1. Cross-check every medicine against the patient's allergies, conditions, age, gender.
2. When recommending, prefer options from their scan history and explain why.
3. Warn clearly (⚠️) for any conflict with allergies, conditions, or other meds.
4. If pregnant: apply strict pregnancy safety. If hypertension: warn about NSAIDs.
5. Never say a medicine is 100% safe.
6. Be warm and encouraging — the patient should feel supported, not scared.

RESPONSE FORMAT for medicine questions (keep it short and friendly):
✅ [medicine name] — [why it suits THIS patient, 1 sentence]

💊 How to take it:
• [dose, strength, frequency, duration — all in 1-2 bullet points]
• Take with: [water/food]

⏱ Kicks in: [e.g. 30–60 min]
🚫 Avoid: [key interactions, brief]
⚠️ Watch out: [only if specific risk for THIS patient]
🩺 Always double-check with your doctor or pharmacist. You've got this! 💙

IMPORTANT: If you recommend a specific medicine, append this EXACT line at the very end (no text after it):
MEDICINE_SUGGEST:MedicineName|GenericName|Dosage

Example: MEDICINE_SUGGEST:Panadol|Acetaminophen|500mg

For simple conversational questions: reply in 1-3 warm, friendly sentences only.

CONVERSATION SO FAR:
${historyText.isEmpty ? 'None.' : historyText}

PATIENT SAYS:
$message${hasImage && ocrResultText == null ? '\n[Patient attached an image — described above if scanned]' : ''}
''';

    const modelsToTry = [
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-1.5-flash',
    ];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(promptText)]);
        final raw = response.text;
        if (raw != null && raw.trim().isNotEmpty) {
          return _parseResponse(raw.trim());
        }
      } catch (e) {
        final err = e.toString().toLowerCase();
        final isTemporary = err.contains('quota') ||
            err.contains('429') ||
            err.contains('resource exhausted') ||
            err.contains('overloaded') ||
            err.contains('503') ||
            err.contains('unavailable');
        if (!isTemporary) return PilloResponse('Pillo error: $e');
      }
    }

    return const PilloResponse(
        'Pillo is very busy right now. Please try again in a moment.');
  }

  // ── Parse MEDICINE_SUGGEST marker from response ───────────────────────────
  static PilloResponse _parseResponse(String raw) {
    const marker = 'MEDICINE_SUGGEST:';
    final idx = raw.lastIndexOf(marker);
    if (idx == -1) return PilloResponse(raw);

    final text       = raw.substring(0, idx).trim();
    final suggestion = raw.substring(idx + marker.length).trim();
    final parts      = suggestion.split('|');

    final name    = parts.isNotEmpty ? parts[0].trim() : '';
    final generic = parts.length > 1 ? parts[1].trim() : '';
    final dosage  = parts.length > 2 ? parts[2].trim() : '';

    if (name.isEmpty) return PilloResponse(text);

    return PilloResponse(
      text,
      suggestedMedicine: {
        'name':         name,
        'generic_name': generic,
        'dosage':       dosage,
      },
    );
  }
}

// ── Context model ─────────────────────────────────────────────────────────────
class PilloContext {
  final Map<String, dynamic> userProfile;
  final List<Map<String, dynamic>> scanHistory;
  final Map<String, String> memory;

  const PilloContext({
    this.userProfile = const {},
    this.scanHistory = const [],
    this.memory = const {},
  });
}
