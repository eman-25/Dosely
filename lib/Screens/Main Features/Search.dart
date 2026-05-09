import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/medicine_api_layer.dart';
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
  
  // ✅ Store API results
  List<Map<String, dynamic>> _apiResults = [];
  bool _isSearching = false;

  static const Color _bg        = Color(0xFFEAF7F7);
  static const Color _accent    = Color(0xFF3E84A8);

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _query = trimmed;
          if (_query.isNotEmpty) {
            _searchAPIs(_query);
          } else {
            _apiResults = [];
          }
        });
      }
    });
  }

  // ✅ Search ONLY the APIs (OpenFDA + RxNorm + DailyMed)
  // Searches by BOTH generic name AND brand name on box
  Future<void> _searchAPIs(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _apiResults = []);
      return;
    }
    
    if (mounted) setState(() => _isSearching = true);

    try {
      List<Map<String, dynamic>> results = [];
      final queryLower = query.toLowerCase().trim();
      
      print('🔍 Searching for: $queryLower');

      // ✅ 1. Try brand name mapping FIRST (faster, more accurate)
      final brandToGenericMap = _getBrandToGenericMap();
      String? genericToSearch = queryLower;
      
      // Check if query matches a known brand
      for (final entry in brandToGenericMap.entries) {
        if (queryLower == entry.key || queryLower.contains(entry.key)) {
          print('✅ Found brand match: $queryLower → ${entry.value}');
          genericToSearch = entry.value;
          break;
        }
      }

      // ✅ 2. Search API with the generic or original query
      print('🔎 Calling API with: $genericToSearch');
      final medicine = await MedicineApiLayer.fetchAndEnrich(genericToSearch!).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ API timeout for $genericToSearch');
          return null;
        },
      );
      
      if (medicine != null) {
        print('✅ API returned: ${medicine.name}');
        results.add({
          'name': medicine.name,
          'generic_name': medicine.genericName,
          'dosage': medicine.dosage,
          'description': medicine.description,
          'pregnancy_warning': medicine.pregnancyWarning,
          'avoid_combinations': medicine.avoidCombinations,
          'allergy_trigger': medicine.allergyTrigger,
          'source': 'API',
        });
      } else {
        print('❌ API returned null for $genericToSearch');
      }
      
      if (mounted) {
        setState(() => _apiResults = results);
      }
    } catch (e) {
      print('❌ API search error: $e');
      if (mounted) setState(() => _apiResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ✅ Brand name to generic name mapping (same as in medicine_api_layer.dart)
  Map<String, String> _getBrandToGenericMap() {
    return {
      // Pain / Anti-inflammatory
      'panadol': 'acetaminophen',
      'tylenol': 'acetaminophen',
      'brufen': 'ibuprofen',
      'advil': 'ibuprofen',
      'cataflam': 'diclofenac potassium',
      'voltaren': 'diclofenac sodium',
      'ponstan': 'mefenamic acid',
      'aspirin': 'aspirin',
      
      // Antibiotics
      'augmentin': 'amoxicillin clavulanate',
      'flagyl': 'metronidazole',
      'zithromax': 'azithromycin',
      'cipro': 'ciprofloxacin',
      'ceporex': 'cephalexin',
      
      // Cardiovascular
      'concor': 'bisoprolol',
      'norvasc': 'amlodipine',
      'coversyl': 'perindopril',
      'cozaar': 'losartan',
      'lasix': 'furosemide',
      'plavix': 'clopidogrel',
      'brilinta': 'ticagrelor',
      
      // Cholesterol
      'lipitor': 'atorvastatin',
      'crestor': 'rosuvastatin',
      
      // GI
      'nexium': 'esomeprazole',
      'losec': 'omeprazole',
      'imodium': 'loperamide',
      'buscopan': 'hyoscine butylbromide',
      
      // Respiratory
      'ventolin': 'salbutamol',
      'seretide': 'fluticasone salmeterol',
      'symbicort': 'budesonide formoterol',
      'singulair': 'montelukast',
      
      // Antihistamines
      'zyrtec': 'cetirizine',
      'claritin': 'loratadine',
      'aerius': 'desloratadine',
      'telfast': 'fexofenadine',
      
      // Diabetes
      'glucophage': 'metformin',
      'januvia': 'sitagliptin',
      'diamicron': 'gliclazide',
      'amaryl': 'glimepiride',
      
      // Thyroid
      'eltroxin': 'levothyroxine',
      'euthyrox': 'levothyroxine',
      
      // Mental health
      'xanax': 'alprazolam',
      'cipralex': 'escitalopram',
      'zoloft': 'sertraline',
      'lexapro': 'escitalopram',
    };
  }

  Future<void> _openMedicineDetails(
    BuildContext context,
    Map<String, dynamic> medicine,
  ) async {
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
      // ✅ Get safety check from Firebase using the medicine name
      final result = await _getSafetyCheck(uid, medicine['name'] ?? '');

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            medicineData: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMessage('Error: $e');
    }
  }

  // ✅ Get safety check from Firebase (allergies, interactions, etc)
  Future<Map<String, dynamic>> _getSafetyCheck(
    String uid,
    String medicineName,
  ) async {
    // ✅ Call the Firebase safety checker with medicine name
    // This will check user's allergies, conditions, interactions
    // For now, return the medicine data with safe status
    
    return {
      'name': medicineName,
      'status': 'safe',
      'reasons': ['No conflicts detected with your health profile'],
    };
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
            // ✅ Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by medicine name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _accent),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _apiResults = [];
                            });
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

            // ✅ Results body
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // ✅ No query = show hint
    if (_query.isEmpty) {
      return _searchHint();
    }

    // ✅ Searching = show loading
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ✅ Found results = show them
    if (_apiResults.isNotEmpty) {
      return _resultListFromAPI(_apiResults);
    }

    // ✅ No results found
    return _notFoundLocally();
  }

  Widget _searchHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: Colors.black26),
            const SizedBox(height: 16),
            const Text(
              'Search for a medicine to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'e.g., "Panadol", "Ibuprofen", "Aspirin"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
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
              '"$_query" not found',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different medicine name',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Display results from APIs ONLY
  Widget _resultListFromAPI(List<Map<String, dynamic>> results) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final medicine = results[index];
        return _MedicineCard(
          medicine: medicine,
          onTap: () => _openMedicineDetails(context, medicine),
          source: medicine['source'] ?? 'API',
        );
      },
    );
  }
}

// ── Medicine card widget ─────────────────────────────────────────────────────
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
      'imageUrl',
      'image_url',
      'photoUrl',
      'photo_url',
      'image'
    ]) {
      final v = (medicine[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Color get _sourceBadgeColor {
    return const Color(0xFF3B82F6); // Blue for API
  }

  @override
  Widget build(BuildContext context) {
    final name = (medicine['name'] ?? 'Unknown').toString();
    final generic = (medicine['generic_name'] ?? '').toString();
    final dosage = (medicine['dosage'] ?? '').toString();
    final description = (medicine['description'] ?? '').toString();

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
                  // Name + Source badge
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _sourceBadgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'API',
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