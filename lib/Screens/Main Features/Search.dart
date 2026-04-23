
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _isAddingToSchedule = false;

  static const Color bg = Color(0xFFEAF7F7);
  static const Color accent = Color(0xFF4ACED0);
  static const Color darkAccent = Color(0xFF3E84A8);
  static const Color softCard = Colors.white;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      final safety = await _checkMedicineSafety(
        uid: uid,
        medicine: data,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

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
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMessage('Error while checking medicine: $e');
    }
  }

  Future<Map<String, dynamic>> _checkMedicineSafety({
    required String uid,
    required Map<String, dynamic> medicine,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final userDoc = await firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return {
        'status': 'not safe',
        'reasons': ['User profile was not found.'],
      };
    }

    final userData = userDoc.data() ?? {};
    final healthInfo = Map<String, dynamic>.from(userData['healthInfo'] ?? {});

    final allergies = _splitTextList(healthInfo['allergies']);
    final chronicConditions = _splitTextList(healthInfo['chronicConditions']);
    final currentMedications = _splitTextList(healthInfo['currentMedications']);
    final specialConditions = _splitTextList(healthInfo['specialConditions']);

    final medTableSnap = await firestore
        .collection('users')
        .doc(uid)
        .collection('medicine_table')
        .get();

    final scheduledMedicines = <String>[];
    for (final doc in medTableSnap.docs) {
      final item = doc.data();
      if (item['medicineName'] != null) {
        scheduledMedicines.add(_normalize(item['medicineName'].toString()));
      }
      if (item['genericName'] != null) {
        scheduledMedicines.add(_normalize(item['genericName'].toString()));
      }
    }

    String status = 'safe';
    final reasons = <String>[];

    final allergyIngredient =
        _normalize((medicine['allergy_ingredient'] ?? '').toString());
    final pregnancyWarning =
        (medicine['pregnancy_warning'] ?? '').toString().trim().toLowerCase();
    final avoidCombinations = _splitTextList(medicine['avoid_combinations']);

    final normalizedMedicineName = _normalize((medicine['name'] ?? '').toString());
    final normalizedGenericName =
        _normalize((medicine['generic_name'] ?? '').toString());
    final medDescription = _normalize((medicine['description'] ?? '').toString());

    if (allergyIngredient.isNotEmpty &&
        allergyIngredient != 'none' &&
        _containsEquivalent(allergies, allergyIngredient)) {
      status = 'not safe';
      reasons.add('Allergy conflict: ${medicine['allergy_ingredient']}');
    }

    for (final med in currentMedications) {
      if (_matchesAnyMedicineToken(avoidCombinations, med)) {
        status = 'not safe';
        reasons.add('Interacts with current medication: $med');
      }
    }

    for (final med in scheduledMedicines) {
      if (_matchesAnyMedicineToken(avoidCombinations, med)) {
        status = 'not safe';
        reasons.add('Interacts with scheduled medicine: $med');
      }
    }

    if (_containsEquivalent(currentMedications, normalizedMedicineName) ||
        _containsEquivalent(currentMedications, normalizedGenericName) ||
        _containsEquivalent(scheduledMedicines, normalizedMedicineName) ||
        _containsEquivalent(scheduledMedicines, normalizedGenericName)) {
      if (status != 'not safe') {
        status = 'caution';
      }
      reasons.add('This medicine may already exist in the user medication list');
    }

    if (_containsEquivalent(specialConditions, 'pregnant') ||
        _containsEquivalent(specialConditions, 'pregnancy')) {
      if (pregnancyWarning == 'avoid') {
        status = 'not safe';
        reasons.add('Not safe during pregnancy');
      } else if (pregnancyWarning == 'caution' && status != 'not safe') {
        status = 'caution';
        reasons.add('Use with caution during pregnancy');
      }
    }

    for (final condition in chronicConditions) {
      if (condition.isNotEmpty &&
          medDescription.contains(condition) &&
          status == 'safe') {
        status = 'caution';
        reasons.add('Check carefully with chronic condition: $condition');
      }
    }

    if (_containsEquivalent(allergies, 'nsaids') &&
        allergyIngredient == 'nsaids') {
      status = 'not safe';
      reasons.add('User is allergic to NSAIDs');
    }

    if (reasons.isEmpty) {
      reasons.add('No issues found based on stored user data');
    }

    return {
      'status': status,
      'reasons': reasons,
    };
  }

  Future<void> _addToSchedule({
    required String uid,
    required Map<String, dynamic> medicine,
    required Map<String, dynamic> safety,
  }) async {
    if ((safety['status'] ?? '').toString().toLowerCase() != 'safe') {
      _showMessage('This medicine cannot be added because it is not safe.');
      return;
    }

    if (_isAddingToSchedule) return;

    setState(() => _isAddingToSchedule = true);

    try {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicine_table');

      await collection.add({
        'medicineName': medicine['name'] ?? '',
        'genericName': medicine['generic_name'] ?? '',
        'dosage': medicine['dosage'] ?? '',
        'description': medicine['description'] ?? '',
        'imageUrl': _extractImageUrl(medicine),
        'status': safety['status'] ?? 'safe',
        'source': 'search',
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Medicine added to schedule.');
    } catch (e) {
      _showMessage('Failed to add medicine: $e');
    } finally {
      if (mounted) {
        setState(() => _isAddingToSchedule = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _extractImageUrl(Map<String, dynamic> medicine) {
    final candidates = [
      medicine['imageUrl'],
      medicine['image_url'],
      medicine['photoUrl'],
      medicine['photo_url'],
      medicine['image'],
      medicine['photo'],
    ];

    for (final item in candidates) {
      final value = (item ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static List<String> _splitTextList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => _normalize(e.toString()))
          .where((e) => e.isNotEmpty && e != 'none')
          .toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'none') return [];

    return text
        .split(RegExp(r'[,/;|]'))
        .map((e) => _normalize(e))
        .where((e) => e.isNotEmpty && e != 'none')
        .toList();
  }

  static bool _matchesAnyMedicineToken(List<String> haystack, String value) {
    final normalizedValue = _normalize(value);
    for (final item in haystack) {
      if (_areEquivalentMedicineNames(item, normalizedValue)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsEquivalent(List<String> items, String value) {
    final normalizedValue = _normalize(value);
    for (final item in items) {
      if (_areEquivalentMedicineNames(item, normalizedValue)) {
        return true;
      }
    }
    return false;
  }

  static bool _areEquivalentMedicineNames(String a, String b) {
    final left = _normalize(a);
    final right = _normalize(b);

    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    if (left.contains(right) || right.contains(left)) return true;

    final leftTokens = left.split(' ').where((e) => e.isNotEmpty).toSet();
    final rightTokens = right.split(' ').where((e) => e.isNotEmpty).toSet();

    if (leftTokens.isEmpty || rightTokens.isEmpty) return false;

    int matched = 0;
    for (final token in leftTokens) {
      if (rightTokens.contains(token)) matched++;
    }

    return (matched / leftTokens.length) >= 0.75;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Search Medicine'),
        backgroundColor: bg,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search by medicine name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('medicines')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Something went wrong while loading medicines.'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final filtered = _filterMedicines(docs);

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No medicines found in Firebase.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No medicine found.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final medicine = doc.data();
                      final imageUrl = _extractImageUrl(medicine);

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openMedicineDetails(context, doc),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: softCard,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _MedicineThumb(imageUrl: imageUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (medicine['name'] ?? 'Unknown medicine').toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Dosage: ${(medicine['dosage'] ?? 'N/A').toString()}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (medicine['description'] ?? 'No description available.')
                                          .toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.35,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineThumb extends StatelessWidget {
  const _MedicineThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const Icon(
              Icons.medication_rounded,
              size: 34,
              color: Color(0xFF3E84A8),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.medication_rounded,
                size: 34,
                color: Color(0xFF3E84A8),
              ),
            ),
    );
  }
}

class _MedicineDetailsSheet extends StatelessWidget {
  const _MedicineDetailsSheet({
    required this.medicine,
    required this.safety,
    required this.isAddingToSchedule,
    required this.onAddToSchedule,
  });

  final Map<String, dynamic> medicine;
  final Map<String, dynamic> safety;
  final bool isAddingToSchedule;
  final Future<void> Function() onAddToSchedule;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return Colors.green;
      case 'caution':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _statusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return 'Safe for this user';
      case 'caution':
        return 'Not safe to add now';
      default:
        return 'Not safe for this user';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (safety['status'] ?? 'not safe').toString().toLowerCase();
    final reasons = List<String>.from(safety['reasons'] ?? const []);
    final canAddToSchedule = status == 'safe';
    final imageUrl = _SearchScreenState._extractImageUrl(medicine);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEAF7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                _MedicineThumb(imageUrl: imageUrl),
                const SizedBox(height: 14),
                Text(
                  (medicine['name'] ?? 'Unknown medicine').toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dosage: ${(medicine['dosage'] ?? 'N/A').toString()}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _statusColor(status).withOpacity(0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusTitle(status),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _statusColor(status),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reasons.map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $reason',
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (medicine['description'] ?? 'No description available.')
                            .toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!canAddToSchedule || isAddingToSchedule)
                        ? null
                        : () async => onAddToSchedule(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canAddToSchedule ? const Color(0xFF3E84A8) : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isAddingToSchedule
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            canAddToSchedule
                                ? 'Add to Schedule'
                                : 'Cannot Add to Schedule',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
