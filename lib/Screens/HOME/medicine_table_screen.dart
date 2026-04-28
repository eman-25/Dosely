import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../Main Features/Pill_Assistant_Home.dart';

class MedicineTableScreen extends StatefulWidget {
  const MedicineTableScreen({super.key});

  @override
  State<MedicineTableScreen> createState() => _MedicineTableScreenState();
}

class _MedicineTableScreenState extends State<MedicineTableScreen> {
  static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);

  DateTime selectedDay = DateTime.now();
  bool _adding = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _tableRef {
    final uid = _user?.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicine_table');
  }

  @override
  Widget build(BuildContext context) {
    final uid = _user?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Dismissible(
        key: const Key('medicine_table_dismissible'),
        direction: DismissDirection.down,
        onDismissed: (_) => Navigator.of(context).pop(),
        child: Stack(
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
                    _topBar(),
                    const SizedBox(height: 10),
                    _CalendarCard(
                      selectedDay: selectedDay,
                      onDaySelected: (d) => setState(() => selectedDay = d),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: uid == null
                          ? _InfoCard(
                              child: Center(
                                child: Text(
                                  'Please log in first.',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _tableRef.orderBy('addedAt', descending: true).snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const _InfoCard(
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return _InfoCard(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          'Error loading medicine table:\n${snapshot.error}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];
                                final visibleDocs = docs.where((doc) {
                                  final data = doc.data();
                                  return _appearsOnSelectedDay(data, selectedDay);
                                }).toList();

                                return _MedicineListCard(
                                  selectedDay: selectedDay,
                                  docs: visibleDocs,
                                  onAddPressed: _showAddMedicineDialog,
                                  onToggleTaken: _toggleTaken,
                                  onEdit: _showEditMedicineDialog,
                                  onDelete: _deleteMedicine,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: MediaQuery.of(context).padding.top + 6,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 22,
              bottom: 22,
              child: _RoundFab(
                icon: Icons.add_rounded,
                onTap: _showAddMedicineDialog,
              ),
            ),
            Positioned(
              right: 22,
              bottom: 22,
              child: _RoundFab(
                icon: Icons.smart_toy_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PillAssistantHome()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              'Medicine Schedule'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      );

  Future<void> _showAddMedicineDialog() async {
    if (_user == null || _adding) return;

    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    final selectedWeekdays = <int>{selectedDay.weekday};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Scheduled time'),
                  subtitle: Text(selectedTime.format(ctx)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setLocal(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Repeat on days',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final selected = selectedWeekdays.contains(weekday);
                    return FilterChip(
                      selected: selected,
                      label: Text(_weekdayShort(weekday)),
                      onSelected: (value) {
                        setLocal(() {
                          if (value) {
                            selectedWeekdays.add(weekday);
                          } else {
                            selectedWeekdays.remove(weekday);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No save button is needed. After pressing Add, it is saved automatically.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final dosage = dosageCtrl.text.trim();
    final description = descCtrl.text.trim();
    final imageUrl = imageCtrl.text.trim();

    if (name.isEmpty) {
      _showMessage('Medicine name is required.');
      return;
    }

    if (selectedWeekdays.isEmpty) {
      _showMessage('Choose at least one day.');
      return;
    }

    setState(() => _adding = true);

    try {
      await _tableRef.add({
        'medicineName': name,
        'genericName': '',
        'dosage': dosage,
        'description': description,
        'imageUrl': imageUrl,
        'status': 'safe',
        'source': 'manual',
        'timeHour': selectedTime.hour,
        'timeMinute': selectedTime.minute,
        'selectedDays': selectedWeekdays.toList()..sort(),
        'takenDates': <String>[],
        'startDate': _dateKey(selectedDay),
        'addedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Medicine added and saved.');
    } catch (e) {
      _showMessage('Failed to add medicine: $e');
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  Future<void> _showEditMedicineDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final nameCtrl =
        TextEditingController(text: (data['medicineName'] ?? '').toString());
    final dosageCtrl =
        TextEditingController(text: (data['dosage'] ?? '').toString());
    final descCtrl =
        TextEditingController(text: (data['description'] ?? '').toString());
    final imageCtrl =
        TextEditingController(text: (data['imageUrl'] ?? '').toString());

    TimeOfDay selectedTime = TimeOfDay(
      hour: ((data['timeHour'] as num?)?.toInt() ?? 8).clamp(0, 23),
      minute: ((data['timeMinute'] as num?)?.toInt() ?? 0).clamp(0, 59),
    );

    final selectedWeekdays = _readWeekdays(data);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Edit Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Scheduled time'),
                  subtitle: Text(selectedTime.format(ctx)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setLocal(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Repeat on days',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final selected = selectedWeekdays.contains(weekday);
                    return FilterChip(
                      selected: selected,
                      label: Text(_weekdayShort(weekday)),
                      onSelected: (value) {
                        setLocal(() {
                          if (value) {
                            selectedWeekdays.add(weekday);
                          } else {
                            selectedWeekdays.remove(weekday);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Changes are saved directly after pressing Update.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    if (nameCtrl.text.trim().isEmpty) {
      _showMessage('Medicine name is required.');
      return;
    }

    if (selectedWeekdays.isEmpty) {
      _showMessage('Choose at least one day.');
      return;
    }

    try {
      await doc.reference.update({
        'medicineName': nameCtrl.text.trim(),
        'dosage': dosageCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'imageUrl': imageCtrl.text.trim(),
        'timeHour': selectedTime.hour,
        'timeMinute': selectedTime.minute,
        'selectedDays': selectedWeekdays.toList()..sort(),
      });
      _showMessage('Medicine updated.');
    } catch (e) {
      _showMessage('Failed to update medicine: $e');
    }
  }

  Future<void> _deleteMedicine(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine'),
        content: Text(
          'Delete ${(doc.data()['medicineName'] ?? 'this medicine').toString()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await doc.reference.delete();
      _showMessage('Medicine deleted.');
    } catch (e) {
      _showMessage('Failed to delete medicine: $e');
    }
  }

  Future<void> _toggleTaken(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final dateKey = _dateKey(selectedDay);
    final current = (data['takenDates'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    try {
      if (current.contains(dateKey)) {
        await doc.reference.update({
          'takenDates': FieldValue.arrayRemove([dateKey]),
        });
      } else {
        await doc.reference.update({
          'takenDates': FieldValue.arrayUnion([dateKey]),
        });
      }
    } catch (e) {
      _showMessage('Failed to update taken status: $e');
    }
  }

  bool _appearsOnSelectedDay(Map<String, dynamic> data, DateTime day) {
    final startDate = (data['startDate'] ?? '').toString().trim();
    if (startDate.isNotEmpty) {
      try {
        final s = DateTime.parse(startDate);
        final normalizedDay = DateTime(day.year, day.month, day.day);
        final normalizedStart = DateTime(s.year, s.month, s.day);
        if (normalizedDay.isBefore(normalizedStart)) {
          return false;
        }
      } catch (_) {}
    }

    final selectedDays = _readWeekdays(data);
    if (selectedDays.isEmpty) return true;
    return selectedDays.contains(day.weekday);
  }

  Set<int> _readWeekdays(Map<String, dynamic> data) {
    final raw = data['selectedDays'];
    if (raw is List) {
      return raw
          .map((e) => int.tryParse(e.toString()) ?? -1)
          .where((e) => e >= 1 && e <= 7)
          .toSet();
    }
    return <int>{1, 2, 3, 4, 5, 6, 7};
  }

  static String _weekdayShort(int weekday) {
    const map = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return map[weekday]!;
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _CalendarCard extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  const _CalendarCard({
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selectedDay.year, widget.selectedDay.month, 1);
  }

  @override
  void didUpdateWidget(covariant _CalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay.month != widget.selectedDay.month ||
        oldWidget.selectedDay.year != widget.selectedDay.year) {
      _month = DateTime(widget.selectedDay.year, widget.selectedDay.month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWd = DateTime(_month.year, _month.month, 1).weekday;
    final offset = firstWd == 7 ? 0 : firstWd;

    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1, 1);
                  }),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: Colors.black87),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_month),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1, 1);
                  }),
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Colors.black87),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
                  .map(
                    (d) => Text(
                      d.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(42, (i) {
                if (i < offset || i >= offset + dim) {
                  return const SizedBox(width: 32, height: 32);
                }

                final day = i - offset + 1;
                final date = DateTime(_month.year, _month.month, day);

                final isSel = date.year == widget.selectedDay.year &&
                    date.month == widget.selectedDay.month &&
                    date.day == widget.selectedDay.day;

                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return SizedBox(
                  width: 32,
                  height: 32,
                  child: GestureDetector(
                    onTap: () => widget.onDaySelected(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF4ACED0) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSel
                            ? Border.all(
                                color: const Color(0xFF4ACED0),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineListCard extends StatelessWidget {
  final DateTime selectedDay;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final VoidCallback onAddPressed;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onToggleTaken;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onEdit;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onDelete;

  const _MedicineListCard({
    required this.selectedDay,
    required this.docs,
    required this.onAddPressed,
    required this.onToggleTaken,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Medicine Schedule Table'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No medicines for this day yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black38),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final item = doc.data();

                        final time = TimeOfDay(
                          hour: ((item['timeHour'] as num?)?.toInt() ?? 8)
                              .clamp(0, 23),
                          minute: ((item['timeMinute'] as num?)?.toInt() ?? 0)
                              .clamp(0, 59),
                        );

                        final takenDates = (item['takenDates'] as List?)
                                ?.map((e) => e.toString())
                                .toSet() ??
                            <String>{};

                        final isTaken = takenDates.contains(_dateKey(selectedDay));

                        final selectedDateTime = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                          selectedDay.day,
                          time.hour,
                          time.minute,
                        );
                        final isToday = _isSameDate(selectedDay, DateTime.now());
                        final isLate =
                            !isTaken && isToday && DateTime.now().isAfter(selectedDateTime);

                        return _MedicineRow(
                          data: item,
                          time: time,
                          isTaken: isTaken,
                          isLate: isLate,
                          onToggle: () => onToggleTaken(doc),
                          onEdit: () => onEdit(doc),
                          onDelete: () => onDelete(doc),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _MedicineRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final TimeOfDay time;
  final bool isTaken;
  final bool isLate;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineRow({
    required this.data,
    required this.time,
    required this.isTaken,
    required this.isLate,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLate ? const Color(0xFFB3261E) : Colors.black87;
    final medicineName = (data['medicineName'] ?? 'Unknown medicine').toString();
    final dosage = (data['dosage'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isTaken ? Colors.black87 : Colors.transparent,
                border: Border.all(
                  color: isLate
                      ? const Color(0xFFB3261E)
                      : isTaken
                          ? Colors.black87
                          : Colors.black54,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isTaken
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : isLate
                      ? null
                      : const Icon(Icons.alarm, size: 14, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackImage(),
                  )
                : _fallbackImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dosage.isNotEmpty ? '$medicineName , $dosage' : medicineName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (isLate)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'LATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB3261E),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFFEAF7F7),
      child: const Icon(Icons.medication_rounded, color: Colors.black54),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'am' : 'pm';
    return '$h:$m $p';
  }
}

class _RoundFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundFab({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, size: 24, color: Colors.black87),
        ),
      ),
    );
  }
}
