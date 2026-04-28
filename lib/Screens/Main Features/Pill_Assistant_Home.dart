import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pillo_chat_service.dart';

class PillAssistantHome extends StatefulWidget {
  const PillAssistantHome({super.key});

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
  final Map<String, String> _memory = {};

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

  // ── Persistence (UNCHANGED) ──────────────────────────────────────────────────
  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final rawConvs = prefs.getString('pillo_conversations');
    final rawCurrentId = prefs.getString('pillo_current_conv_id');
    final rawMemory = prefs.getString('pillo_memory');

    if (rawConvs != null && rawConvs.isNotEmpty) {
      final List decoded = jsonDecode(rawConvs);
      _conversations.clear();
      _conversations.addAll(
        decoded.map((e) => _ChatConversation.fromJson(Map<String, dynamic>.from(e))),
      );
    }

    if (rawMemory != null && rawMemory.isNotEmpty) {
      final decoded = Map<String, dynamic>.from(jsonDecode(rawMemory));
      _memory
        ..clear()
        ..addAll(decoded.map((key, value) => MapEntry(key, value.toString())));
    }

    if (_conversations.isNotEmpty) {
      _currentConvId = rawCurrentId ?? _conversations.first.id;
    }

    setState(() => _loaded = true);
    _jumpToBottom();
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pillo_conversations',
      jsonEncode(_conversations.map((c) => c.toJson()).toList()),
    );
    await prefs.setString('pillo_current_conv_id', _currentConvId);
    await prefs.setString('pillo_memory', jsonEncode(_memory));
  }

  // ── Image picking (UNCHANGED) ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _pickedImage = File(x.path));
  }

  // ── Conversation management (UNCHANGED) ──────────────────────────────────────
  void _startNewChat() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _conversations.insert(0, _ChatConversation(id, 'New Chat', []));
      _currentConvId = id;
    });
    _saveChats();
    Navigator.of(context).pop();
  }

  void _switchChat(String id) {
    setState(() => _currentConvId = id);
    _saveChats();
    Navigator.of(context).pop();
    _jumpToBottom();
  }

  // ── Chat logic (UNCHANGED) ────────────────────────────────────────────────────
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

  void _updateMemoryFromUserText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('my name is ')) {
      final i = lower.indexOf('my name is ');
      final value = text.substring(i + 'my name is '.length).trim();
      if (value.isNotEmpty) _memory['name'] = value;
    }
    if (lower.contains('i am allergic to ')) {
      final i = lower.indexOf('i am allergic to ');
      final value = text.substring(i + 'i am allergic to '.length).trim();
      if (value.isNotEmpty) _memory['allergies'] = value;
    }
    if (lower.contains('i take ')) {
      final i = lower.indexOf('i take ');
      final value = text.substring(i + 'i take '.length).trim();
      if (value.isNotEmpty) _memory['current_medicines'] = value;
    }
    if (lower.contains('i am pregnant')) _memory['pregnancy'] = 'pregnant';
    if (lower.contains('i have asthma')) _memory['condition'] = 'asthma';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _pickedImage;

    if (text.isEmpty && image == null) return;

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
    if (conv.title == 'New Chat' && text.isNotEmpty) {
      setState(() {
        conv.title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      });
    }

    final historyBeforeCurrentMessage = _buildHistoryForModel(conv.messages);

    setState(() {
      _sending = true;
      if (text.isNotEmpty) {
        _messages.add(_ChatMessage.user(text));
        _updateMemoryFromUserText(text);
      }
      if (image != null) _messages.add(_ChatMessage.userImage(image));
      _controller.clear();
      _pickedImage = null;
    });

    _saveChats();
    _jumpToBottom();

    try {
      final reply = await PilloChatService.send(
        text.isNotEmpty ? text : 'The user uploaded an image.',
        previousMessages: historyBeforeCurrentMessage,
        memory: _memory,
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

  // ── Build ─────────────────────────────────────────────────────────────────────
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
          // ── Background gradient (same as home screen) ──────────────────
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

                // ── Frosted chat card ──────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _c5,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 2),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Messages or empty state
                          if (isEmpty)
                            Expanded(child: _buildEmptyState())
                          else
                            Expanded(child: _buildMessages()),

                          // Input bar
                          _buildInputBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_ios_new_rounded,
              () => Navigator.pop(context)),
          const Spacer(),
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 3),
              const Text(
                'Pillo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Spacer(),
          _circleBtn(Icons.menu_rounded,
              () => _scaffoldKey.currentState?.openEndDrawer()),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
        child: Column(
          children: [
            // Pillo avatar
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_c1, _c3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _c3.withValues(alpha: 0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hi, I\'m Pillo!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _c1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ask me about medicines, dosages,\ndrug interactions, or any health questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black45,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _SuggestionChip('Medicine interactions'),
                _SuggestionChip('Dosage guide'),
                _SuggestionChip('Side effects'),
                _SuggestionChip('Is this safe for me?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Messages list ─────────────────────────────────────────────────────────────
  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length && _sending) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: _messages[i]);
      },
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_pickedImage!,
                          width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedImage = null),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 11, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Image pick button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _c3.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded,
                      color: _c2, size: 20),
                ),
              ),
              const SizedBox(width: 10),

              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _c5,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _c3.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: _c1, fontSize: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'Ask Pillo something…',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Send button
              GestureDetector(
                onTap: _sending ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _sending
                        ? null
                        : const LinearGradient(
                            colors: [_c1, _c2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _sending ? Colors.black12 : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _sending
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: _c3),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_c1, _c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conversations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_conversations.length} chat${_conversations.length == 1 ? '' : 's'}',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                  ),
                ],
              ),
            ),

            // New conversation button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GestureDetector(
                onTap: _startNewChat,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_c1, _c3]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'New Conversation',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Memory chip
            if (_memory.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _c3.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _c3.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.memory_rounded, color: _c2, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'MEMORY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _c1,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _memory.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(' • '),
                      style: const TextStyle(fontSize: 12, color: _c2),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Conversations list
            Expanded(
              child: _conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.black38, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: _conversations.length,
                      itemBuilder: (ctx, i) {
                        final conv = _conversations[i];
                        final isActive = conv.id == _currentConvId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _c3.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isActive
                                ? Border.all(
                                    color: _c3.withValues(alpha: 0.35))
                                : null,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [_c1, _c3])
                                    : null,
                                color:
                                    isActive ? null : const Color(0xFFF2F2F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_rounded,
                                size: 16,
                                color: isActive ? Colors.white : Colors.black38,
                              ),
                            ),
                            title: Text(
                              conv.title,
                              style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13.5,
                                color: _c1,
                              ),
                            ),
                            onTap: () => _switchChat(conv.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  static const _c1 = Color(0xFF48466E);
  static const _c2 = Color(0xFF3E84A8);
  static const _c3 = Color(0xFF4ACED0);

  @override
  Widget build(BuildContext context) {
    if (message.isImage) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(message.imageFile!, width: 160),
          ),
        ),
      );
    }

    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Pillo avatar on bot messages
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

            // Bubble
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

// ── Typing indicator ──────────────────────────────────────────────────────────

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

// ── Suggestion chip ───────────────────────────────────────────────────────────

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

// ── Data models (UNCHANGED) ───────────────────────────────────────────────────

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
