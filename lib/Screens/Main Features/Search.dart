import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/medicine_lookup_service.dart';
import '../../services/medicine_api_layer.dart'; // ✅ Import the API layer
import 'medicine_result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  static const Color _bg        = Color(0xFFEAF7F7);
  static const Color _accent     = Color(0xFF3E84A8);

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _openMedicineDetails(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
    String? searchName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showMessage('Please log in first.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic>? result;

      if (doc != null) {
        result = await MedicineLookupService.lookupByName(
          uid: uid,
          name: (doc.data()['name'] ?? '').toString(),
        );
        result ??= {
          ...doc.data(),
          'status': 'safe',
          'reasons': ['No issues found based on your health profile'],
        };
      } else if (searchName != null && searchName.isNotEmpty) {
        result = await MedicineLookupService.lookupByName(
          uid: uid,
          name: searchName,
        );
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;

      if (result == null) {
        _showMessage('Medicine not found. Try a different name.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            medicineData: result!,
            ocrText: searchName ?? (result['name'] ?? '').toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMessage('Error: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return docs.where((doc) {
      final d       = doc.data();
      final name    = (d['name']         ?? '').toString().toLowerCase();
      final generic = (d['generic_name'] ?? '').toString().toLowerCase();
      final aliases = List<String>.from(d['aliases'] ?? [])
          .map((a) => a.toLowerCase());
      return name.contains(q) ||
          generic.contains(q) ||
          aliases.any((a) => a.contains(q));
    }).toList();
  }

  // ✅ NEW: Search the 3 APIs when Firestore has no results
  Future<List<Map<String, dynamic>>> _searchAPIs(String query) async {
    if (query.isEmpty) return [];
    
    final results = <Map<String, dynamic>>[];
    
    try {
      // Call MedicineApiLayer to fetch from the 3 APIs
      final medicine = await MedicineApiLayer.fetchAndEnrich(query);
      
      if (medicine != null) {
        // Convert MedicineModel to Map<String, dynamic>
        results.add({
          'name': medicine.name,
          'generic_name': medicine.genericName,
          'dosage': medicine.dosage,
          'description': medicine.description,
          'pregnancy_warning': medicine.pregnancyWarning,
          'avoid_combinations': medicine.avoidCombinations,
          'source': 'API (OpenFDA/RxNorm/DailyMed)',
        });
      }
    } catch (e) {
      print('❌ API search error: $e');
    }
    
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Search Medicine',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _bg,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by medicine name...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: _accent),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Body
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('medicines')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Something went wrong.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  // ✅ If no query, show ALL medicines from Firestore
                  if (_query.isEmpty) {
                    final allMedicines = snapshot.data!.docs;
                    
                    if (allMedicines.isEmpty) {
                      return _searchHint();
                    }
                    
                    return _resultList(allMedicines);
                  }

                  // ✅ If query exists, filter and search APIs if needed
                  final filtered = _filterDocs(snapshot.data!.docs);

                  // If no local results, search APIs
                  if (filtered.isEmpty) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _searchAPIs(_query),
                      builder: (context, apiSnapshot) {
                        if (apiSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Searching APIs...'),
                              ],
                            ),
                          );
                        }

                        final apiResults = apiSnapshot.data ?? [];

                        if (apiResults.isEmpty) {
                          return _notFoundLocally();
                        }

                        return _resultListFromAPI(apiResults);
                      },
                    );
                  }

                  return _resultList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchHint() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_rounded, size: 56, color: _accent),
          SizedBox(height: 14),
          Text(
            'Type a medicine name to search',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _notFoundLocally() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              '"$_query" not found in saved medicines.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 13),
              ),
              onPressed: () =>
                  _openMedicineDetails(context, searchName: _query),
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text('Search online for "$_query"'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc      = filtered[index];
        final medicine = doc.data();
        return _MedicineCard(
          medicine: medicine,
          onTap: () => _openMedicineDetails(context, doc: doc),
          source: 'Saved',
        );
      },
    );
  }

  // ✅ NEW: Display results from APIs
  Widget _resultListFromAPI(List<Map<String, dynamic>> results) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final medicine = results[index];
        return _MedicineCard(
          medicine: medicine,
          onTap: () => _openMedicineDetails(context, searchName: medicine['name'] ?? ''),
          source: medicine['source'] ?? 'API',
        );
      },
    );
  }
}

// ── Medicine list card ─────────────────────────────────────────────────────────
class _MedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onTap;
  final String source;

  const _MedicineCard({
    required this.medicine,
    required this.onTap,
    required this.source,
  });

  String get _imageUrl {
    for (final key in [
      'imageUrl', 'image_url', 'photoUrl', 'photo_url', 'image'
    ]) {
      final v = (medicine[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Color get _sourceBadgeColor {
    if (source.contains('API')) return const Color(0xFF3B82F6); // Blue for API
    return const Color(0xFF10B981); // Green for Saved
  }

  @override
  Widget build(BuildContext context) {
    final name        = (medicine['name']         ?? 'Unknown').toString();
    final generic     = (medicine['generic_name'] ?? '').toString();
    final dosage      = (medicine['dosage']        ?? '').toString();
    final description = (medicine['description']   ?? '').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageUrl.isEmpty
                  ? const Icon(Icons.medication_rounded,
                      size: 26, color: Color(0xFF3E84A8))
                  : Image.network(
                      _imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.medication_rounded,
                          size: 26,
                          color: Color(0xFF3E84A8)),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Name + Source badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _sourceBadgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          source,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _sourceBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (generic.isNotEmpty && generic != name) ...[
                    const SizedBox(height: 2),
                    Text(
                      generic,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF3E84A8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (dosage.isNotEmpty &&
                      !dosage.toLowerCase().contains('see product')) ...[
                    const SizedBox(height: 3),
                    Text(
                      dosage,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}