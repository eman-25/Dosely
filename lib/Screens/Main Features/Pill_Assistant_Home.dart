import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pillo_chat_service.dart' show PilloChatService, PilloContext;
import '../../services/medicine_service.dart';
import '../HOME/medicine_table_screen.dart';

class PillAssistantHome extends StatefulWidget {
  final String uid;
  const PillAssistantHome({super.key, required this.uid});

  @override
  State<PillAssistantHome> createState() => _PillAssistantHomeState();
}

class _PillAssistantHomeState extends State<PillAssistantHome>
    with TickerProviderStateMixin {
  // ── Brand colours ────────────────────────────────────────────────────────
  static const _c1 = Color(0xFF48466E);
  static const _c2 = Color(0xFF3E84A8);
  static const _c3 = Color(0xFF4ACED0);

  // ── Controllers ──────────────────────────────────────────────────────────
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  // ── State ────────────────────────────────────────────────────────────────
  final List<_ChatConversation> _conversations = [];
  String _currentConvId = '';
  PilloContext _pilloContext = const PilloContext();
  bool _sending = false;
  bool _loaded  = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  _ChatConversation? get _currentConv {
    if (_currentConvId.isEmpty) return null;
    try { return _conversations.firstWhere((c) => c.id == _currentConvId); }
    catch (_) { return null; }
  }

  List<_ChatMessage> get _messages => _currentConv?.messages ?? [];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _loadChats() async {
    final prefs  = await SharedPreferences.getInstance();
    final rawC   = prefs.getString('pillo_conversations');

    if (rawC != null && rawC.isNotEmpty) {
      final List dec = jsonDecode(rawC);
      _conversations
        ..clear()
        ..addAll(dec.map(
            (e) => _ChatConversation.fromJson(Map<String, dynamic>.from(e as Map))));
    }
    // Always start fresh — no conversation auto-selected on open
    final ctx = await PilloChatService.loadUserContext(widget.uid);
    if (mounted) setState(() { _pilloContext = ctx; _loaded = true; });
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pillo_conversations',
        jsonEncode(_conversations.map((c) => c.toJson()).toList()));
    await prefs.setString('pillo_current_conv_id', _currentConvId);
  }

  // ── Conversation helpers ──────────────────────────────────────────────────
  void _ensureConversation(String hint) {
    if (_currentConv != null) return;
    final id    = DateTime.now().millisecondsSinceEpoch.toString();
    final title = hint.length > 30 ? '${hint.substring(0, 30)}…' : hint;
    setState(() {
      _conversations.insert(0, _ChatConversation(id, title, []));
      _currentConvId = id;
    });
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
  }

  void _deleteConversation(String id) {
    setState(() {
      _conversations.removeWhere((c) => c.id == id);
      if (_currentConvId == id) _currentConvId = '';
    });
    _saveChats();
  }

  List<Map<String, String>> _buildHistory(List<_ChatMessage> msgs) {
    final out = <Map<String, String>>[];
    for (final m in msgs) {
      if (m.isImage) {
        out.add({'role': 'user', 'content': '[User attached an image.]'});
      } else if ((m.text ?? '').trim().isNotEmpty) {
        out.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.text!.trim()});
      }
    }
    return out;
  }

  // ── Send text ─────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _ensureConversation(text);
    final conv = _currentConv!;
    if (conv.title == 'New Chat') {
      setState(() => conv.title =
          text.length > 30 ? '${text.substring(0, 30)}…' : text);
    }
    final history = _buildHistory(conv.messages);

    setState(() { _sending = true; _messages.add(_ChatMessage.user(text)); _controller.clear(); });
    _saveChats();

    try {
      final res = await PilloChatService.send(
        text,
        previousMessages: history,
        userProfile:  _pilloContext.userProfile,
        scanHistory:  _pilloContext.scanHistory,
      );
      setState(() => _messages.add(
          _ChatMessage.bot(res.text, suggestedMedicine: res.suggestedMedicine)));
    } catch (_) {
      setState(() => _messages.add(
          _ChatMessage.bot('Sorry, something went wrong. Please try again.')));
    } finally {
      setState(() => _sending = false);
      _saveChats();
    }
  }

  void _sendSuggestion(String text) { _controller.text = text; _send(); }

  // ── Scan image ────────────────────────────────────────────────────────────
  Future<void> _scanImage(ImageSource source) async {
    if (_sending) return;
    final x = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1080);
    if (x == null || !mounted) return;

    final imageFile = File(x.path);
    _ensureConversation('Medicine Scan');
    final history = _buildHistory(_messages);

    setState(() { _sending = true; _messages.add(_ChatMessage.userImage(imageFile)); });
    _saveChats();

    try {
      final ocrText = await MedicineService.processImage(imageFile.path);
      String messageToSend; String? ocrResult;
      Map<String, dynamic>? forcedSugg;

      if (ocrText.trim().isEmpty) {
        messageToSend = 'I uploaded a medicine image but OCR could not read text. Ask me to describe it manually.';
      } else {
        final medicine = await MedicineService.lookupFromOcr(ocrText);
        if (medicine != null) {
          ocrResult = '${medicine.name} (${medicine.genericName}) — ${medicine.dosage}. '
              'Avoid: ${medicine.avoidCombinations.join(', ')}. '
              'Allergy trigger: ${medicine.allergyTrigger}. Pregnancy: ${medicine.pregnancyWarning}.';
          messageToSend = 'I scanned a medicine: $ocrResult. Is it safe for me and what does it do?';
          forcedSugg = {'name': medicine.name, 'generic_name': medicine.genericName, 'dosage': medicine.dosage};
        } else {
          ocrResult     = ocrText;
          messageToSend = 'I scanned a box. Text reads: "$ocrText". Identify this medicine and tell me if it is safe for me.';
        }
      }

      final res = await PilloChatService.send(
        messageToSend,
        previousMessages: history,
        userProfile: _pilloContext.userProfile,
        scanHistory: _pilloContext.scanHistory,
        hasImage: true, ocrResultText: ocrResult,
      );
      setState(() => _messages.add(_ChatMessage.bot(
          res.text,
          suggestedMedicine: res.suggestedMedicine ?? forcedSugg?.cast<String, String>())));
    } catch (_) {
      setState(() => _messages.add(
          _ChatMessage.bot('I had trouble scanning that image. Try a clearer photo of the medicine box.')));
    } finally {
      setState(() => _sending = false);
      _saveChats();
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Scan a Medicine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _c1)),
              const SizedBox(height: 6),
              const Text('Take or upload a photo of any medicine box',
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _imageSourceTile(
                  Icons.camera_alt_rounded, 'Camera', 'Take a photo now', _c3,
                  () { Navigator.pop(context); _scanImage(ImageSource.camera); })),
                const SizedBox(width: 12),
                Expanded(child: _imageSourceTile(
                  Icons.photo_library_rounded, 'Gallery', 'Choose existing photo', _c2,
                  () { Navigator.pop(context); _scanImage(ImageSource.gallery); })),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceTile(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Container(width: 50, height: 50,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 11, height: 1.3)),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        endDrawer: _buildDrawer(),
        body: Stack(
          children: [
            // ── Fixed gradient background (always visible) ──────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.30, 0.55, 1.0],
                  colors: [_c1, _c2, Color(0xFFD6F0F8), Colors.white],
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(),
                  ),
                  _buildInputArea(),
                ],
              ),
            ),

            // ── Loading overlay (shaded, over gradient) ─────────────────
            if (!_loaded) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Loading overlay ───────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: _c1.withValues(alpha: 0.78),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Pulsing avatar
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) {
              final scale = 1.0 + _pulseCtrl.value * 0.12;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [_c3, _c2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(
                      color: _c3.withValues(alpha: 0.45 * _pulseCtrl.value + 0.2),
                      blurRadius: 28 + _pulseCtrl.value * 16,
                      spreadRadius: 4,
                    )],
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 42),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text('Getting things ready for you',
              style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text('Loading your health profile…',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14)),
          const SizedBox(height: 28),
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              color: _c3, strokeWidth: 2.5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [_c3, _c2]),
            boxShadow: [BoxShadow(color: _c3.withValues(alpha: 0.4), blurRadius: 10)],
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pillo',
                style: TextStyle(color: Colors.white,
                    fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Medicine Assistant',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ]),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_c1, _c3]),
                    shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Chat History',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _c1)),
            ]),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _c3.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: _c3, size: 20),
            ),
            title: const Text('New Chat',
                style: TextStyle(fontWeight: FontWeight.w700, color: _c1)),
            onTap: _startNewChat,
          ),
          const Divider(height: 1),
          Expanded(
            child: _conversations.isEmpty
                ? const Center(
                    child: Text('No chats yet',
                        style: TextStyle(color: Colors.black38, fontSize: 14)))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    children: _conversations.map((conv) {
                      final isCur = conv.id == _currentConvId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isCur ? _c3.withValues(alpha: 0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: isCur ? _c3 : Colors.black38),
                          title: Text(conv.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCur ? FontWeight.w700 : FontWeight.w400,
                                  color: isCur ? _c1 : Colors.black87)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.black38),
                            onPressed: () => _deleteConversation(conv.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onTap: () => _switchChat(conv.id),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
                color: _c1.withValues(alpha: 0.12),
                blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_c1, _c3],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                boxShadow: [BoxShadow(
                    color: _c3.withValues(alpha: 0.35), blurRadius: 16)],
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Hi! I\'m Pillo',
                style: TextStyle(color: _c1, fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Your personal medicine assistant.\nAsk me anything or scan a medicine box.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _c1.withValues(alpha: 0.6),
                    fontSize: 13.5, height: 1.5)),
          ]),
        ),

        const SizedBox(height: 20),

        // Quick actions grid
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Quick actions',
              style: TextStyle(color: Colors.white70,
                  fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.6)),
        ),
        const SizedBox(height: 10),

        // Scan card (full width, prominent)
        _quickActionCard(
          gradient: const LinearGradient(colors: [_c3, _c2]),
          icon: Icons.camera_alt_rounded,
          title: 'Scan a Medicine Box',
          subtitle: 'Take or upload a photo — Pillo identifies it instantly',
          onTap: _showImageSourceSheet,
          light: false,
        ),
        const SizedBox(height: 10),

        // Text suggestion cards
        _suggestionRow(
          'Safe medicines for me?', Icons.shield_outlined,
          'Drug interactions?', Icons.warning_amber_rounded,
        ),
        const SizedBox(height: 10),
        _suggestionRow(
          'Pain reliever for me', Icons.medication_rounded,
          'Is Panadol safe for me?', Icons.help_outline_rounded,
        ),
      ]),
    );
  }

  Widget _quickActionCard({
    required LinearGradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool light = true,
  }) {
    final textColor = light ? _c1 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w800,
                      color: textColor, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12, height: 1.4)),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.55), size: 16),
        ]),
      ),
    );
  }

  Widget _suggestionRow(String t1, IconData i1, String t2, IconData i2) {
    return Row(children: [
      Expanded(child: _smallSuggestionCard(t1, i1)),
      const SizedBox(width: 10),
      Expanded(child: _smallSuggestionCard(t2, i2)),
    ]);
  }

  Widget _smallSuggestionCard(String text, IconData icon) {
    return GestureDetector(
      onTap: () => _sendSuggestion(text),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _c3, size: 22),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  color: _c1, fontSize: 12.5,
                  fontWeight: FontWeight.w700, height: 1.3)),
        ]),
      ),
    );
  }

  // ── Message list (reverse = no white space) ───────────────────────────────
  Widget _buildMessageList() {
    final itemCount = _messages.length + (_sending ? 1 : 0);
    return ListView.builder(
      controller: _scroll,
      reverse: true,  // newest at bottom, eliminates white space
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        // Typing indicator is always index 0 (bottom) when sending
        if (_sending && i == 0) return const _TypingIndicator();
        final msgIdx = _messages.length - 1 - (i - (_sending ? 1 : 0));
        return _buildChatBubble(_messages[msgIdx]);
      },
    );
  }

  // ── Input area ────────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Image scan button
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: 46, height: 46,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_c3, _c2]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: _c3.withValues(alpha: 0.35), blurRadius: 8)],
            ),
            child: const Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white, size: 22),
          ),
        ),

        // Text input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAFB),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: _c3.withValues(alpha: 0.25), width: 1.5),
            ),
            child: TextField(
              controller: _controller,
              minLines: 1, maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Ask Pillo anything…',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send button
        GestureDetector(
          onTap: _sending ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: _sending
                  ? null
                  : const LinearGradient(
                      colors: [_c1, _c2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
              color: _sending ? Colors.black12 : null,
              shape: BoxShape.circle,
              boxShadow: _sending ? null : [
                BoxShadow(color: _c1.withValues(alpha: 0.3), blurRadius: 8)
              ],
            ),
            child: Icon(
              _sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
              color: Colors.white, size: 20,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Chat bubble ───────────────────────────────────────────────────────────
  Widget _buildChatBubble(_ChatMessage msg) {
    if (msg.isImage) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20), bottomRight: Radius.circular(5),
            ),
            child: Image.file(msg.imageFile!,
                width: 190, height: 190, fit: BoxFit.cover),
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_c1, _c3]),
                    boxShadow: [BoxShadow(
                        color: _c3.withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 15),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: isUser
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_c1, _c2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(5),
                          ),
                          boxShadow: [BoxShadow(
                              color: _c1.withValues(alpha: 0.20),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        )
                      : BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                  child: Text(msg.text!,
                      style: TextStyle(
                        color: isUser ? Colors.white : _c1,
                        fontSize: 14.5, height: 1.5,
                        fontWeight:
                            isUser ? FontWeight.w500 : FontWeight.w400,
                      )),
                ),
              ),
            ],
          ),

          // Medicine suggestion card
          if (!isUser && msg.suggestedMedicine != null)
            _buildSuggestionCard(msg.suggestedMedicine!),
        ],
      ),
    );
  }

  // ── Already-scheduled dialog ──────────────────────────────────────────────
  void _showAlreadyScheduledDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: Color(0xFFE67E22), size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Already Scheduled',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: _c1)),
              const SizedBox(height: 10),
              Text('$name is already in your medicine schedule.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14,
                      color: Colors.black54, height: 1.5)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _c1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Got it',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Medicine suggestion card ───────────────────────────────────────────────
  Widget _buildSuggestionCard(Map<String, dynamic> med) {
    final name    = (med['name']         as String? ?? '').trim();
    final generic = (med['generic_name'] as String? ?? '').trim();
    final dosage  = (med['dosage']       as String? ?? '').trim();
    if (name.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10, left: 38),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_c1, _c2],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: _c1.withValues(alpha: 0.25),
            blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.medication_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 15)),
            if (generic.isNotEmpty)
              Text(generic,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (dosage.isNotEmpty)
              Text(dosage,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null && name.isNotEmpty) {
              try {
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('medicine_table')
                    .get();
                final nameLower = name.toLowerCase().trim();
                final exists = snap.docs.any((doc) =>
                    (doc.data()['medicineName'] ?? '')
                        .toString()
                        .toLowerCase()
                        .trim() ==
                    nameLower);
                if (exists && mounted) {
                  _showAlreadyScheduledDialog(name);
                  return;
                }
              } catch (_) {}
            }
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicineTableScreen(prefillMedicine: {
                  'name': name, 'generic_name': generic,
                  'dosage': dosage, '_safetyStatus': 'caution',
                }),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: _c3, borderRadius: BorderRadius.circular(14)),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(height: 2),
              Text('Schedule',
                  style: TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Typing indicator ─────────────────────────────────────────────────────────
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
    vsync: this, duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30, height: 30,
          margin: const EdgeInsets.only(right: 8, bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [_c1, _c3]),
            boxShadow: [BoxShadow(color: _c3.withValues(alpha: 0.30), blurRadius: 8)],
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 15),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5), topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20),
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t      = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                final bounce = t < 0.5 ? t * 2 : (1.0 - t) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7, height: 7 + bounce * 7,
                  decoration: BoxDecoration(
                      color: _c3, borderRadius: BorderRadius.circular(4)),
                );
              },
            );
          })),
        ),
      ]),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────
