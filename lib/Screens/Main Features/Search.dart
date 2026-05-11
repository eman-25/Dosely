import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/medicine_api_layer.dart';
import '../../services/firebase_medicine_checker.dart';
import '../../services/trending_service.dart';
import 'medicine_result_screen.dart';
import 'Upload.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  
  List<Map<String, dynamic>> _apiResults = [];
  bool _isSearching = false;
  List<String> _trendingMeds = [];
  List<String> _recentSearches = [];
  bool _showReminder = true;

  // ✅ Design colors matching your app
  static const Color _bg        = Color(0xFFF7FBFD);
  static const Color _accent    = Color(0xFF3E84A8);
  static const Color _safe      = Color(0xFF1B8A5A);
  static const Color _danger    = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _loadTrendingMeds();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Load trending medicines ──────────────────────────────
  Future<void> _loadTrendingMeds() async {
    final trending = await TrendingService.getTopTrendingNames();
    if (mounted) {
      setState(() => _trendingMeds = trending);
    }
  }

  // ── Load recent searches from SharedPreferences ──────────
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? [];
    if (mounted) {
      setState(() => _recentSearches = recent.take(5).toList());
    }
  }

  // ── Save search to recent list ──────────────────────────
  Future<void> _saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? [];
    
    // Remove if already exists (to avoid duplicates)
    recent.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    
    // Add to front
    recent.insert(0, query);
    
    // Keep only 10 most recent
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }
    
    await prefs.setStringList('recent_searches', recent);
    
    if (mounted) {
      setState(() => _recentSearches = recent.take(5).toList());
    }
  }

  // ── Clear all recent searches ──────────────────────────
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) {
      setState(() => _recentSearches = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('recent_searches'.tr())),
      );
    }
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

  // Search APIs + Firestore, then run real safety checks
  Future<void> _searchAPIs(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _apiResults = []);
      return;
    }

    if (mounted) setState(() => _isSearching = true);

    try {
      final queryLower = query.toLowerCase().trim();

      // Brand → generic mapping
      final brandToGenericMap = _getBrandToGenericMap();
      String genericToSearch = queryLower;
      for (final entry in brandToGenericMap.entries) {
        if (queryLower == entry.key || queryLower.contains(entry.key)) {
          genericToSearch = entry.value;
          break;
        }
      }

      // Run API search and Firestore search in parallel
      final futures = await Future.wait([
        MedicineApiLayer.fetchAndEnrich(genericToSearch).timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        ),
        _searchFirestore(query),
      ]);

      final apiMed = futures[0] as dynamic;
      final firestoreMeds = futures[1] as List<Map<String, dynamic>>;

      final seen = <String>{};
      final results = <Map<String, dynamic>>[];

      if (apiMed != null) {
        final m = apiMed;
        final name = (m.name as String).toLowerCase();
        if (seen.add(name)) {
          results.add({
            'name': m.name,
            'generic_name': m.genericName,
            'dosage': m.dosage,
            'description': m.description,
            'pregnancy_warning': m.pregnancyWarning,
            'avoid_combinations': m.avoidCombinations,
            'allergy_trigger': m.allergyTrigger,
          });
        }
      }

      for (final med in firestoreMeds) {
        final name = ((med['name'] as String?) ?? '').toLowerCase();
        if (name.isNotEmpty && seen.add(name)) {
          results.add(med);
        }
      }

      if (results.isNotEmpty) await _saveSearch(query);

      // Run safety checks for all results in parallel
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && results.isNotEmpty) {
        final safetyFutures = results.map((r) =>
          FirebaseMedicineChecker.checkByName(
            uid: uid,
            medicineName: (r['name'] as String? ?? '').isNotEmpty
                ? r['name'] as String
                : r['generic_name'] as String? ?? '',
          ).catchError((_) => null),
        );
        final safetyList = await Future.wait(safetyFutures);
        for (int i = 0; i < results.length; i++) {
          final safety = safetyList[i];
          if (safety != null) {
            results[i] = {
              ...results[i],
              'status': safety['status'] ?? 'unknown',
              'reasons': safety['reasons'] ?? <String>[],
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          _apiResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  // Search the Firestore medicines collection by name / generic_name prefix
  Future<List<Map<String, dynamic>>> _searchFirestore(String query) async {
    if (query.trim().length < 2) return [];
    final db = FirebaseFirestore.instance;
    final cap = query.trim()[0].toUpperCase() + query.trim().substring(1).toLowerCase();
    final end = cap + '';
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    Future<void> addDocs(QuerySnapshot<Map<String, dynamic>> snap) async {
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        if (name.isNotEmpty && seen.add(name)) {
          results.add(_firestoreDocToMap(data));
        }
      }
    }

    try {
      await Future.wait([
        db.collection('medicines')
            .orderBy('name')
            .startAt([cap]).endAt([end])
            .limit(4)
            .get()
            .then(addDocs),
        db.collection('medicines')
            .orderBy('generic_name')
            .startAt([cap]).endAt([end])
            .limit(4)
            .get()
            .then(addDocs),
      ]);
    } catch (_) {}

    return results;
  }

  Map<String, dynamic> _firestoreDocToMap(Map<String, dynamic> d) => {
    'name': d['name'] ?? '',
    'generic_name': d['generic_name'] ?? '',
    'dosage': d['dosage'] ?? '',
    'description': d['description'] ?? '',
    'pregnancy_warning': d['pregnancy_warning'] ?? 'none',
    'avoid_combinations': List<String>.from(d['avoid_combinations'] ?? []),
    'allergy_trigger': d['allergy_trigger'] ?? '',
  };

  void _openMedicineDetails(BuildContext context, Map<String, dynamic> medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineResultScreen(
          imagePath: '',
          ocrText: medicine['generic_name'] ?? medicine['name'] ?? '',
          medicineData: medicine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'search_medication'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: _bg,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Modern search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'search_medicine_above'.tr(),
                  hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                  prefixIcon: const Icon(Icons.search_rounded, 
                      color: _accent, size: 24),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, color: _accent),
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
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _accent,
                      width: 2,
                    ),
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
    if (_query.isEmpty) {
      return _emptyState();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_apiResults.isNotEmpty) {
      return _resultListFromAPI(_apiResults);
    }

    return _notFoundState();
  }

  // ── Empty state with trending & recent searches ──────────
  Widget _emptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reminder banner (can be dismissed) ──
          if (_showReminder)
            _buildReminder(),
          
          const SizedBox(height: 24),

          // ── Trending medicines ──
          if (_trendingMeds.isNotEmpty) ...[
            Text(
              'trending'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingMeds
                  .map((med) => _trendingChip(med))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ── Recent searches ──
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'recent_searches'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    'clear'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: _recentSearches
                  .map((search) => _recentSearchItem(search))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Reminder banner ──────────────────────────────────────
  Widget _buildReminder() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outlined, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'search_reminder_title'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'search_reminder_desc'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Upload()),
                          );
                        },
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: Text('upload_btn'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _showReminder = false),
                      color: const Color(0xFF92400E),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Trending medicine chip ──────────────────────────────
  Widget _trendingChip(String med) {
    return GestureDetector(
      onTap: () {
        _searchController.text = med;
        _onSearchChanged(med);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withOpacity(0.2)),
        ),
        child: Text(
          med,
          style: const TextStyle(
            color: _accent,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Recent search item ──────────────────────────────────
  Widget _recentSearchItem(String search) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history_rounded, size: 18, color: Colors.grey),
      title: Text(search, style: const TextStyle(fontSize: 14)),
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final recent = prefs.getStringList('recent_searches') ?? [];
          recent.remove(search);
          await prefs.setStringList('recent_searches', recent);
          setState(() => _recentSearches = recent.take(5).toList());
        },
      ),
      onTap: () {
        _searchController.text = search;
        _onSearchChanged(search);
      },
    );
  }

  // ── Not found state ────────────────────────────────────
  Widget _notFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: _danger.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '"$_query" ' + 'more_info'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'search_reminder_upload'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Upload()),
                );
              },
              icon: const Icon(Icons.upload_rounded),
              label: Text('upload_btn'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Modern minimal list - name + safety status only
  Widget _resultListFromAPI(List<Map<String, dynamic>> results) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final medicine = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ModernMedicineCard(
            medicine: medicine,
            onTap: () => _openMedicineDetails(context, medicine),
          ),
        );
      },
    );
  }

  // ── Brand to generic name mapping ──────────────────────
  Map<String, String> _getBrandToGenericMap() {
    return {
      'panadol': 'acetaminophen',
      'tylenol': 'acetaminophen',
      'brufen': 'ibuprofen',
      'advil': 'ibuprofen',
      'cataflam': 'diclofenac potassium',
      'voltaren': 'diclofenac sodium',
      'ponstan': 'mefenamic acid',
      'aspirin': 'aspirin',
      'augmentin': 'amoxicillin clavulanate',
      'flagyl': 'metronidazole',
      'zithromax': 'azithromycin',
      'cipro': 'ciprofloxacin',
      'ceporex': 'cephalexin',
      'concor': 'bisoprolol',
      'norvasc': 'amlodipine',
      'coversyl': 'perindopril',
      'cozaar': 'losartan',
      'lasix': 'furosemide',
      'plavix': 'clopidogrel',
      'brilinta': 'ticagrelor',
      'lipitor': 'atorvastatin',
      'crestor': 'rosuvastatin',
      'nexium': 'esomeprazole',
      'losec': 'omeprazole',
      'imodium': 'loperamide',
      'buscopan': 'hyoscine butylbromide',
      'ventolin': 'salbutamol',
      'seretide': 'fluticasone salmeterol',
      'symbicort': 'budesonide formoterol',
      'singulair': 'montelukast',
      'zyrtec': 'cetirizine',
      'claritin': 'loratadine',
      'aerius': 'desloratadine',
      'telfast': 'fexofenadine',
      'glucophage': 'metformin',
      'januvia': 'sitagliptin',
      'diamicron': 'gliclazide',
      'amaryl': 'glimepiride',
      'eltroxin': 'levothyroxine',
      'euthyrox': 'levothyroxine',
      'xanax': 'alprazolam',
      'cipralex': 'escitalopram',
      'zoloft': 'sertraline',
      'lexapro': 'escitalopram',
    };
  }
}

