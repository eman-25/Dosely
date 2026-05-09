import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/medicine_api_layer.dart';
import '../../services/firebase_medicine_checker.dart';
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
  
  List<Map<String, dynamic>> _apiResults = [];
  bool _isSearching = false;

  // ✅ Design colors matching your app
  static const Color _bg        = Color(0xFFF7FBFD);
  static const Color _accent    = Color(0xFF3E84A8);
  static const Color _safe      = Color(0xFF1B8A5A);
  static const Color _danger    = Color(0xFFDC2626);

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

  // ✅ Search ONLY the APIs
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

      // ✅ Try brand name mapping FIRST
      final brandToGenericMap = _getBrandToGenericMap();
      String? genericToSearch = queryLower;
      
      for (final entry in brandToGenericMap.entries) {
        if (queryLower == entry.key || queryLower.contains(entry.key)) {
          print('✅ Found brand match: $queryLower → ${entry.value}');
          genericToSearch = entry.value;
          break;
        }
      }

      // ✅ Search API
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
      // ✅ Get safety check from Firebase
      final result = await FirebaseMedicineChecker.checkByName(
        uid: uid,
        medicineName: medicine['name'] ?? '',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            medicineData: result ?? medicine,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Search Medicine',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
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
                  hintText: 'Search by medicine name',
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
      return _searchHint();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_apiResults.isNotEmpty) {
      return _resultListFromAPI(_apiResults);
    }

    return _notFoundLocally();
  }

  Widget _searchHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 56,
                color: _accent.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Search for a medicine',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'e.g., Panadol, Ibuprofen, Aspirin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: _danger.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '"$_query" not found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different medicine name',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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

  Future<void> _checkSafety() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _safetyStatus = 'safe');
        return;
      }

      // ✅ Quick safety check from Firebase
      final result = await FirebaseMedicineChecker.checkByName(
        uid: uid,
        medicineName: widget.medicine['name'] ?? '',
      ).timeout(const Duration(seconds: 5), onTimeout: () => null);

      if (mounted && result != null) {
        final status = result['status'] ?? 'safe';
        setState(() => _safetyStatus = status);
      } else if (mounted) {
        setState(() => _safetyStatus = 'safe');
      }
    } catch (e) {
      if (mounted) setState(() => _safetyStatus = 'safe');
    }
  }

  Color get _statusColor {
    switch (_safetyStatus) {
      case 'safe':
        return const Color(0xFF1B8A5A);
      case 'caution':
        return const Color(0xFFD97706);
      case 'not_safe':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade400;
    }
  }

  IconData get _statusIcon {
    switch (_safetyStatus) {
      case 'safe':
        return Icons.check_circle_rounded;
      case 'caution':
        return Icons.warning_amber_rounded;
      case 'not_safe':
        return Icons.cancel_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  String get _statusLabel {
    switch (_safetyStatus) {
      case 'safe':
        return 'Safe';
      case 'caution':
        return 'Caution';
      case 'not_safe':
        return 'Not Safe';
      default:
        return 'Checking...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.medicine['name'] ?? 'Unknown').toString();
    final generic = (widget.medicine['generic_name'] ?? '').toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ✅ Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E84A8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Color(0xFF3E84A8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              
              // ✅ Name + Generic (left side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (generic.isNotEmpty && generic != name) ...[
                      const SizedBox(height: 2),
                      Text(
                        generic,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ✅ Safety badge (right side)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon,
                      color: _statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}