import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_data.dart';
import 'settings_panel.dart';
import 'medicine_table_screen.dart';

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
          // ── Background gradient ──────────────────────────────────────────
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
                // ── Main scrollable content ──────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: open > 0.15,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: (1 - open * 0.92).clamp(0.0, 1.0),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: _headerHeight + 20),

                            // Date pill
                            _DatePill(),

                            const SizedBox(height: 18),

                            // Section label
                            const Padding(
                              padding: EdgeInsets.only(left: 2, bottom: 14),
                              child: Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white70,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),

                            // 2×2 action grid
                            _QuickActionsGrid(
                              onScan: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const Scan())),
                              onUpload: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const Upload())),
                              onSearch: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const SearchScreen())),
                              onChat: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => PillAssistantHome(uid: FirebaseAuth.instance.currentUser!.uid))),
                            ),
                            const SizedBox(height: 22),

                            // Schedule card
                            _ScheduleCard(
                              onViewAll: () => _openMedicineTable(context),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Sliding settings panel (UNCHANGED behaviour) ─────────
                Positioned(
                  left: 18,
                  right: 18,
                  top: sheetTop + 8,
                  height: sheetTotalHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.96),
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
                                  (_dragY + details.delta.dy)
                                      .clamp(0.0, sheetMax));
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

// ── Date pill ────────────────────────────────────────────────────────────────

class _DatePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = DateFormat('EEEE, MMMM d').format(now);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: Colors.white70, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Greeting handle (settings drag panel header) ─────────────────────────────

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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 14, 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF48466E), Color(0xFF4ACED0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ACED0).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: avatar != null
                        ? ClipOval(
                            child: Image(image: avatar!, fit: BoxFit.cover))
                        : const Icon(Icons.person_rounded,
                            color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 13),
                  // Name + greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF4ACED0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF48466E),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'how_can_help'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings arrow
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showDown
                        ? const Icon(Icons.keyboard_arrow_down_rounded,
                            key: ValueKey('down'),
                            color: Color(0xFF48466E),
                            size: 26)
                        : showUp
                            ? const Icon(Icons.keyboard_arrow_up_rounded,
                                key: ValueKey('up'),
                                color: Color(0xFF48466E),
                                size: 26)
                            : const SizedBox(
                                width: 26, key: ValueKey('none')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions 2×2 grid ───────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onScan, onUpload, onSearch, onChat;

  const _QuickActionsGrid({
    required this.onScan,
    required this.onUpload,
    required this.onSearch,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.document_scanner_rounded,
                label: 'scan_btn'.tr(),
                gradientColors: const [Color(0xFF48466E), Color(0xFF3E84A8)],
                shadowColor: Color(0xFF48466E),
                onTap: onScan,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: _ActionTile(
                icon: Icons.upload_file_rounded,
                label: 'upload_btn'.tr(),
                gradientColors: const [Color(0xFF3E84A8), Color(0xFF4ACED0)],
                shadowColor: Color(0xFF3E84A8),
                onTap: onUpload,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.manage_search_rounded,
                label: 'search_btn'.tr(),
                gradientColors: const [Color(0xFF4ACED0), Color(0xFF3E84A8)],
                shadowColor: Color(0xFF4ACED0),
                onTap: onSearch,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: _ActionTile(
                icon: Icons.smart_toy_rounded,
                label: 'chat_btn'.tr(),
                gradientColors: const [Color(0xFF5C5490), Color(0xFF48466E)],
                shadowColor: Color(0xFF5C5490),
                onTap: onChat,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 148,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles (clipped cleanly by the container)
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -18,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon inside a frosted circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Open',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white54, size: 11),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's schedule card ────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final VoidCallback onViewAll;

  const _ScheduleCard({required this.onViewAll});

  /// Returns true if this medicine doc should appear today
  bool _appearsToday(Map<String, dynamic> data) {
    final today = DateTime.now();
    final todayWeekday = today.weekday; // 1=Mon … 7=Sun

    // startDate/endDate can be Timestamp or String — handle both
    DateTime? _toDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        try { return DateTime.parse(val); } catch (_) {}
      }
      return null;
    }

    final startDate = _toDate(data['startDate']);
    final endDate   = _toDate(data['endDate']);
    final days      = List<int>.from(data['selectedDays'] as List? ?? []);

    if (startDate != null && today.isBefore(
        DateTime(startDate.year, startDate.month, startDate.day))) return false;
    if (endDate != null && today.isAfter(
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59))) return false;
    if (days.isNotEmpty && !days.contains(todayWeekday)) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicine_table')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final todayDocs = docs.where((d) => _appearsToday(d.data())).toList();
        final medsList = todayDocs.map((d) {
          final data = d.data();
          final name   = (data['medicineName'] ?? '').toString();
          final hour   = ((data['timeHour'] as num?)?.toInt()) ?? 8;
          final minute = ((data['timeMinute'] as num?)?.toInt()) ?? 0;
          final time   = TimeOfDay(hour: hour, minute: minute);
          final h      = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
          final m      = time.minute.toString().padLeft(2, '0');
          final period = time.period == DayPeriod.am ? 'AM' : 'PM';
          return {'name': name, 'time': '$h:$m $period'};
        }).toList();

        return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF48466E), Color(0xFF4ACED0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'medicine_reminders'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF48466E),
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMM').format(DateTime.now()),
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black38),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF48466E), Color(0xFF3E84A8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: Colors.black.withValues(alpha: 0.05),
          ),

          const SizedBox(height: 14),

          // Medicine list or empty state
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            child: medsList.isEmpty
                ? _EmptySchedule(onTap: onViewAll)
                : Column(
                    children: medsList
                        .take(3)
                        .map((med) => _MedRow(
                              name: med['name'] as String,
                              time: med['time'] as String,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _MedRow extends StatelessWidget {
  final String name;
  final String time;
  const _MedRow({required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF4ACED0).withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ACED0), Color(0xFF3E84A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF48466E),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF48466E).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF48466E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptySchedule({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded,
                color: Color(0xFF4ACED0), size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'no_medications'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'add_medicine_hint'.tr(),
            style: const TextStyle(fontSize: 12, color: Colors.black38),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF48466E), Color(0xFF4ACED0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'add_medicine'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}