// ✅ Modern medicine card - minimal design
class _ModernMedicineCard extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onTap;

  const _ModernMedicineCard({
    required this.medicine,
    required this.onTap,
  });

  @override
  State<_ModernMedicineCard> createState() => _ModernMedicineCardState();
}

class _ModernMedicineCardState extends State<_ModernMedicineCard> {
  String _safetyStatus = 'checking'; // checking, safe, caution, not_safe

  @override
  void initState() {
    super.initState();
    _checkSafety();
  }

  void _checkSafety() {
    // Status is computed by _searchAPIs before results are shown
    final status = (widget.medicine['status'] as String? ?? 'unknown').toLowerCase();
    setState(() => _safetyStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    const Color _accent = Color(0xFF3E84A8);
    const Color _safe = Color(0xFF1B8A5A);
    const Color _danger = Color(0xFFDC2626);
    const Color _warning = Color(0xFFF59E0B);

    Color safetyColor = Colors.grey;
    IconData safetyIcon = Icons.help_outline_rounded;

    switch (_safetyStatus) {
      case 'safe':
        safetyColor = _safe;
        safetyIcon = Icons.check_circle_rounded;
        break;
      case 'caution':
        safetyColor = _warning;
        safetyIcon = Icons.warning_rounded;
        break;
      case 'not safe':
      case 'not_safe':
        safetyColor = _danger;
        safetyIcon = Icons.cancel_rounded;
        break;
      default:
        safetyColor = Colors.grey.shade400;
        safetyIcon = Icons.help_outline_rounded;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.medicine['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.medicine['generic_name'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(safetyIcon, color: safetyColor, size: 24),
          ],
        ),
      ),
    );
  }
}