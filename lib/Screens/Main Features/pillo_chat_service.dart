import 'package:firebase_ai/firebase_ai.dart';

class PilloChatService {
  static final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3-flash-preview',
  );

  static Future<String> send(
    String message, {
    List<Map<String, String>> previousMessages = const [],
    Map<String, String> memory = const {},
    bool hasImage = false,
  }) async {
    final trimmedHistory = previousMessages.length > 12
        ? previousMessages.sublist(previousMessages.length - 12)
        : previousMessages;

    final historyText = trimmedHistory.map((m) {
      final role = (m['role'] ?? 'user').trim();
      final content = (m['content'] ?? '').trim();
      return '$role: $content';
    }).where((line) => line.trim().isNotEmpty).join('\n');

    final memoryText = memory.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');

    final prompt = [
      Content.text('''
You are Pillo, a helpful medicine assistant inside a mobile app.

Your job:
- Remember the conversation and answer based on what was said before.
- Use the saved user memory when it is relevant.
- Answer in simple and clear words.
- Keep answers short unless the user asks for more details.
- Be careful with medicine advice.
- Never say a medicine is 100% safe.
- Do not ignore the previous conversation.
- If the user uploads an image, mention that an image was attached, but only answer based on text unless the app sends extracted image text too.
- Always remind the user to ask a doctor or pharmacist for important medical decisions.

Saved user memory:
${memoryText.isEmpty ? '- none yet' : memoryText}

Previous conversation:
${historyText.isEmpty ? 'No previous conversation.' : historyText}

Current user message:
$message

Attached image:
${hasImage ? 'Yes' : 'No'}
''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        return 'Sorry, I got an empty reply.';
      }

      return text.trim();
    } catch (e) {
      return 'Firebase AI error:\n$e';
    }
  }
}