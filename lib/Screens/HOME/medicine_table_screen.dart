import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../models/user_data.dart';
import '../../services/user_service.dart';
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
  final List<MedicineScheduleItem> medicines = [];
  final Set<String> _takenMeds = {};

  // ── Known medicine metadata (name → short display name, standard dosage, ideal time) ──
  static final Map<String, _MedMeta> _knownMeds = {
    'paracetamol': _MedMeta('Panadol Extra', '500 g',  TimeOfDay(hour: 8,  minute: 0)),
    'panadol':     _MedMeta('Panadol Extra', '500 g',  TimeOfDay(hour: 8,  minute: 0)),
    'ibuprofen':   _MedMeta('Ibuprofen',     '400 mg', TimeOfDay(hour: 8,  minute: 0)),
    'aspirin':     _MedMeta('Aspirin',        '100 mg', TimeOfDay(hour: 8,  minute: 0)),
    'naproxen':    _MedMeta('Naproxen',       '250 mg', TimeOfDay(hour: 8,  minute: 0)),
    'diclofenac':  _MedMeta('Diclofenac',     '50 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'tramadol':    _MedMeta('Tramadol',        '50 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'amoxicillin': _MedMeta('Amoxicillin',    '500 mg', TimeOfDay(hour: 8,  minute: 0)),
    'augmentin':   _MedMeta('Augmentin',      '1 g',    TimeOfDay(hour: 10, minute: 0)),
    'azithromycin':_MedMeta('Azithromycin',   '500 mg', TimeOfDay(hour: 8,  minute: 0)),
    'ciprofloxacin':_MedMeta('Ciprofloxacin','500 mg', TimeOfDay(hour: 8,  minute: 0)),
    'metronidazole':_MedMeta('Metronidazole','500 mg', TimeOfDay(hour: 8,  minute: 0)),
    'clindamycin': _MedMeta('Clindamycin',   '300 mg', TimeOfDay(hour: 8,  minute: 0)),
    'omeprazole':  _MedMeta('Omeprazole',    '20 mg',  TimeOfDay(hour: 7,  minute: 30)),
    'pantoprazole':_MedMeta('Pantoprazole',  '40 mg',  TimeOfDay(hour: 7,  minute: 30)),
    'metformin':   _MedMeta('Metformin',     '500 mg', TimeOfDay(hour: 8,  minute: 0)),
    'insulin':     _MedMeta('Insulin',        '10 IU',  TimeOfDay(hour: 7,  minute: 0)),
    'atorvastatin':_MedMeta('Atorvastatin',  '20 mg',  TimeOfDay(hour: 21, minute: 0)),
    'rosuvastatin':_MedMeta('Rosuvastatin',  '10 mg',  TimeOfDay(hour: 21, minute: 0)),
    'simvastatin': _MedMeta('Simvastatin',   '20 mg',  TimeOfDay(hour: 21, minute: 0)),
    'amlodipine':  _MedMeta('Amlodipine',    '5 mg',   TimeOfDay(hour: 8,  minute: 0)),
    'lisinopril':  _MedMeta('Lisinopril',    '10 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'losartan':    _MedMeta('Losartan',       '50 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'metoprolol':  _MedMeta('Metoprolol',    '50 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'atenolol':    _MedMeta('Atenolol',       '50 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'furosemide':  _MedMeta('Furosemide',    '40 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'warfarin':    _MedMeta('Warfarin',       '5 mg',   TimeOfDay(hour: 18, minute: 0)),
    'apixaban':    _MedMeta('Apixaban',       '5 mg',   TimeOfDay(hour: 8,  minute: 0)),
    'salbutamol':  _MedMeta('Salbutamol',    '100 mcg',TimeOfDay(hour: 8,  minute: 0)),
    'ventolin':    _MedMeta('Ventolin',       '100 mcg',TimeOfDay(hour: 8,  minute: 0)),
    'budesonide':  _MedMeta('Budesonide',    '200 mcg',TimeOfDay(hour: 8,  minute: 0)),
    'levothyroxine':_MedMeta('Levothyroxine','50 mcg', TimeOfDay(hour: 7,  minute: 0)),
    'sertraline':  _MedMeta('Sertraline',    '50 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'fluoxetine':  _MedMeta('Fluoxetine',    '20 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'escitalopram':_MedMeta('Escitalopram',  '10 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'alprazolam':  _MedMeta('Alprazolam',    '0.5 mg', TimeOfDay(hour: 21, minute: 0)),
    'diazepam':    _MedMeta('Diazepam',      '5 mg',   TimeOfDay(hour: 21, minute: 0)),
    'cetirizine':  _MedMeta('Cetirizine',    '10 mg',  TimeOfDay(hour: 21, minute: 0)),
    'loratadine':  _MedMeta('Loratadine',    '10 mg',  TimeOfDay(hour: 8,  minute: 0)),
    'prednisolone':_MedMeta('Prednisolone',  '5 mg',   TimeOfDay(hour: 8,  minute: 0)),
    'dexamethasone':_MedMeta('Dexamethasone','4 mg',   TimeOfDay(hour: 8,  minute: 0)),
    'vitamin d':   _MedMeta('Vitamin D',     '1000 IU',TimeOfDay(hour: 8,  minute: 0)),
    'vitamin b12': _MedMeta('Vitamin B12',   '1000 mcg',TimeOfDay(hour: 8, minute: 0)),
    'folic acid':  _MedMeta('Folic Acid',    '5 mg',   TimeOfDay(hour: 8,  minute: 0)),
    'iron':        _MedMeta('Iron',           '325 mg', TimeOfDay(hour: 8,  minute: 0)),
    'olfen':       _MedMeta('Olfen',          '100SR',  TimeOfDay(hour: 8,  minute: 0)),
    'artelac':     _MedMeta('Artelac Advanced','1 drop',TimeOfDay(hour: 8,  minute: 0)),
    'montelukast': _MedMeta('Montelukast',   '10 mg',  TimeOfDay(hour: 21, minute: 0)),
    'allopurinol': _MedMeta('Allopurinol',   '300 mg', TimeOfDay(hour: 8,  minute: 0)),
    'methotrexate':_MedMeta('Methotrexate',  '7.5 mg', TimeOfDay(hour: 8,  minute: 0)),
    'hydroxychloroquine':_MedMeta('Hydroxychloroquine','200 mg',TimeOfDay(hour: 8,minute:0)),
  };

  _MedMeta _resolve(String stored, int index) {
    final lower = stored.toLowerCase();
    for (final key in _knownMeds.keys) {
      if (lower.contains(key)) return _knownMeds[key]!;
    }
    // Staggered fallback times so they don't all show 8:00 am
    const fallbackHours = [8, 10, 12, 14, 16, 18, 20];
    return _MedMeta(
      stored.split('(').first.trim(),
      '1 dose',
      TimeOfDay(hour: fallbackHours[index % fallbackHours.length], minute: 0),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMedicines());
  }

  void _loadMedicines() {
    final user = Provider.of<UserData>(context, listen: false);
    final raw = user.currentMedications;
    final list = raw.isNotEmpty
        ? raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'None').toList()
        : <String>[];

    setState(() {
      medicines.clear();
      for (int i = 0; i < list.length; i++) {
        final meta = _resolve(list[i], i);
        medicines.add(MedicineScheduleItem(
          storedName: list[i],
          displayName: meta.displayName,
          dosage: meta.dosage,
          time: meta.time,
          status: MedicineStatus.pending,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      child: _MedicineListCard(
                        medicines: medicines,
                        takenMeds: _takenMeds,
                        onAddPressed: _addMedicine,
                        onToggleTaken: _toggleTaken,
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
              child: _RoundFab(icon: Icons.edit_rounded, onTap: _showEditSection),
            ),
            Positioned(
              right: 22,
              bottom: 22,
              child: _RoundFab(
                icon: Icons.smart_toy_rounded,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PillAssistantHome())),
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
            child: Text('Medicine Schedule'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(width: 48),
        ],
      );

  void _toggleTaken(MedicineScheduleItem item) => setState(() {
        if (_takenMeds.contains(item.storedName)) {
          _takenMeds.remove(item.storedName);
        } else {
          _takenMeds.add(item.storedName);
        }
      });

  Future<void> _addMedicine({StateSetter? modalSetState}) async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 dose');
    TimeOfDay selTime = const TimeOfDay(hour: 8, minute: 0);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Medicine'),
        content: StatefulBuilder(
          builder: (ctx2, sl) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Medicine Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Dosage', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scheduled time'),
                subtitle: Text(selTime.format(ctx2)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final p =
                      await showTimePicker(context: ctx2, initialTime: selTime);
                  if (p != null) sl(() => selTime = p);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    final name = nameCtrl.text.trim();
    final meta = _resolve(name, medicines.length);
    final item = MedicineScheduleItem(
      storedName: name,
      displayName: meta.displayName,
      dosage: dosageCtrl.text.trim().isNotEmpty ? dosageCtrl.text.trim() : meta.dosage,
      time: selTime,
      status: MedicineStatus.pending,
    );

    final conflict = medicines.any((m) =>
        m.storedName.toLowerCase() == name.toLowerCase());
    if (conflict) { _showWarning('$name already exists.'); return; }

    setState(() => medicines.add(item));
    modalSetState?.call(() {});

    final user = Provider.of<UserData>(context, listen: false);
    final cur = user.currentMedications
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'None')
        .toList();
    if (!cur.contains(name)) {
      cur.add(name);
      final joined = cur.join(', ');
      await UserService.updateHealthInfo(
        allergies: user.allergies,
        chronicConditions: user.chronicConditions,
        currentMedications: joined,
        specialConditions: user.specialConditions,
      );
      user.updateHealthInfo(currentMedications: joined);
    }
    _showInfo('Medicine added.');
  }

  void _showEditSection() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: const Color(0xFFE6F2F2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Section'.tr(),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87)),
                        IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.black87)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: medicines.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No medicines yet.\nTap + to add one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black45)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            itemCount: medicines.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _editCard(medicines[i], i, setM),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 20, 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _addMedicine(modalSetState: setM),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black87, width: 2),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.black87, size: 26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _editCard(MedicineScheduleItem item, int idx, StateSetter setM) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Dosage: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
              const SizedBox(width: 6),
              _dropdown(
                value: item.dosage,
                items: {'500 g','100 g','1 g','100SR','1 drop','1 dose',
                        '500 mg','250 mg','100 mg','50 mg','10 mg','5 mg', item.dosage}.toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => medicines[idx] = item.copyWith(dosage: v));
                    setM(() {});
                  }
                },
              ),
              const Spacer(),
              const Text('Time: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: item.time);
                  if (p != null) {
                    setState(() => medicines[idx] = item.copyWith(time: p));
                    setM(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD4D8D9),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.formattedTime,
                          style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.black87),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() => medicines.removeAt(idx));
                  setM(() {});
                  _showInfo('${item.displayName} removed.');
                },
                child: const Icon(Icons.delete_outline_rounded, color: Colors.black87, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFD4D8D9), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.black87),
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          dropdownColor: const Color(0xFFE6F2F2),
          borderRadius: BorderRadius.circular(16),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showWarning(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
  void _showInfo(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFF3E84A8)));
}

