import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

    String reply = 'pillo_intro'.tr();
    if (text.toLowerCase().contains("safe")) {
      reply = 'pillo_safe'.tr();
    } else if (text.toLowerCase().contains("dose")) {
      reply = 'pillo_dose'.tr();
    } else if (text.toLowerCase().contains("side")) {
      reply = 'pillo_side'.tr();
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() => messages.add({'role': 'pillo', 'text': reply}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('pillo_assistant'.tr())),
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
                    child: Text(
                      m['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
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
                      hintText: 'ask_medicine'.tr(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: Color(0xFF4ACED0), size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}