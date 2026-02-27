import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';

import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../models/user_data.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Store multiple selections
  List<String> selectedAllergies = [];
  List<String> selectedChronic = [];
  List<String> selectedMeds = [];
  List<String> selectedSpecial = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlue, AppColors.primaryGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "Health Personalization",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Info box (matches your mockup)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "This information helps Dosely provide safer and more accurate medication analysis and health predictions.",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF2E7D32),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dropdowns
                    _buildMultiDropdown(
                      label: "Allergies",
                      items: const ["Peanuts", "Dust", "Latex", "Penicillin", "Shellfish", "None"],
                      selected: selectedAllergies,
                      onChanged: (val) => setState(() => selectedAllergies = val),
                    ),
                    _buildMultiDropdown(
                      label: "Chronic Conditions",
                      items: const ["Diabetes", "Hypertension", "Asthma", "Arthritis", "Thyroid", "None"],
                      selected: selectedChronic,
                      onChanged: (val) => setState(() => selectedChronic = val),
                    ),
                    _buildMultiDropdown(
                      label: "Current Medications",
                      items: const ["Aspirin", "Insulin", "Metformin", "Lisinopril", "Panadol", "None"],
                      selected: selectedMeds,
                      onChanged: (val) => setState(() => selectedMeds = val),
                    ),
                    _buildMultiDropdown(
                      label: "Special Conditions (optional)",
                      items: const ["Pregnant", "Breastfeeding", "Post-surgery", "Elderly", "Child", "None"],
                      selected: selectedSpecial,
                      onChanged: (val) => setState(() => selectedSpecial = val),
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: "Submit",
                      onPressed: () {
                        final userData = Provider.of<UserData>(context, listen: false);

                        userData.updateHealthInfo(
                          allergies: selectedAllergies.join(', '),
                          chronicConditions: selectedChronic.join(', '),
                          currentMedications: selectedMeds.join(', '),
                          specialConditions: selectedSpecial.join(', '),
                        );

                        Navigator.pushNamed(context, '/registerSuccess');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiDropdown({
    required String label,
    required List<String> items,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownSearch<String>.multiSelection(
            items: (filter, _) => items
                .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                .toList(),
            selectedItems: selected,
            onChanged: onChanged,
            popupProps: const PopupPropsMultiSelection.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                hintText: "Select $label",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}