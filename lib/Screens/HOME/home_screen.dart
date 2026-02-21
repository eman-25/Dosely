import 'dart:math';
import 'package:flutter/material.dart';
import 'settings_panel.dart';
import 'medicine_table_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final ImageProvider? avatar;

  const HomeScreen({
    super.key,
    this.userName = 'Sara',
    this.avatar,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Palette (your screenshots)
  static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);

  // Sheet drag value: 0 = closed, sheetMax = open
  double _dragY = 0.0;

  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  Animation<double>? _anim;

  static const double _headerHeight = 112;

  double _sheetMax(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return min(520.0, h * 0.62); // settings content height (not including header)
  }

  double _openFactor(BuildContext context) {
    final maxY = _sheetMax(context);
    return (maxY == 0) ? 0 : (_dragY / maxY).clamp(0.0, 1.0);
  }

  void _animateTo(BuildContext context, double target) {
    _snap.stop();
    _anim = Tween<double>(begin: _dragY, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _dragY = _anim!.value);
      });

    _snap
      ..reset()
      ..forward();
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
        final tween = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
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
    final sheetMax = _sheetMax(context);
    final open = _openFactor(context);

    // Sheet total height = settings content (sheetMax) + header handle
    final sheetTotalHeight = sheetMax + _headerHeight;

    // When closed: sheet is moved up by sheetMax, leaving only header visible.
    // When open: sheet top becomes 0.
    final sheetTop = -sheetMax + _dragY;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
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
                // =========================
                //  HOME CONTENT (stays put)
                // =========================
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: open > 0.15, // disable home taps when settings is open
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
                                    onScan: () {},
                                    onUpload: () {},
                                    onSearch: () {},
                                    onChat: () {},
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

                // =========================
                //  SETTINGS SHEET (above home)
                //  settings + greeting header (handle) attached at bottom
                // =========================
                Positioned(
                  left: 18,
                  right: 18,
                  top: sheetTop + 8, // +8 for a little breathing room inside SafeArea
                  height: sheetTotalHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Material(
                      color: Colors.white.withOpacity(0.96),
                      child: Column(
  children: [
    // ✅ Settings list area (ONLY clickable when sheet is open)
    IgnorePointer(
      ignoring: _openFactor(context) < 0.05, // when closed, don't catch touches
      child: SizedBox(
        height: sheetMax,
        child: SettingsPanel(
          topSpacing: 12,
          bottomSpacing: 12,
        ),
      ),
    ),

    // ✅ Greeting header handle (ALWAYS draggable)
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragY = (_dragY + details.delta.dy).clamp(0.0, sheetMax);
        });
      },
      onVerticalDragEnd: (_) => _snapSheet(context),
      onTap: () {
        final isOpen = _openFactor(context) > 0.5;
        _animateTo(context, isOpen ? 0.0 : sheetMax);
      },
      child: _GreetingHandle(
        height: _headerHeight,
        name: widget.userName,
        avatar: widget.avatar,
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

// =========================
// Greeting handle (bottom of settings sheet)
// =========================
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
                      'Greetings, $name !',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'How can Dosely help you today?',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 22,
                backgroundImage: avatar,
                backgroundColor: const Color(0xFF4ACED0).withOpacity(0.25),
                child: avatar == null
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
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

// =========================
// Middle functions carousel (left/right)
// =========================
class _FunctionCarousel extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onUpload;
  final VoidCallback onSearch;
  final VoidCallback onChat;

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
          _FunctionCard(
            icon: Icons.camera_alt_rounded,
            title: 'Scan Your Medicine Using\nCamera',
            subtitle:
                'Take a clear photo of the medicine and let Dosely identify it and provide detailed information.',
            buttonText: 'Scan',
            onTap: onScan,
          ),
          _FunctionCard(
            icon: Icons.cloud_upload_rounded,
            title: 'Upload a Photo of the\nMedicine',
            subtitle:
                'Upload an existing image of the medicine to receive accurate details, usage information, and warnings.',
            buttonText: 'Upload',
            onTap: onUpload,
          ),
          _FunctionCard(
            icon: Icons.manage_search_rounded,
            title: 'Search for a Medicine\nManually',
            subtitle:
                'Search by medicine name or type to view trusted information, instructions, and safety details.',
            buttonText: 'Search',
            onTap: onSearch,
          ),
          _FunctionCard(
            icon: Icons.smart_toy_rounded,
            title: 'Pillo Assistant',
            subtitle:
                'Get instant answers about medicines, usage, and safety information to help you take them correctly and confidently.',
            buttonText: 'Chat',
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

class _FunctionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _FunctionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
  child: SizedBox(
    height: 330, // ✅ smaller card height (adjust between 300-350)
    child: Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(28),
  color: Colors.white, // ✅ solid white
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ],
),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              width: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFACEDD9).withOpacity(0.45),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF3E84A8)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: Color.fromARGB(136, 59, 59, 92),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.65),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}

// =========================
// Bottom reminders (swipe up -> medicine table)
// =========================
class _RemindersCard extends StatelessWidget {
  final VoidCallback onDragUp;
  final VoidCallback onArrowTap;

  const _RemindersCard({
    required this.onDragUp,
    required this.onArrowTap,
  });
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onVerticalDragEnd: (details) {
      if (details.velocity.pixelsPerSecond.dy < -220) onDragUp();
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14), // bigger padding
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
          const Text(
            'Medicine Reminders',
            style: TextStyle(
              fontSize: 16, // bigger title
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          _row(
            leading: _redBox(),
            name: 'Panadol Extra , 500 g',
            time: '9:30 am  (LATE)',
            nameColor: const Color(0xFFB3261E),
            timeColor: const Color(0xFFB3261E),
          ),
          const SizedBox(height: 12),

          _row(
            leading: const Icon(Icons.alarm, size: 20, color: Colors.black54),
            name: 'Augmentin , 1 g',
            time: '10:00 am',
          ),
          const SizedBox(height: 12),

          _row(
            leading: const Icon(Icons.check_box, size: 20, color: Colors.black87),
            name: 'Olfèn  - 100SR',
            time: '8:00 am',
          ),
          const SizedBox(height: 12),

          _row(
            leading: const Icon(Icons.check_box, size: 20, color: Colors.black87),
            name: 'Artelac advanced - 1 drop',
            time: '8:00 am',
          ),

          const SizedBox(height: 12),
          InkWell(
            onTap: onArrowTap,
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 26,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}

  static Widget _redBox() {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFB3261E), width: 1.4),
      ),
    );
  }

  static Widget _row({
    required Widget leading,
    required String name,
    required String time,
    Color nameColor = Colors.black87,
    Color timeColor = Colors.black87,
  }) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: nameColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          time,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: timeColor),
        ),
      ],
    );
  }
}