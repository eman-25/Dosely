import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/Trending_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _isAddingToSchedule = false;

  // 🔥 Trending
  List<String> _trending = [];
  bool _loadingTrending = true;

  static const Color bg = Color(0xFFEAF7F7);
  static const Color accent = Color(0xFF4ACED0);
  static const Color darkAccent = Color(0xFF3E84A8);
  static const Color softCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    final result = await TrendingService.getTopTrendingNames();
    setState(() {
      _trending = result;
      _loadingTrending = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= FILTER =================
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterMedicines(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _normalize(_query);
    if (query.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data();

      final name = _normalize((data['name'] ?? '').toString());
      final genericName = _normalize((data['generic_name'] ?? '').toString());
      final dosage = _normalize((data['dosage'] ?? '').toString());
      final description = _normalize((data['description'] ?? '').toString());
      final aliases = _splitTextList(data['aliases']);

      return name.contains(query) ||
          genericName.contains(query) ||
          dosage.contains(query) ||
          description.contains(query) ||
          aliases.any((a) => a.contains(query));
    }).toList();
  }

  // ================= OPEN DETAILS =================
  Future<void> _openMedicineDetails(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final data = doc.data();

    if (uid == null) {
      _showMessage('User is not logged in.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final safety = await _checkMedicineSafety(uid: uid, medicine: data);

      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _MedicineDetailsSheet(
          medicine: data,
          safety: safety,
          isAddingToSchedule: _isAddingToSchedule,
          onAddToSchedule: () => _addToSchedule(
            uid: uid,
            medicine: data,
            safety: safety,
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showMessage('Error: $e');
    }
  }

  // ================= SAFETY =================
  Future<Map<String, dynamic>> _checkMedicineSafety({
    required String uid,
    required Map<String, dynamic> medicine,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final userDoc = await firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final healthInfo = Map<String, dynamic>.from(userData['healthInfo'] ?? {});

    final allergies = _splitTextList(healthInfo['allergies']);
    final currentMedications =
        _splitTextList(healthInfo['currentMedications']);

    String status = 'safe';
    final reasons = <String>[];

    final avoidCombinations = _splitTextList(medicine['avoid_combinations']);

    for (final med in currentMedications) {
      if (_matchesAnyMedicineToken(avoidCombinations, med)) {
        status = 'not safe';
        reasons.add('Interacts with $med');
      }
    }

    if (reasons.isEmpty) {
      reasons.add('No issues found');
    }

    return {
      'status': status,
      'reasons': reasons,
    };
  }

  // ================= ADD TO SCHEDULE =================
  Future<void> _addToSchedule({
    required String uid,
    required Map<String, dynamic> medicine,
    required Map<String, dynamic> safety,
  }) async {
    if ((safety['status'] ?? '') != 'safe') {
      _showMessage('Not safe to add');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicine_table')
        .add({
      'medicineName': medicine['name'],
      'addedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
    _showMessage('Added!');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Search Medicine'),
        backgroundColor: bg,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔥 TRENDING
          if (_query.isEmpty) _buildTrending(),

          // 📦 RESULTS
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('medicines')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered =
                    _filterMedicines(snapshot.data!.docs);

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final medicine = filtered[index].data();

                    return ListTile(
                      title: Text(medicine['name'] ?? ''),
                      subtitle: Text(medicine['description'] ?? ''),
                      onTap: () =>
                          _openMedicineDetails(context, filtered[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= TRENDING UI =================
  Widget _buildTrending() {
    if (_loadingTrending) {
      return const CircularProgressIndicator();
    }

    return Wrap(
      children: _trending.map((med) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _query = med;
              _searchController.text = med;
            });
          },
          child: Chip(label: Text(med)),
        );
      }).toList(),
    );
  }

  // ================= HELPERS =================
  static List<String> _splitTextList(dynamic value) {
    if (value == null) return [];
    return value.toString().split(',');
  }

  static bool _matchesAnyMedicineToken(
      List<String> list, String value) {
    return list.contains(value);
  }

  static String _normalize(String input) {
    return input.toLowerCase();
  }
}

// ================= DETAILS SHEET =================
class _MedicineDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final Map<String, dynamic> safety;
  final bool isAddingToSchedule;
  final Future<void> Function() onAddToSchedule;

  const _MedicineDetailsSheet({
    required this.medicine,
    required this.safety,
    required this.isAddingToSchedule,
    required this.onAddToSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medicine['name'] ?? ''),
          Text(safety['status']),
          ElevatedButton(
            onPressed: onAddToSchedule,
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
}