import 'package:firebase_ai/firebase_ai.dart';

class PilloChatService {
  static final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3-flash-preview',
  );

  static Future<String> send(
    String message, {
    List<Map<String, String>> previousMessages = const [],
  }) async {
    final String historyText = previousMessages.map((m) {
      final role = m['role'] ?? 'user';
      final content = m['content'] ?? '';
      return '$role: $content';
    }).join('\n');

    final prompt = [
      Content.text('''
You are Pillo, a helpful medicine assistant inside a mobile app.

Rules:
- Answer in simple and clear words.
- Keep answers short unless the user asks for more details.
- Be careful with medicine advice.
- Never say a medicine is 100% safe.
- Always remind the user to ask a doctor or pharmacist for medical decisions.
- If the question is unclear, ask one short follow-up question.

Previous conversation:
$historyText

User: $message
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