// ── Internal metadata ────────────────────────────────────────────────────────
class _MedMeta {
  final String displayName, dosage;
  final TimeOfDay time;
  const _MedMeta(this.displayName, this.dosage, this.time);
}

// ── Calendar ─────────────────────────────────────────────────────────────────
class _CalendarCard extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  const _CalendarCard({required this.selectedDay, required this.onDaySelected});
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.black87),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                Text(DateFormat('MMMM yyyy').format(_month),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.black87),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['sun','mon','tue','wed','thu','fri','sat']
                  .map((d) => Text(d.tr(), style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w700)))
                  .toList(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: List.generate(42, (i) {
                if (i < offset || i >= offset + dim) return const SizedBox(width: 32, height: 32);
                final day = i - offset + 1;
                final date = DateTime(_month.year, _month.month, day);
                final isSel = date.year == widget.selectedDay.year &&
                    date.month == widget.selectedDay.month &&
                    date.day == widget.selectedDay.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                return SizedBox(
                  width: 32, height: 32,
                  child: GestureDetector(
                    onTap: () => widget.onDaySelected(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF4ACED0) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSel
                            ? Border.all(color: const Color(0xFF4ACED0), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text('$day',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : Colors.black87)),
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

// ── Medicine List Card ────────────────────────────────────────────────────────
class _MedicineListCard extends StatelessWidget {
  final List<MedicineScheduleItem> medicines;
  final Set<String> takenMeds;
  final VoidCallback onAddPressed;
  final ValueChanged<MedicineScheduleItem> onToggleTaken;

  const _MedicineListCard({
    required this.medicines, required this.takenMeds,
    required this.onAddPressed, required this.onToggleTaken,
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
                Text('Medicine Schedule Table'.tr(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: onAddPressed, icon: const Icon(Icons.add_circle_outline_rounded)),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: medicines.isEmpty
                  ? Center(child: Text('no_medications'.tr(), style: const TextStyle(color: Colors.black38)))
                  : ListView.separated(
                      itemCount: medicines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = medicines[i];
                        final isTaken = takenMeds.contains(item.storedName);
                        final now = TimeOfDay.now();
                        final isLate = !isTaken &&
                            (now.hour > item.time.hour ||
                                (now.hour == item.time.hour && now.minute >= item.time.minute));
                        return _MedicineRow(
                            item: item, isTaken: isTaken, isLate: isLate,
                            onToggle: () => onToggleTaken(item));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Medicine Row — "Name , dosage  |  9:50 am  (LATE)" ───────────────────────
class _MedicineRow extends StatelessWidget {
  final MedicineScheduleItem item;
  final bool isTaken, isLate;
  final VoidCallback onToggle;
  const _MedicineRow({required this.item, required this.isTaken, required this.isLate, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = isLate ? const Color(0xFFB3261E) : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isTaken ? Colors.black87 : Colors.transparent,
                border: Border.all(
                  color: isLate ? const Color(0xFFB3261E) : isTaken ? Colors.black87 : Colors.black54,
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
          // Name , dosage
          Expanded(
            child: Text(
              '${item.displayName} , ${item.dosage}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          // Time (LATE)
          Text(
            isLate ? '${item.formattedTime}   (LATE)' : item.formattedTime,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Round FAB ─────────────────────────────────────────────────────────────────
class _RoundFab extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _RoundFab({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(0.9), shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(), onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14),
              child: Icon(icon, size: 24, color: Colors.black87)),
        ),
      );
}

// ── Data model ────────────────────────────────────────────────────────────────
enum MedicineStatus { taken, pending, late }

class MedicineScheduleItem {
  final String storedName;   // raw from UserData  e.g. "Paracetamol (Panadol / Tylenol)"
  final String displayName;  // short display name e.g. "Panadol Extra"
  final String dosage;       // e.g. "500 g", "1 drop"
  final TimeOfDay time;
  final MedicineStatus status;

  const MedicineScheduleItem({
    required this.storedName, required this.displayName,
    required this.dosage, required this.time, required this.status,
  });

  MedicineScheduleItem copyWith({String? storedName, String? displayName, String? dosage, TimeOfDay? time, MedicineStatus? status}) =>
      MedicineScheduleItem(
        storedName: storedName ?? this.storedName,
        displayName: displayName ?? this.displayName,
        dosage: dosage ?? this.dosage,
        time: time ?? this.time,
        status: status ?? this.status,
      );

  String get formattedTime {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'am' : 'pm';
    return '$h:$m $p';
  }
}