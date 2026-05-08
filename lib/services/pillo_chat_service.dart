// ============================================================
//  pillo_chat_service.dart
//
//  Pillo — personalised medicine AI assistant powered by Gemini.
//
//  What changed from the original:
//
//  1. loadUserContext() — reads the user's full health profile,
//     scheduled medicines, and last scan result from Firestore.
//     This replaces the shallow manual memory extraction.
//
//  2. send() — now accepts a PilloContext object. The system
//     prompt is rebuilt on every call with live, structured data
//     so Pillo always has accurate, up-to-date information.
//
//  3. The system prompt is structured in clearly labelled sections
//     so Gemini never confuses profile data with conversation history.
//
//  4. Safety guardrails are enforced in the prompt: Pillo never
//     overrides the scan engine result, never claims 100% safety,
//     and always defers serious decisions to a pharmacist/doctor.
//
//  Nothing in PillAssistantHome.dart needs to change except calling
//  loadUserContext() before the first send() and passing the context.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

// ── Context object — holds everything loaded from Firestore ──────────────────
class PilloContext {
  final String name;
  final String allergies;
  final String chronicConditions;
  final String currentMedications;
  final String specialConditions;
  final String gender;
  final String dob;
  final List<String> scheduledMedicines; // from medicine_table sub-collection
  final Map<String, dynamic>? lastScanResult; // last scan_results document

  const PilloContext({
    this.name = '',
    this.allergies = '',
    this.chronicConditions = '',
    this.currentMedications = '',
    this.specialConditions = '',
    this.gender = '',
    this.dob = '',
    this.scheduledMedicines = const [],
    this.lastScanResult,
  });

  bool get isEmpty =>
      name.isEmpty &&
      allergies.isEmpty &&
      currentMedications.isEmpty &&
      scheduledMedicines.isEmpty;
}

// ── Service ───────────────────────────────────────────────────────────────────
class PilloChatService {
  static final _db = FirebaseFirestore.instance;

