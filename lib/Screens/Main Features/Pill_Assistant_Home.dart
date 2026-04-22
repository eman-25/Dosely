import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../api_key.dart';
import 'pillo_chat_service.dart';
class PillAssistantHome extends StatefulWidget {
  const PillAssistantHome({super.key});

  @override
  State<PillAssistantHome> createState() => _PillAssistantHomeState();
}

class _PillAssistantHomeState extends State<PillAssistantHome> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage.user('how can i scan medicine?'),
    _ChatMessage.bot(
      'Open the camera and point it directly and clearly at the medicine container, and wait a little while until the result appears.',
    ),
  ];

  bool _sending = false;
  File? _pickedImage;

  static const bg = Color(0xFFEAF7F7); // close to your screenshot

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedImage = File(x.path));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _pickedImage;

    if (text.isEmpty && image == null) return;

    setState(() {
      _sending = true;
      if (text.isNotEmpty) _messages.add(_ChatMessage.user(text));
      if (image != null) _messages.add(_ChatMessage.userImage(image));
      _controller.clear();
      _pickedImage = null;
    });

    _jumpToBottom();

    try {
      final reply = await PilloChatService.send(text);

      setState(() => _messages.add(_ChatMessage.bot(reply)));
    } catch (e) {
      setState(() => _messages.add(_ChatMessage.bot('Sorry, something went wrong: $e')));
    } finally {
      setState(() => _sending = false);
      _jumpToBottom();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Top bot area
          Column(
            children: [
              // Replace this with your asset if you have it:
              // Image.asset('assets/pillo.png', height: 100)
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 48, color: Color(0xFF3E84A8)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ask Pillo anything about\nyour medicine',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: m.isImage
                        ? _ImageBubble(file: m.imageFile!, isUser: m.isUser)
                        : _TextBubble(text: m.text!, isUser: m.isUser),
                  ),
                );
              },
            ),
          ),

          // If user picked image, show a small preview above input
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_pickedImage!, height: 46, width: 46, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Image attached', style: TextStyle(color: Colors.black54)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _pickedImage = null),
                    icon: const Icon(Icons.close_rounded),
                  )
                ],
              ),
            ),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, -8)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    color: Colors.black54,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sending ? null : _send(),
                      decoration: const InputDecoration(
                        hintText: 'What would you like to know?',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sending ? null : _send,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ACED0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _TextBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? Colors.white : const Color(0xFF9BC8C3);
    final fg = Colors.black87;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Text(text, style: TextStyle(color: fg, height: 1.25)),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final File file;
  final bool isUser;

  const _ImageBubble({required this.file, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String? text;
  final File? imageFile;

  bool get isImage => imageFile != null;

  _ChatMessage._(this.isUser, this.text, this.imageFile);

  factory _ChatMessage.user(String text) => _ChatMessage._(true, text, null);
  factory _ChatMessage.bot(String text) => _ChatMessage._(false, text, null);
  factory _ChatMessage.userImage(File f) => _ChatMessage._(true, null, f);

  Map<String, dynamic> toMap() => {
        "role": isUser ? "user" : "assistant",
        "text": text,
        "hasImage": imageFile != null,
      };
}