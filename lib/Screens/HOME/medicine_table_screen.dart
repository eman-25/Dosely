import 'package:flutter/material.dart';
import 'home_screen.dart';

class MedicineTableScreen extends StatelessWidget {
  const MedicineTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double dragDy = 0;

    void handleVerticalDragUpdate(DragUpdateDetails d) {
      dragDy += d.delta.dy;
    }

    void handleVerticalDragEnd(DragEndDetails d) {
      const threshold = 80.0;
      if (dragDy > threshold) Navigator.of(context).pop();
      dragDy = 0;
    }

    return Scaffold(
      body: GestureDetector(
        onVerticalDragUpdate: handleVerticalDragUpdate,
        onVerticalDragEnd: handleVerticalDragEnd,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.c1, AppColors.c2, AppColors.c3, AppColors.c4, AppColors.c5],
              stops: [0.14, 0.31, 0.50, 0.72, 0.95],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const _CalendarCard(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView(
                          children: const [
                            _MedRow(
                              name: 'Panadol Extra - 500 mg',
                              time: '9:30 am',
                              isLate: true,
                            ),
                            _MedRow(name: 'Augmentin - 1 g', time: '10:00 am'),
                            _MedRow(name: 'Olfen - 100SR', time: '8:00 am'),
                            _MedRow(name: 'Artelac advanced - 1 drop', time: '8:00 am'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: AppColors.c3,
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  left: 18,
                  child: FloatingActionButton.small(
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.smart_toy_rounded, color: AppColors.c2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel('Sun'),
              _DayLabel('Mon'),
              _DayLabel('Tue'),
              _DayLabel('Wed'),
              _DayLabel('Thu'),
              _DayLabel('Fri'),
              _DayLabel('Sat'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(30, (i) {
              final day = i + 1;
              final selected = day == 8;
              return Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.c4 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.text : Colors.black45,
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String t;
  const _DayLabel(this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      t,
      style: const TextStyle(
        color: Colors.black38,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  final String name;
  final String time;
  final bool isLate;

  const _MedRow({required this.name, required this.time, this.isLate = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm_rounded, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isLate ? AppColors.late : AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isLate ? '$time  (LATE)' : time,
              style: TextStyle(
                color: isLate ? AppColors.late : AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
