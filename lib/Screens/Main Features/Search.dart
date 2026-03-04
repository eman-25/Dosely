import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/medicine_service.dart';
import '../../models/user_data.dart';
import 'medicine_result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _recent = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _showRecent = false;
  String _query = '';
  Timer? _debounce;

  static const c1 = Color(0xFF48466E);
  static const c2 = Color(0xFF3E84A8);
  static const c3 = Color(0xFF4ACED0);
  static const c4 = Color(0xFFACEDD9);
  static const c5 = Color(0xFFE0FBF4);

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recent.clear();
      _recent.addAll(prefs.getStringList('dosely_search_history') ?? []);
    });
  }

  Future<void> _saveRecentSearch(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recent.remove(term);
    _recent.insert(0, term);
    if (_recent.length > 8) _recent.removeLast();
    await prefs.setStringList('dosely_search_history', _recent);
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.length >= 2) _performSearch(value);
    });
  }

  Future<void> _performSearch(String name) async {
    if (name.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await _saveRecentSearch(name.trim());
    final result = await MedicineService.fetchMedicineInfo(name.trim());
    setState(() {
      _searchResults = [result];
      _isLoading = false;
    });
  }

  void _useRecent(String text) {
    _controller.text = text;
    _onSearchChanged(text);
    setState(() => _showRecent = false);
  }

  void _selectMedicine(Map<String, dynamic> medicine) {
    final userData = Provider.of<UserData>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineResultScreen(
          medicineData: medicine,
          userData: userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [c1, c2, c3, c4, c5],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.hintColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: _onSearchChanged,
                            onSubmitted: _performSearch,
                            decoration: InputDecoration(
                              hintText: 'search_medication'.tr(),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _searchResults.clear();
                            });
                          },
                          child: Icon(Icons.close, size: 18, color: theme.hintColor),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => setState(() => _showRecent = !_showRecent),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.menu, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildRecentPanel(theme),
              crossFadeState: _showRecent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            'search_medicine_above'.tr(),
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemBuilder: (context, i) {
                            final m = _searchResults[i];
                            final title = m['brand_name'] ?? m['openfda']?['brand_name']?[0] ?? 'unknown'.tr();
                            final desc = m['purpose']?.toString() ?? 'no_description'.tr();
                            return _buildMedicineCard(title, desc, theme);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('recent_searches'.tr(), style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () => setState(() => _recent.clear()),
                child: Text('clear'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent.map((r) {
              return ActionChip(
                label: Text(r),
                onPressed: () => _useRecent(r),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(String title, String desc, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        final medicine = _searchResults.firstWhere(
          (m) => (m['brand_name'] ?? '').toString() == title,
          orElse: () => _searchResults.first,
        );
        _selectMedicine(medicine);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.medication, size: 50, color: Color(0xFF4ACED0)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(desc, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: Text('more_info'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}