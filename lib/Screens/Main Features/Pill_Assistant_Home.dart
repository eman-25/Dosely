import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'pillo_chat_service.dart';

class PillAssistantHome extends StatefulWidget {
  const PillAssistantHome({super.key});

  @override
  State<PillAssistantHome> createState() => _PillAssistantHomeState();
}

class _PillAssistantHomeState extends State<PillAssistantHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // ✅ Start with no conversations — fresh empty state
  final List<_ChatConversation> _conversations = [];

  late String _currentConvId = '';

  _ChatConversation? get _currentConversation {
    if (_currentConvId.isEmpty) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _currentConvId);
    } catch (_) {
      return null;
    }
  }

  List<_ChatMessage> get _messages => _currentConversation?.messages ?? [];

  bool _sending = false;
  File? _pickedImage;

  static const bg = Color(0xFFEAF7F7);

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

  void _startNewChat() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _conversations.insert(0, _ChatConversation(id, 'New Chat', []));
      _currentConvId = id;
    });
    Navigator.of(context).pop();
  }

  void _switchChat(String id) {
    setState(() => _currentConvId = id);
    Navigator.of(context).pop();
    _jumpToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _pickedImage;

    if (text.isEmpty && image == null) return;

    // ✅ Auto-create a conversation on first message
    if (_currentConversation == null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      setState(() {
        _conversations.insert(0, _ChatConversation(id, title.isNotEmpty ? title : 'Image', []));
        _currentConvId = id;
      });
    }

    final conv = _currentConversation!;

    if (conv.title == 'New Chat' && text.isNotEmpty) {
      setState(() {
        conv.title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      });
    }

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
      setState(() => _messages.add(_ChatMessage.bot('Error: $e')));
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
    final bool isEmpty = _messages.isEmpty;

    return Scaffold(
      key: _scaffoldKey,
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
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),

      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add),
                  label: const Text('New Conversation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ACED0),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    return ListTile(
                      title: Text(conv.title),
                      selected: conv.id == _currentConvId,
                      selectedTileColor: const Color(0xFF4ACED0).withOpacity(0.12),
                      onTap: () => _switchChat(conv.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          Image.asset('assets/images/pillo_icon.png', height: 100),

          const SizedBox(height: 10),

          // ✅ Show welcome message when chat is empty, normal subtitle otherwise
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isEmpty
                ? Padding(
                    key: const ValueKey('welcome'),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "If you need anything, don't hesitate to ask Pillo for help.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.55),
                        height: 1.5,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 0),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: m.isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(m.imageFile!, width: 150),
                          )
                        : Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: m.isUser
                                  ? const Color(0xFF4ACED0)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(m.isUser ? 18 : 4),
                                bottomRight: Radius.circular(m.isUser ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              m.text!,
                              style: TextStyle(
                                color: m.isUser ? Colors.white : Colors.black87,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: Colors.black54),
                  onPressed: _pickImage,
                ),
                if (_pickedImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedImage!, width: 40, height: 40, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => setState(() => _pickedImage = null),
                          child: const CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 6),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF3E84A8)),
                        onPressed: _send,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _ChatMessage {
  final bool isUser;
  final String? text;
  final File? imageFile;

  bool get isImage => imageFile != null;

  _ChatMessage._(this.isUser, this.text, this.imageFile);

  factory _ChatMessage.user(String text) => _ChatMessage._(true, text, null);
  factory _ChatMessage.bot(String text) => _ChatMessage._(false, text, null);
  factory _ChatMessage.userImage(File f) => _ChatMessage._(true, null, f);
}

class _ChatConversation {
  final String id;
  String title;
  final List<_ChatMessage> messages;

  _ChatConversation(this.id, this.title, this.messages);
}