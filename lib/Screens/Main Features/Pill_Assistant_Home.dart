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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatConversation> _conversations = [];
  late String _currentConvId = '';

  final Map<String, String> _memory = {};

  bool _sending = false;
  bool _loaded = false;
  File? _pickedImage;

  static const bg = Color(0xFFEAF7F7);
  static const accent = Color(0xFF4ACED0);
  static const darkAccent = Color(0xFF3E84A8);

  _ChatConversation? get _currentConversation {
    if (_currentConvId.isEmpty) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _currentConvId);
    } catch (_) {
      return null;
    }
  }

  List<_ChatMessage> get _messages => _currentConversation?.messages ?? [];

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
    _saveChats();
    Navigator.of(context).pop();
  }

  void _switchChat(String id) {
    setState(() => _currentConvId = id);
    _saveChats();
    Navigator.of(context).pop();
    _jumpToBottom();
  }

  List<Map<String, String>> _buildHistoryForModel(List<_ChatMessage> messages) {
    final items = <Map<String, String>>[];

    for (final m in messages) {
      if (m.isImage) {
        items.add({
          'role': 'user',
          'content': '[User attached an image.]',
        });
      } else if ((m.text ?? '').trim().isNotEmpty) {
        items.add({
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text!.trim(),
        });
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

    if (lower.contains('i am pregnant')) {
      _memory['pregnancy'] = 'pregnant';
    }

    if (lower.contains('i have asthma')) {
      _memory['condition'] = 'asthma';
    }
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

      if (image != null) {
        _messages.add(_ChatMessage.userImage(image));
      }

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

      setState(() {
        _messages.add(_ChatMessage.bot(reply));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage.bot('Error: $e'));
      });
    } finally {
      setState(() {
        _sending = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        title: const Text(
          'Pillo',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
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
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_memory.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Memory: ${_memory.entries.map((e) => '${e.key}: ${e.value}').join(' • ')}',
                    style: const TextStyle(fontSize: 12.5),
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
                      selectedTileColor: accent.withOpacity(0.12),
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
          const SizedBox(height: 8),
          Image.asset('assets/images/pillo_icon.png', height: 92),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isEmpty
                ? Padding(
                    key: const ValueKey('welcome'),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      "Ask Pillo about medicine, timing, warnings, or general health questions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withOpacity(0.55),
                        height: 1.45,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('not_empty'), height: 0),
          ),
          const SizedBox(height: 6),
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
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(m.imageFile!, width: 150),
                          )
                        : Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.76,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: m.isUser ? accent : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(m.isUser ? 18 : 5),
                                bottomRight: Radius.circular(m.isUser ? 5 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              m.text!,
                              style: TextStyle(
                                color: m.isUser ? Colors.white : Colors.black87,
                                fontSize: 14.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.image_outlined, color: Colors.black54),
                    onPressed: _pickImage,
                  ),
                ),
                if (_pickedImage != null) ...[
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _pickedImage!,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                        ),
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
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask Pillo something...',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    : Container(
                        decoration: BoxDecoration(
                          color: darkAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          onPressed: _send,
                        ),
                      ),
              ],
            ),
          ),
        ],
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

  factory _ChatConversation.fromJson(Map<String, dynamic> json) => _ChatConversation(
        json['id'].toString(),
        json['title'].toString(),
        (json['messages'] as List)
            .map((m) => _ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}