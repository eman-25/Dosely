import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'medicine_table_screen.dart';
import 'SettingsScreen.dart';

class AppColors {
  static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);

  static const text = Color(0xFF1E1E1E);
  static const subText = Color(0xFF6B7280);
  static const late = Color(0xFFE74C3C);
  static const card = Colors.white;
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _pageIndex = 0;
  double _hDragDx = 0;

  // Header key so we can align the sheet visually
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0.0;

  // Sheet state
  double _maxSheetHeight = 0.0;
  double _sheetHeight = 0.0; // 0 = hidden, _maxSheetHeight = fully open
  late AnimationController _sheetAnimController;

  // Dummy reminders (UI only)
  final reminders = const [
    _ReminderItem(
      checked: false,
      name: 'Panadol Extra',
      dose: '500 mg',
      time: '9:30 am',
      isLate: true,
    ),
    _ReminderItem(
      checked: false,
      name: 'Augmentin',
      dose: '1 g',
      time: '10:00 am',
      isLate: false,
    ),
    _ReminderItem(
      checked: true,
      name: 'Olfen',
      dose: '100SR',
      time: '8:00 am',
      isLate: false,
    ),
    _ReminderItem(
      checked: true,
      name: 'Artelac advanced',
      dose: '1 drop',
      time: '8:00 am',
      isLate: false,
    ),
  ];

  final features = const [
    _FeatureCardData(
      icon: Icons.camera_alt_rounded,
      title: 'Scan Your Medicine Using\nCamera',
      desc:
          'Take a clear photo of the medicine and let Dosely identify it and provide detailed information.',
      buttonText: 'Scan',
    ),
    _FeatureCardData(
      icon: Icons.cloud_upload_rounded,
      title: 'Upload a Photo of the\nMedicine',
      desc:
          'Upload an existing image of the medicine to receive accurate details, usage information, and warnings.',
      buttonText: 'Upload',
    ),
    _FeatureCardData(
      icon: Icons.manage_search_rounded,
      title: 'Search for a Medicine\nManually',
      desc:
          'Search by medicine name or type to view trusted information, instructions, and safety details.',
      buttonText: 'Search',
    ),
    _FeatureCardData(
      icon: Icons.smart_toy_rounded,
      title: 'Pillo Assistant',
      desc:
          'Get instant answers about medicines, usage, and safety information to help you take them correctly and confidently.',
      buttonText: 'Chat',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sheetAnimController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = MediaQuery.of(context).size.height;
      _maxSheetHeight = h * 0.64;

      // Measure header height so the settings sheet can "attach" to it.
      final ctx = _headerKey.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) _headerHeight = box.size.height;
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sheetAnimController.dispose();
    super.dispose();
  }

  double get _sheetProgress =>
      (_maxSheetHeight <= 0) ? 0.0 : (_sheetHeight / _maxSheetHeight).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.c1, AppColors.c2, AppColors.c3, AppColors.c4, AppColors.c5],
            stops: [0.14, 0.31, 0.50, 0.72, 0.95],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable content sits UNDER the header (header is pinned in the stack).
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is OverscrollNotification) {
                  final metrics = n.metrics;
                  if (metrics.pixels <= metrics.minScrollExtent && n.overscroll < 0) {
                    _animateOpenSheet();
                    return true;
                  }
                }
                return false;
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Spacer so the scroll starts below the pinned header
                  SliverToBoxAdapter(
                    child: SizedBox(height: (_headerHeight > 0 ? _headerHeight : (topInset + 86)) + 14),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // PageView (swipe left/right)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.36,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (d) => _hDragDx += d.delta.dx,
                            onHorizontalDragEnd: (d) {
                              const threshold = 40; // px
                              if (_hDragDx > threshold) {
                                final prev = (_pageController.page ?? _pageIndex).round() - 1;
                                final target = prev.clamp(0, features.length - 1);
                                _pageController.animateToPage(
                                  target,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              } else if (_hDragDx < -threshold) {
                                final next = (_pageController.page ?? _pageIndex).round() + 1;
                                final target = next.clamp(0, features.length - 1);
                                _pageController.animateToPage(
                                  target,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                              _hDragDx = 0;
                            },
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: features.length,
                              physics: const PageScrollPhysics(),
                              onPageChanged: (i) => setState(() => _pageIndex = i),
                              itemBuilder: (context, i) {
                                final data = features[i];
                                return AnimatedPadding(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.only(
                                    left: i == _pageIndex ? 6 : 14,
                                    right: i == _pageIndex ? 6 : 14,
                                    top: i == _pageIndex ? 0 : 10,
                                    bottom: i == _pageIndex ? 0 : 10,
                                  ),
                                  child: _FeatureCard(
                                    data: data,
                                    onSwipeLeft: () {
                                      final next = (_pageController.page ?? _pageIndex).round() + 1;
                                      final target = next.clamp(0, features.length - 1);
                                      _pageController.animateToPage(
                                        target,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    onSwipeRight: () {
                                      final prev = (_pageController.page ?? _pageIndex).round() - 1;
                                      final target = prev.clamp(0, features.length - 1);
                                      _pageController.animateToPage(
                                        target,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverToBoxAdapter(
                      child: _RemindersCard(reminders: reminders),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: const [
                        SizedBox(height: 14),
                        Icon(Icons.keyboard_arrow_up_rounded, color: Colors.black38),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),

            // Pinned header (full width) - its corners/shadow change based on sheet progress.
            SafeArea(
              left: false,
              right: false,
              bottom: false,
              child: Container(
                key: _headerKey,
                width: double.infinity,
                child: _TopHeader(
                  name: 'Sara',
                  onArrowTap: _toggleSheet,
                  progress: _sheetProgress,
                ),
              ),
            ),

            // Scrim so it feels like one surface and prevents tapping behind while open
            if (_sheetProgress > 0)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (_sheetProgress * 0.35).clamp(0.0, 0.35),
                    child: Container(color: Colors.black),
                  ),
                ),
              ),

            // Settings sheet that "pulls down" from the bottom edge of the header.
            if (_maxSheetHeight > 0 && _headerHeight > 0)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: _headerHeight - _maxSheetHeight + _sheetHeight,
                height: _maxSheetHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (d) {
                    setState(() {
                      _sheetHeight = (_sheetHeight + d.delta.dy).clamp(0.0, _maxSheetHeight);
                    });
                  },
                  onVerticalDragEnd: (d) {
                    final velocity = d.primaryVelocity ?? 0.0;
                    if (velocity > 300) {
                      _openSheet();
                    } else if (velocity < -300) {
                      _closeSheet();
                    } else {
                      if (_sheetHeight > _maxSheetHeight * 0.35) {
                        _openSheet();
                      } else {
                        _closeSheet();
                      }
                    }
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card.withOpacity(0.98),
                        // ONLY bottom radius: top is flush with the header so no side gaps
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16 * _sheetProgress),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Settings',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Account, Notifications, Appearance, and more',
                                      style: TextStyle(color: AppColors.subText),
                                    ),
                                    SizedBox(height: 16),
                                    _SettingsTile(icon: Icons.person_outline, title: 'Account'),
                                    _SettingsTile(icon: Icons.notifications_none, title: 'Notifications'),
                                    _SettingsTile(icon: Icons.color_lens_outlined, title: 'Appearance'),
                                    SizedBox(height: 200),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSheet() {
    if (_sheetHeight <= 0) {
      _openSheet();
    } else {
      _closeSheet();
    }
  }

  void _openSheet() {
    setState(() {
      _sheetHeight = _maxSheetHeight;
    });
    _sheetAnimController.forward(from: 0);
  }

  void _animateOpenSheet() {
    setState(() {
      _sheetHeight = math.max(_sheetHeight, _maxSheetHeight * 0.42);
    });
    _sheetAnimController.forward(from: 0);
  }

  void _closeSheet() {
    setState(() {
      _sheetHeight = 0.0;
    });
    _sheetAnimController.reverse(from: 1);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SettingsTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      onTap: () {},
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String name;
  final VoidCallback onArrowTap;

  /// 0 = sheet closed, 1 = sheet fully open
  final double progress;

  const _TopHeader({
    required this.name,
    required this.onArrowTap,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    // When the sheet opens, we remove the header's bottom radius + shadow
    // so it visually merges with the settings panel (no side gaps).
    final double bottomRadius = (1 - p) * 22.0;
    final double shadowOpacity = (1 - p) * 0.08;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.96),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
        boxShadow: shadowOpacity <= 0.001
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(shadowOpacity),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
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
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'How can MedAI help you today?',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.c3,
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onArrowTap,
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardData {
  final IconData icon;
  final String title;
  final String desc;
  final String buttonText;

  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.buttonText,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureCardData data;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _FeatureCard({required this.data, this.onSwipeLeft, this.onSwipeRight});

  @override
  Widget build(BuildContext context) {
    double startX = 0;
    double accDx = 0;
    return Listener(
      onPointerDown: (ev) {
        startX = ev.position.dx;
        accDx = 0;
      },
      onPointerMove: (ev) {
        accDx += ev.delta.dx;
      },
      onPointerUp: (ev) {
        const threshold = 40;
        if (accDx < -threshold) {
          if (onSwipeLeft != null) onSwipeLeft!();
        } else if (accDx > threshold) {
          if (onSwipeRight != null) onSwipeRight!();
        }
        startX = 0;
        accDx = 0;
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.95),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              height: 74,
              width: 74,
              decoration: BoxDecoration(
                color: AppColors.c5,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(data.icon, size: 44, color: AppColors.c2),
            ),
            const SizedBox(height: 14),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 12.2,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 140,
              height: 42,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.c3,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  data.buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _ReminderItem {
  final bool checked;
  final String name;
  final String dose;
  final String time;
  final bool isLate;

  const _ReminderItem({
    required this.checked,
    required this.name,
    required this.dose,
    required this.time,
    required this.isLate,
  });
}

class _RemindersCard extends StatelessWidget {
  final List<_ReminderItem> reminders;
  const _RemindersCard({required this.reminders});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Medicine Reminders',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...reminders.map((r) => _ReminderRow(item: r)),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final _ReminderItem item;
  const _ReminderRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final timeColor = item.isLate ? AppColors.late : AppColors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.95,
            child: Checkbox(
              value: item.checked,
              onChanged: (_) {},
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: Colors.black26),
              activeColor: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${item.name} - ${item.dose}',
              style: TextStyle(
                color: item.isLate ? AppColors.late : AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.isLate ? '${item.time}  (LATE)' : item.time,
            style: TextStyle(
              color: timeColor,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