  static final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-1.5-flash',   // free tier available; 2.0-flash requires billing
  );

  // =========================================================================
  //  CONTEXT LOADER
  //  Call this once when PillAssistantHome opens (or when user logs in).
  //  Pass the result into every subsequent send() call.
  // =========================================================================
  static Future<PilloContext> loadUserContext(String uid) async {
    try {
      // ── 1. User root document (profile + health info) ──────────────────
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return const PilloContext();

      final raw = userDoc.data() ?? {};
      final health = Map<String, dynamic>.from(raw['healthInfo'] ?? {});

      // ── 2. Scheduled medicines ─────────────────────────────────────────
      final tableSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('medicine_table')
          .get();

      final scheduled = <String>[];
      for (final doc in tableSnap.docs) {
        final d = doc.data();
        final name = d['medicineName']?.toString().trim() ?? '';
        final generic = d['genericName']?.toString().trim() ?? '';
        final dose = d['dosage']?.toString().trim() ?? '';
        final freq = d['frequency']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          final entry = [
            name,
            if (generic.isNotEmpty && generic != name) '($generic)',
            if (dose.isNotEmpty) dose,
            if (freq.isNotEmpty) '— $freq',
          ].join(' ');
          scheduled.add(entry);
        }
      }

      // ── 3. Most recent scan result ─────────────────────────────────────
      final scanSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('scan_results')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      Map<String, dynamic>? lastScan;
      if (scanSnap.docs.isNotEmpty) {
        lastScan = scanSnap.docs.first.data();
      }

      return PilloContext(
        name:               raw['username']?.toString() ?? '',
        gender:             raw['gender']?.toString() ?? '',
        dob:                raw['dob']?.toString() ?? '',
        allergies:          health['allergies']?.toString() ?? '',
        chronicConditions:  health['chronicConditions']?.toString() ?? '',
        currentMedications: health['currentMedications']?.toString() ?? '',
        specialConditions:  health['specialConditions']?.toString() ?? '',
        scheduledMedicines: scheduled,
        lastScanResult:     lastScan,
      );
    } catch (e) {
      // Network error — return empty context, Pillo will still work
      return const PilloContext();
    }
  }

  // =========================================================================
  //  SEND
  //  Builds a fully-structured prompt and calls Gemini.
  // =========================================================================
  static Future<String> send(
    String message, {
    List<Map<String, String>> previousMessages = const [],
    PilloContext context = const PilloContext(),
    bool hasImage = false,
  }) async {
    // Trim history to last 14 messages to stay within token budget
    final trimmedHistory = previousMessages.length > 14
        ? previousMessages.sublist(previousMessages.length - 14)
        : previousMessages;

    final historyText = trimmedHistory
        .map((m) {
          final role = (m['role'] ?? 'user').trim();
          final content = (m['content'] ?? '').trim();
          return '$role: $content';
        })
        .where((line) => line.isNotEmpty)
        .join('\n');

    // ── Build system prompt ────────────────────────────────────────────────
    final systemPrompt = _buildSystemPrompt(context);

    // ── Build last-scan section ────────────────────────────────────────────
    final scanSection = _buildScanSection(context.lastScanResult);

    final prompt = [
      Content.text('''
$systemPrompt

════════════════════════════════════════
LAST MEDICINE SCAN RESULT
════════════════════════════════════════
$scanSection

════════════════════════════════════════
CONVERSATION HISTORY (most recent last)
════════════════════════════════════════
${historyText.isEmpty ? 'No previous messages.' : historyText}

════════════════════════════════════════
CURRENT USER MESSAGE
════════════════════════════════════════
${message.trim()}

Attached image: ${hasImage ? 'Yes — the user has uploaded an image. Acknowledge it but base your answer only on the text context above unless image content was explicitly extracted and passed to you.' : 'No'}
''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return 'Sorry, I received an empty response. Please try again.';
      }
      return text.trim();
    } catch (e) {
      return 'I\'m having trouble connecting right now. Please try again in a moment.\n\nError: $e';
    }
  }

  // =========================================================================
  //  SYSTEM PROMPT BUILDER
  // =========================================================================
  static String _buildSystemPrompt(PilloContext ctx) {
    final profileSection = ctx.isEmpty
        ? '- No profile data loaded. Ask the user to complete their health profile in the app settings.'
        : [
            if (ctx.name.isNotEmpty)         '- Name: ${ctx.name}',
            if (ctx.gender.isNotEmpty)        '- Gender: ${ctx.gender}',
            if (ctx.dob.isNotEmpty)           '- Date of birth: ${ctx.dob}',
            if (ctx.allergies.isNotEmpty)     '- Allergies: ${ctx.allergies}',
            if (ctx.chronicConditions.isNotEmpty)
              '- Chronic conditions: ${ctx.chronicConditions}',
            if (ctx.currentMedications.isNotEmpty)
              '- Current medications (from profile): ${ctx.currentMedications}',
            if (ctx.specialConditions.isNotEmpty)
              '- Special conditions: ${ctx.specialConditions}',
            if (ctx.scheduledMedicines.isNotEmpty)
              '- Scheduled medicines:\n${ctx.scheduledMedicines.map((m) => '    • $m').join('\n')}',
          ].join('\n');

    return '''
You are Pillo, a smart and caring medicine assistant built into the Dosely app.

════════════════════════════════════════
YOUR ROLE
════════════════════════════════════════
- Help users understand their medicines, scan results, and health profile.
- Answer in simple, clear, friendly language. Avoid medical jargon unless the user asks for detail.
- Keep answers concise. Expand only if the user asks for more.
- You have access to the user's full health profile below. Use it actively.
- When the user asks about safety, interactions, or dosage — cross-reference against their known allergies, conditions, and current medications.
- Never claim a medicine is 100% safe. Always acknowledge individual variation.
- Never override the scan engine result. If the app said "not safe", support that finding — never contradict it.
- For serious medical decisions (starting, stopping, or changing a medicine) always recommend consulting a pharmacist or doctor.
- If the user's profile is incomplete, gently encourage them to fill it in for better advice.

════════════════════════════════════════
USER HEALTH PROFILE  (live from Firestore — treat as ground truth)
════════════════════════════════════════
$profileSection

════════════════════════════════════════
SAFETY RULES YOU MUST ALWAYS FOLLOW
════════════════════════════════════════
1. If the user's allergy list contains a substance and they ask about a medicine containing it → clearly warn them.
2. If the user is pregnant (special conditions or scan flag) and a medicine is marked "avoid" in pregnancy → clearly warn them.
3. If a medicine the user is asking about appears in their scheduled or current medication list → flag potential duplication.
4. Never suggest stopping a prescribed medicine. Say "consult your doctor before making changes."
5. Never diagnose. Describe symptoms and recommend professional evaluation.
6. If you are unsure, say so clearly. Do not fabricate drug information.
''';
  }

  // =========================================================================
  //  LAST SCAN RESULT FORMATTER
  // =========================================================================
  static String _buildScanSection(Map<String, dynamic>? scan) {
    if (scan == null) return 'No scan has been performed yet in this session.';

    final name    = scan['medicineName']?.toString() ?? 'Unknown';
    final generic = scan['genericName']?.toString() ?? '';
    final dosage  = scan['dosage']?.toString() ?? '';
    final status  = scan['status']?.toString() ?? 'unknown';
    final reasons = List<String>.from(scan['reasons'] ?? []);

    final statusLabel = {
      'safe':     '✅ SAFE',
      'caution':  '⚠️ USE WITH CAUTION',
      'not safe': '❌ NOT SAFE FOR THIS USER',
    }[status.toLowerCase()] ?? 'ℹ️ $status';

    return [
      '- Medicine: $name${generic.isNotEmpty ? ' ($generic)' : ''}',
      if (dosage.isNotEmpty) '- Dosage: $dosage',
      '- Safety result: $statusLabel',
      if (reasons.isNotEmpty)
        '- Reasons:\n${reasons.map((r) => '    • $r').join('\n')}',
    ].join('\n');
  }
}