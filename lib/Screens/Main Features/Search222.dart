import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/medicine_service.dart';
import '../../models/user_data.dart';
import 'package:provider/provider.dart';
import 'medicine_result_screen.dart';

class Search extends StatefulWidget {
  const Search({super.key});
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _ctrl = TextEditingController();
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => history = prefs.getStringList('dosely_search_history') ?? []);
  }

  Future<void> _saveToHistory(String term) async {
    final prefs = await SharedPreferences.getInstance();
    history.remove(term);
    history.insert(0, term);
    if (history.length > 8) history.removeLast();
    await prefs.setStringList('dosely_search_history', history);
  }

  Future<void> _performSearch(String name) async {
    if (name.trim().isEmpty) return;
    await _saveToHistory(name.trim());

    final data = await MedicineService.fetchMedicineInfo(name.trim());
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineResultScreen(
            medicineData: data,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'e.g. Panadol Extra, Augmentin',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_ctrl.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 24),
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(history[i]),
                  onTap: () => _performSearch(history[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}