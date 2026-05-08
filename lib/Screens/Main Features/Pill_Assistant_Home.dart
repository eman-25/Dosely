import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pillo_chat_service.dart' show PilloChatService, PilloContext;

class PillAssistantHome extends StatefulWidget {
  final String uid;
  const PillAssistantHome({super.key, required this.uid});

  @override
  State<PillAssistantHome> createState() => _PillAssistantHomeState();
}

class _PillAssistantHomeState extends State<PillAssistantHome> {
  // ── Colours (system palette) ────────────────────────────────────────────────
  static const _c1 = Color(0xFF48466E);
  static const _c2 = Color(0xFF3E84A8);
  static const _c3 = Color(0xFF4ACED0);
  static const _c5 = Color(0xFFE0FBF4);

  // ── State ───────────────────────────────────────────────────────────────────
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatConversation> _conversations = [];
  late String _currentConvId = '';
  PilloContext _pilloContext = const PilloContext();

  bool _sending = false;
  bool _loaded = false;
  File? _pickedImage;

  // ── Getters ─────────────────────────────────────────────────────────────────
  _ChatConversation? get _currentConversation {
    if (_currentConvId.isEmpty) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _currentConvId);
    } catch (_) {
      return null;
    }
  }

  List<_ChatMessage> get _messages => _currentConversation?.messages ?? [];

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Load chats from local storage + Firestore context
  // ──────────────────────────────────────────────────────────────────────────────
  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final rawConvs = prefs.getString('pillo_conversations');
    final rawCurrentId = prefs.getString('pillo_current_conv_id');

    if (rawConvs != null && rawConvs.isNotEmpty) {
      final List decoded = jsonDecode(rawConvs);
      _conversations.clear();
      _conversations.addAll(
        decoded.map((e) => _ChatConversation.fromJson(Map<String, dynamic>.from(e))),
      );
    }

    if (_conversations.isNotEmpty) {
      _currentConvId = rawCurrentId ?? _conversations.first.id;
    }

    // Load full health profile from Firestore for context-aware responses
    final ctx = await PilloChatService.loadUserContext(widget.uid);
    setState(() {
      _pilloContext = ctx;
      _loaded = true;
    });
    _jumpToBottom();
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Save chats to local storage
  // ──────────────────────────────────────────────────────────────────────────────
  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pillo_conversations',
      jsonEncode(_conversations.map((c) => c.toJson()).toList()),
    );
    await prefs.setString('pillo_current_conv_id', _currentConvId);
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Image picking from gallery
  // ──────────────────────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedImage = File(x.path));
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Create a new chat conversation
  // ──────────────────────────────────────────────────────────────────────────────
  void _startNewChat() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _conversations.insert(0, _ChatConversation(id, 'New Chat', []));
      _currentConvId = id;
    });
    _saveChats();
    Navigator.of(context).pop();
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Switch to existing chat conversation
  // ──────────────────────────────────────────────────────────────────────────────
  void _switchChat(String id) {
    setState(() => _currentConvId = id);
    _saveChats();
    Navigator.of(context).pop();
    _jumpToBottom();
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Build message history for LLM context
  // ──────────────────────────────────────────────────────────────────────────────
  List<Map<String, String>> _buildHistoryForModel(List<_ChatMessage> messages) {
    final items = <Map<String, String>>[];
    for (final m in messages) {
      if (m.isImage) {
        items.add({'role': 'user', 'content': '[User attached an image.]'});
      } else if ((m.text ?? '').trim().isNotEmpty) {
        items.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.text!.trim()});
      }
    }
    return items;
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Send message to Pillo and get response
  // ──────────────────────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _pickedImage;

    if (text.isEmpty && image == null) return;

    // Create conversation if it doesn't exist
    if (_currentConversation == null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final titleBase = text.isNotEmpty ? text : 'Image';
      final title = titleBase.length > 25 ? '${titleBase.substring(0, 25)}...' : titleBase;
      setState(() {
        _conversations.insert(0, _ChatConversation(id, title, []));
        _currentConvId = id;
      });
    }

    final conv = _currentConversation!;
    
    // Update title if it's a new chat
    if (conv.title == 'New Chat' && text.isNotEmpty) {
      setState(() {
        conv.title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      });
    }

    // Get history before adding current message
    final historyBeforeCurrentMessage = _buildHistoryForModel(conv.messages);

    // Add user message(s) to conversation
    setState(() {
      _sending = true;
      if (text.isNotEmpty) {
        _messages.add(_ChatMessage.user(text));
      }
      if (image != null) _messages.add(_ChatMessage.userImage(image));
      _controller.clear();
      _pickedImage = null;
    });

    _saveChats();
    _jumpToBottom();

    try {
      // Call Pillo with user profile and scan history context
      final reply = await PilloChatService.send(
        text.isNotEmpty ? text : 'The user uploaded an image.',
        previousMessages: historyBeforeCurrentMessage,
        userProfile: _pilloContext.userProfile,
        scanHistory: _pilloContext.scanHistory,
        hasImage: image != null,
      );
      
      setState(() => _messages.add(_ChatMessage.bot(reply)));
    } catch (e) {
      setState(() => _messages.add(_ChatMessage.bot('Error: $e')));
    } finally {
      setState(() => _sending = false);
      _saveChats();
      _jumpToBottom();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Scroll to bottom of messages
  // ──────────────────────────────────────────────────────────────────────────────
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

  // ──────────────────────────────────────────────────────────────────────────────
  // Main build method
  // ──────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: _c1,
        body: Center(
          child: CircularProgressIndicator(color: _c3),
        ),
      );
    }

    final isEmpty = _messages.isEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        endDrawer: _buildDrawer(),
        body: Stack(
          children: [
            // ── Background gradient ────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.22, 0.45],
                  colors: [_c1, _c2, Colors.white],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Custom header ──────────────────────────────────────────
                  _buildHeader(),
                  const SizedBox(height: 10),

                  // ── Messages (or empty state) ──────────────────────────────
                  Expanded(
                    child: isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            itemCount: _messages.length +
                                (_sending ? 1 : 0), // +1 for typing indicator
                            itemBuilder: (_, i) {
                              if (i == _messages.length) {
                                return const _TypingIndicator();
                              }
                              final msg = _messages[i];
                              return _buildChatBubble(msg);
                            },
                          ),
                  ),

                  // ── Input area ────────────────────────────────────────────
                  _buildInputArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Build header with title and menu button
  // ──────────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pillo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Build side drawer with chat history
  // ──────────────────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ListTile(
                    leading: const Icon(Icons.add, color: _c1),
                    title: const Text('New Chat'),
                    onTap: _startNewChat,
                  ),
                  const Divider(),
                  ..._conversations.map((conv) {
                    final isCurrent = conv.id == _currentConvId;
                    return ListTile(
                      title: Text(conv.title),
                      selected: isCurrent,
                      selectedTileColor: _c3.withValues(alpha: 0.2),
                      onTap: () => _switchChat(conv.id),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Build empty state with Pillo intro and suggestions
  // ──────────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Pillo avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_c1, _c3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 40),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Hi! I\'m Pillo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _c1,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Your personal medicine assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _c1.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Suggestion chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SuggestionChip('What medicine is safe?'),
                const SizedBox(width: 8),
                _SuggestionChip('Drug interactions?'),
                const SizedBox(width: 8),
                _SuggestionChip('When to take it?'),
              ],
            ),
          ),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Build message input area
  // ──────────────────────────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _c5,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Ask Pillo...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // Image picker button
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.image, color: _c3),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_c1, _c2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _sending ? Icons.hourglass_top : Icons.send,
                color: Colors.white,
              ),
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Build individual chat bubble
  // ──────────────────────────────────────────────────────────────────────────────
  Widget _buildChatBubble(_ChatMessage message) {
    final isUser = message.isUser;

    // Image message
    if (message.isImage) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(5),
            ),
            child: Image.file(
              message.imageFile!,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // Text message
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bot avatar
            if (!isUser)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 7, bottom: 2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_c1, _c3]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 14),
              ),

            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isUser
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_c1, _c2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _c1.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
              child: Text(
                message.text!,
                style: TextStyle(
                  color: isUser ? Colors.white : _c1,
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight:
                      isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════════
// TYPING INDICATOR WIDGET
// ══════════════════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  static const _c1 = Color(0xFF48466E);
  static const _c3 = Color(0xFF4ACED0);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bot avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 7, bottom: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_c1, _c3]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 14),
            ),
            // Typing bubble
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) {
                      final t =
                          ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                      final bounce =
                          t < 0.5 ? t * 2 : (1.0 - t) * 2;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 7,
                        height: 7 + bounce * 6,
                        decoration: BoxDecoration(
                          color: _c3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════════
// SUGGESTION CHIP WIDGET
// ══════════════════════════════════════════════════════════════════════════════════

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4ACED0).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF4ACED0).withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF48466E),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════════

/// Represents a single chat message
class _ChatMessage {
  final bool isUser;
  final String? text;
  final File? imageFile;

  bool get isImage => imageFile != null;

  _ChatMessage._(this.isUser, this.text, this.imageFile);

  factory _ChatMessage.user(String text) => _ChatMessage._(true, text, null);
  factory _ChatMessage.bot(String text) => _ChatMessage._(false, text, null);
  factory _ChatMessage.userImage(File f) => _ChatMessage._(true, null, f);

  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        'imagePath': imageFile?.path,
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage._(
        json['isUser'] == true,
        json['text'] as String?,
        json['imagePath'] != null ? File(json['imagePath']) : null,
      );
}

/// Represents a complete conversation
class _ChatConversation {
  final String id;
  String title;
  final List<_ChatMessage> messages;

  _ChatConversation(this.id, this.title, this.messages);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory _ChatConversation.fromJson(Map<String, dynamic> json) =>
      _ChatConversation(
        json['id'].toString(),
        json['title'].toString(),
        (json['messages'] as List)
            .map((m) => _ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}