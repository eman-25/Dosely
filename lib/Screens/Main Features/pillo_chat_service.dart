import 'package:firebase_ai/firebase_ai.dart';

class PilloChatService {
  static final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-preview-05-20',
  );

  /// [userProfile] is the full health profile loaded from Firestore.
  /// Keys expected (all optional): name, allergies, chronicConditions,
  /// currentMedications, specialConditions, uid, username, lastUpdatedAt.
  static Future<String> send(
    String message, {
    List<Map<String, String>> previousMessages = const [],
    Map<String, String> memory = const {},
    Map<String, dynamic> userProfile = const {},
    bool hasImage = false,
  }) async {
    // ── Trim history ────────────────────────────────────────────────────────────
    final trimmedHistory = previousMessages.length > 12
        ? previousMessages.sublist(previousMessages.length - 12)
        : previousMessages;

    final historyText = trimmedHistory
        .map((m) {
          final role = (m['role'] ?? 'user').trim();
          final content = (m['content'] ?? '').trim();
          return '$role: $content';
        })
        .where((line) => line.trim().isNotEmpty)
        .join('\n');

    // ── Build health profile block from Firestore data ──────────────────────────
    final profileLines = <String>[];

    void addIfPresent(String label, String key) {
      final val = userProfile[key]?.toString().trim() ?? '';
      if (val.isNotEmpty && val.toLowerCase() != 'none') {
        profileLines.add('- $label: $val');
      }
    }

    final username = userProfile['username']?.toString().trim() ??
        userProfile['name']?.toString().trim() ??
        '';
    if (username.isNotEmpty) profileLines.add('- Name: $username');

    addIfPresent('Allergies', 'allergies');
    addIfPresent('Chronic conditions', 'chronicConditions');
    addIfPresent('Current medications', 'currentMedications');
    addIfPresent('Special conditions', 'specialConditions');

    final profileText = profileLines.isEmpty
        ? '- No health profile available yet.'
        : profileLines.join('\n');

    // ── Build in-chat memory block ───────────────────────────────────────────────
    final memoryText = memory.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');

    // ── Compose prompt ───────────────────────────────────────────────────────────
    final prompt = [
      Content.text('''
You are Pillo, a smart and caring medicine assistant inside a mobile health app.

════════════════════════════════════════
USER HEALTH PROFILE (from their account)
════════════════════════════════════════
$profileText

════════════════════════════════════════
ADDITIONAL MEMORY (from this chat session)
════════════════════════════════════════
${memoryText.isEmpty ? '- none yet' : memoryText}

════════════════════════════════════════
YOUR BEHAVIOUR RULES
════════════════════════════════════════
1. ALWAYS use the health profile above when giving advice. This is the most important context.
2. Proactively warn the user if:
   - A medicine they mention conflicts with their known allergies.
   - A medicine is risky given their chronic condition (e.g. NSAIDs + hypertension, ibuprofen allergy conflicts).
   - A medicine is unsafe during pregnancy if specialConditions includes "Pregnant".
   - A medicine interacts badly with their current medications.
3. Give personalised advice, not generic advice. Example: do not say "consult your doctor about NSAIDs" — say "Given your hypertension, NSAIDs like ibuprofen can raise blood pressure further, so you should ask your doctor for a safer alternative."
4. If the user asks about a medicine and their profile has relevant info, always mention how it relates to them specifically.
5. Keep answers clear and conversational. Use short paragraphs. Avoid jargon unless the user uses it first.
6. Never guarantee a medicine is 100% safe for anyone.
7. Always end important advice with a reminder to confirm with a doctor or pharmacist.
8. Do not ignore previous conversation context.
9. If an image is attached but no text was extracted, acknowledge it and ask what they need help with regarding it.
10. Address the user by their name (${username.isEmpty ? 'their name if known' : username}) when it feels natural.

════════════════════════════════════════
PREVIOUS CONVERSATION
════════════════════════════════════════
${historyText.isEmpty ? 'No previous conversation.' : historyText}

════════════════════════════════════════
CURRENT USER MESSAGE
════════════════════════════════════════
$message

Attached image: ${hasImage ? 'Yes — the user has uploaded an image.' : 'No'}
''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        return 'Sorry, I got an empty reply. Please try again.';
      }

      return text.trim();
    } catch (e) {
      return 'Pillo error: $e';
    }
  }
}