// lib/screens/edit_personalhealthinfo.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/user_data.dart';
import '../../Widgets/custom_button.dart';
import '/theme.dart';

class EditPersonalHealthInfoScreen extends StatefulWidget {
  const EditPersonalHealthInfoScreen({super.key});

  @override
  State<EditPersonalHealthInfoScreen> createState() => _EditPersonalHealthInfoScreenState();
}

class _EditPersonalHealthInfoScreenState extends State<EditPersonalHealthInfoScreen> {
  String? _allergies;
  String? _chronic;
  String? _medications;
  String? _special;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserData>(context, listen: false);

    // Take first value if multiple were saved (comma-separated)
    _allergies = user.allergies.isNotEmpty ? user.allergies.split(',').first.trim() : null;
    _chronic = user.chronicConditions.isNotEmpty ? user.chronicConditions.split(',').first.trim() : null;
    _medications = user.currentMedications.isNotEmpty ? user.currentMedications.split(',').first.trim() : null;
    _special = user.specialConditions.isNotEmpty ? user.specialConditions.split(',').first.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Health Information',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner (matches mockup)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This information helps Dosely provide safer and more accurate medication analysis and health predictions.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Health Personalization',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),

            // 1. Allergies
            _buildDropdown(
              label: "Allergies",
              items: const ['Peanuts', 'Dairy', 'Shellfish', 'Pollen', 'Penicillin', 'None'],
              selected: _allergies,
              onChanged: (v) => setState(() => _allergies = v),
            ),
            const SizedBox(height: 16),

            // 2. Chronic Conditions
            _buildDropdown(
              label: "Chronic Conditions",
              items: const ['Asthma', 'Diabetes', 'Hypertension', 'Thyroid', 'None'],
              selected: _chronic,
              onChanged: (v) => setState(() => _chronic = v),
            ),
            const SizedBox(height: 16),

            // 3. Current Medications
            _buildDropdown(
              label: "Current Medications",
              items: const ['Panadol', 'Metformin', 'Insulin', 'Amlodipine', 'None'],
              selected: _medications,
              onChanged: (v) => setState(() => _medications = v),
            ),
            const SizedBox(height: 16),

            // 4. Special Conditions
            _buildDropdown(
              label: "Special Conditions (optional)",
              items: const ['Pregnancy', 'Lactation', 'Elderly', 'Child', 'None'],
              selected: _special,
              onChanged: (v) => setState(() => _special = v),
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: "Save changes",
              onPressed: () {
                final userData = Provider.of<UserData>(context, listen: false);
                userData.updateHealthInfo(
                  allergies: _allergies,
                  chronicConditions: _chronic,
                  currentMedications: _medications,
                  specialConditions: _special,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Health information saved')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Reusable clean dropdown (new v6+ syntax)
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) => items
          .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItem: selected,
      onChanged: onChanged,
      popupProps: const PopupProps.menu(
        showSearchBox: true,
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}