class _ChatMessage {
  final bool isUser;
  final String? text;
  final File? imageFile;
  final Map<String, dynamic>? suggestedMedicine;

  bool get isImage => imageFile != null;

  _ChatMessage._(this.isUser, this.text, this.imageFile, this.suggestedMedicine);

  factory _ChatMessage.user(String text) =>
      _ChatMessage._(true, text, null, null);
  factory _ChatMessage.bot(String text, {Map<String, String>? suggestedMedicine}) =>
      _ChatMessage._(false, text, null, suggestedMedicine);
  factory _ChatMessage.userImage(File f) =>
      _ChatMessage._(true, null, f, null);

  Map<String, dynamic> toJson() => {
    'isUser': isUser, 'text': text,
    'imagePath': imageFile?.path, 'suggestedMedicine': suggestedMedicine,
  };

  factory _ChatMessage.fromJson(Map<String, dynamic> j) => _ChatMessage._(
    j['isUser'] == true,
    j['text'] as String?,
    j['imagePath'] != null ? File(j['imagePath'] as String) : null,
    j['suggestedMedicine'] != null
        ? Map<String, dynamic>.from(j['suggestedMedicine'] as Map)
        : null,
  );
}

class _ChatConversation {
  final String id;
  String title;
  final List<_ChatMessage> messages;
  _ChatConversation(this.id, this.title, this.messages);

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory _ChatConversation.fromJson(Map<String, dynamic> j) =>
      _ChatConversation(
        j['id'].toString(), j['title'].toString(),
        (j['messages'] as List)
            .map((m) => _ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );
}
