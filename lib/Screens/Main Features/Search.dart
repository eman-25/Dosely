import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> medicines = [
    {
      'name': 'Panadol',
      'dosage': '500 mg',
      'description': 'Used to relieve pain and reduce fever.',
    },
    {
      'name': 'Augmentin',
      'dosage': '625 mg',
      'description': 'Antibiotic used to treat bacterial infections.',
    },
    {
      'name': 'Brufen',
      'dosage': '400 mg',
      'description': 'Used for pain, inflammation, and fever.',
    },
  ];

  List<Map<String, String>> filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    filteredMedicines = medicines;
  }

  void _searchMedicine(String query) {
    setState(() {
      filteredMedicines = medicines.where((medicine) {
        final name = medicine['name']!.toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Medicine'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _searchMedicine,
              decoration: InputDecoration(
                hintText: 'Enter medicine name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredMedicines.isEmpty
                  ? const Center(
                      child: Text(
                        'No medicine found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredMedicines.length,
                      itemBuilder: (context, index) {
                        final medicine = filteredMedicines[index];
                        return ListTile(
                          title: Text(medicine['name'] ?? ''),
                          subtitle: Text(
                            'Dosage: ${medicine['dosage']}\n${medicine['description']}',
                          ),
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