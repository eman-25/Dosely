import 'dart:math';
import 'package:flutter/material.dart';

class MedicineTableScreen extends StatelessWidget {
  const MedicineTableScreen({super.key});

  static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const _CalendarCard(),
                  const SizedBox(height: 12),
                  Expanded(child: _MedicineListCard()),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            left: 10,
            top: MediaQuery.of(context).padding.top + 6,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Bottom edit button
          Positioned(
            left: 22,
            bottom: 22,
            child: _RoundFab(icon: Icons.edit, onTap: () {}),
          ),

          // Bottom Pillo button
          Positioned(
            right: 22,
            bottom: 22,
            child: _RoundFab(icon: Icons.smart_toy_rounded, onTap: () {}),
          ),
        ],
      ),
    );
  }
}

// Calendar (matches your screenshot exactly)
class _CalendarCard extends StatelessWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
            const SizedBox(height: 8),
            _weekdays(),
            const SizedBox(height: 10),
            _datesGrid(selectedDay: 8),   // 8th is highlighted as in your screenshot
          ],
        ),
      ),
    );
  }

  Widget _weekdays() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => Text(d, style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w700))).toList(),
    );
  }

  Widget _datesGrid({required int selectedDay}) {
    final cells = [null, null, 28, 29, 30, 31, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(cells.length, (i) {
        final d = cells[i];
        final isSelected = d == selectedDay;
        return SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: d == null
                ? const SizedBox.shrink()
                : Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4ACED0) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

// Medicine List (matches screenshot style)
class _MedicineListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _row(leading: _redBox(), name: 'Panadol Extra , 500 g', time: '9:30 am  (LATE)', nameColor: const Color(0xFFB3261E), timeColor: const Color(0xFFB3261E)),
            const SizedBox(height: 8),
            _row(leading: const Icon(Icons.alarm, size: 20), name: 'Augmentin , 1 g', time: '10:00 am'),
            const SizedBox(height: 8),
            _row(leading: const Icon(Icons.check_box, size: 20, color: Colors.green), name: 'Olfèn  - 100SR', time: '8:00 am'),
            const SizedBox(height: 8),
            _row(leading: const Icon(Icons.check_box, size: 20, color: Colors.green), name: 'Artelac advanced - 1 drop', time: '8:00 am'),
          ],
        ),
      ),
    );
  }

  static Widget _redBox() => Container(height: 18, width: 18, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFB3261E), width: 2)));

  static Widget _row({required Widget leading, required String name, required String time, Color nameColor = Colors.black87, Color timeColor = Colors.black87}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: nameColor))),
          Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: timeColor)),
        ],
      ),
    );
  }
}

class _RoundFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: Icon(icon, size: 24, color: Colors.black87)),
      ),
    );
  }
}