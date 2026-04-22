import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/user_data.dart';
import 'settings_panel.dart';
import 'medicine_table_screen.dart';

// Main Features
import '../Main Features/Scan.dart';
import '../Main Features/Upload.dart';
import '../Main Features/Search.dart';
import '../Main Features/Pill_Assistant_Home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);

  double _dragY = 0.0;

  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  Animation<double>? _anim;

  static const double _headerHeight = 112;

  double _sheetMax(BuildContext context) =>
      min(520.0, MediaQuery.of(context).size.height * 0.62);

  double _openFactor(BuildContext context) {
    final maxY = _sheetMax(context);
    return (maxY == 0) ? 0 : (_dragY / maxY).clamp(0.0, 1.0);
  }

  void _animateTo(BuildContext context, double target) {
    _snap.stop();
    _anim = Tween<double>(begin: _dragY, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _dragY = _anim!.value));
    _snap.reset();
    _snap.forward();
  }

  void _snapSheet(BuildContext context) {
    final maxY = _sheetMax(context);
    final shouldOpen = _dragY > maxY * 0.35;
    _animateTo(context, shouldOpen ? maxY : 0.0);
  }

  Future<void> _openMedicineTable(BuildContext context) async {
    await Navigator.of(context).push(_slideUpRoute(const MedicineTableScreen()));
  }

  Route _slideUpRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    final sheetMax = _sheetMax(context);
    final open = _openFactor(context);
    final sheetTotalHeight = sheetMax + _headerHeight;
    final sheetTop = -sheetMax + _dragY;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.14, 0.31, 0.50, 0.72, 0.95],
                colors: [c1, c2, c3, c4, c5],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: open > 0.15,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: (1 - open * 0.92).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          children: [
                            const SizedBox(height: _headerHeight + 10),
                            Expanded(
                              child: Column(
                                children: [
                                  _FunctionCarousel(
                                    onScan: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const Scan())),
                                    onUpload: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const Upload())),
                                    onSearch: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const SearchScreen())),
                                    onChat: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const PillAssistantHome())),
                                  ),
                                  const SizedBox(height: 14),
                                  _RemindersCard(
                                    onDragUp: () => _openMedicineTable(context),
                                    onArrowTap: () => _openMedicineTable(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: sheetTop + 8,
                  height: sheetTotalHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Material(
                      color: Colors.white.withOpacity(0.96),
                      child: Column(
                        children: [
                          IgnorePointer(
                            ignoring: _openFactor(context) < 0.05,
                            child: SizedBox(
                              height: sheetMax,
                              child: const SettingsPanel(),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragUpdate: (details) {
                              setState(() => _dragY =
                                  (_dragY + details.delta.dy).clamp(0.0, sheetMax));
                            },
                            onVerticalDragEnd: (_) => _snapSheet(context),
                            onTap: () {
                              final isOpen = _openFactor(context) > 0.5;
                              _animateTo(context, isOpen ? 0.0 : sheetMax);
                            },
                            child: _GreetingHandle(
                              height: _headerHeight,
                              name: (userData.name ?? '').trim().isNotEmpty
                                  ? (userData.name ?? '').trim()
                                  : 'User',
                              avatar: userData.avatar,
                              showDown: _openFactor(context) < 0.15,
                              showUp: _openFactor(context) > 0.85,
                            ),
                          ),
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
    );
  }
}

// ====================== Greeting Handle ======================
class _GreetingHandle extends StatelessWidget {
  final double height;
  final String name;
  final ImageProvider? avatar;
  final bool showDown;
  final bool showUp;

  const _GreetingHandle({
    required this.height,
    required this.name,
    required this.avatar,
    required this.showDown,
    required this.showUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'greetings'.tr(namedArgs: {'name': name}),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'how_can_help'.tr(),
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: showDown
                ? const Icon(Icons.keyboard_arrow_down_rounded, key: ValueKey('down'))
                : showUp
                    ? const Icon(Icons.keyboard_arrow_up_rounded, key: ValueKey('up'))
                    : const SizedBox(height: 24, key: ValueKey('space')),
          ),
        ],
      ),
    );
  }
}

// ====================== Function Carousel ======================
class _FunctionCarousel extends StatelessWidget {
  final VoidCallback onScan, onUpload, onSearch, onChat;

  const _FunctionCarousel({
    required this.onScan,
    required this.onUpload,
    required this.onSearch,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PageView(
        physics: const BouncingScrollPhysics(),
        children: [
          _ScanCard(
            title: 'scan_title'.tr(),
            subtitle: 'scan_subtitle'.tr(),
            buttonText: 'scan_btn'.tr(),
            onTap: onScan,
          ),
          _UploadCard(
            title: 'upload_title'.tr(),
            subtitle: 'upload_subtitle'.tr(),
            buttonText: 'upload_btn'.tr(),
            onTap: onUpload,
          ),
          // ✅ Search card now uses image asset — same style as _ScanCard
          _SearchCard(
            title: 'search_title'.tr(),
            subtitle: 'search_subtitle'.tr(),
            buttonText: 'search_btn'.tr(),
            onTap: onSearch,
          ),
          _ChatCard(
            title: 'chat_title'.tr(),
            subtitle: 'chat_subtitle'.tr(),
            buttonText: 'chat_btn'.tr(),
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

// ====================== Scan Card ======================
class _ScanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _ScanCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/scan_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF666688),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8EEE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Color(0xFF1A7A70),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== Search Card ======================
class _SearchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _SearchCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/search_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF666688),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8EEE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Color(0xFF1A7A70),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== Upload Card ======================
class _UploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/upload_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF666688),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8EEE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Color(0xFF1A7A70),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== Chat Card ======================
class _ChatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _ChatCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/pillo_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF666688),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8EEE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Color(0xFF1A7A70),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ====================== Reminders Card ======================
class _RemindersCard extends StatelessWidget {
  final VoidCallback onDragUp;
  final VoidCallback onArrowTap;

  const _RemindersCard({required this.onDragUp, required this.onArrowTap});

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    final medsStr = userData.currentMedications;
    final medsList = medsStr.isNotEmpty 
        ? medsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'None').toList()
        : <String>[];

    final bool hasMedicines = medsList.isNotEmpty;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < -220) onDragUp();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text('medicine_reminders'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            hasMedicines ? _buildFilledState(medsList) : _buildEmptyState(context),
            const SizedBox(height: 12),
            InkWell(
              onTap: onArrowTap,
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  size: 26, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledState(List<String> medicines) {
    return Column(
      children: medicines.map((med) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4ACED0).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm, size: 20, color: Color(0xFF1A7A70)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                med,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const Text(
              '8:00 am',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A7A70),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.medical_services_outlined, size: 48, color: Colors.black38),
        const SizedBox(height: 12),
        Text('no_medications'.tr(),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 4),
        Text('add_medicine_hint'.tr(),
            style: const TextStyle(fontSize: 12, color: Colors.black45),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => onArrowTap(),
          icon: const Icon(Icons.add),
          label: Text('add_medicine'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ACED0),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}