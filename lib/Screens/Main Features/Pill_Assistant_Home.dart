import 'package:flutter/material.dart';

class PillAssistantHome extends StatefulWidget {
  const PillAssistantHome({super.key});
  @override
  State<PillAssistantHome> createState() => _PillAssistantHomeState();
}

class _PillAssistantHomeState extends State<PillAssistantHome> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _msgCtrl = TextEditingController();

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => messages.add({'role': 'user', 'text': text}));
    _msgCtrl.clear();

    // Smart rule-based + future Grok/xAI integration point
    String reply = "I'm Pillo, your AI medication assistant.\n";
    if (text.toLowerCase().contains("safe")) {
      reply = "✅ According to your profile, this medicine is safe.";
    } else if (text.toLowerCase().contains("dose")) reply = "Typical dose: 1 tablet every 6-8 hours.";
    else if (text.toLowerCase().contains("side")) reply = "Common side effects: mild nausea. Always check with doctor.";

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() => messages.add({'role': 'pillo', 'text': reply}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pillo Assistant 🤖')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF4ACED0) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m['text']!, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask about any medicine...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Color(0xFF4ACED0), size: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}