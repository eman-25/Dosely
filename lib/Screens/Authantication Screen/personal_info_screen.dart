import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Lists to hold the data selected by the user
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
            colors: [AppColors.primaryBlue, AppColors.primaryGreen],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // FIX: Added IconButton with Navigator.pop
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                  const Text("Health Personalization",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  const Text(
                    "This information helps Dosely provide safer and more accurate medication analysis.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 10),
                  ),
                  const SizedBox(height: 20),

                  // 1. Allergies
                  _buildDropdown("Allergies", ["Peanuts", "Dust", "Latex", "Penicillin"], (val) => selectedAllergies = val),
                  
                  // 2. Chronic Conditions
                  _buildDropdown("Chronic Conditions", ["Diabetes", "Hypertension", "Asthma", "Arthritis"], (val) => selectedChronic = val),

                  // 3. Current Medications
                  _buildDropdown("Current Medications", ["Aspirin", "Insulin", "Metformin", "Lisinopril"], (val) => selectedMeds = val),

                  // 4. Special Conditions (Optional)
                  _buildDropdown("Special Conditions (optional)", ["Pregnant", "Breastfeeding", "Post-surgery"], (val) => selectedSpecial = val),

                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Submit",
                    onPressed: () {
                      // Access all selected data here
                      print("Allergies: $selectedAllergies");
                      print("Chronic: $selectedChronic");
                      print("Meds: $selectedMeds");
                      print("Special: $selectedSpecial");
                      Navigator.pushNamed(context, '/registerSuccess');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Common Widget for all 4 dropdowns - Corrected Syntax
  Widget _buildDropdown(String label, List<String> dataList, Function(List<String>) onSelectionChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          DropdownSearch<String>.multiSelection(
            // Use the dataList passed to the function
            items: (filter, infiniteScrollProps) => 
                dataList
                    .where((i) => i.toLowerCase().contains(filter.toLowerCase()))
                    .toList(),
            
            // Correctly placed onChanged within the widget
            onChanged: (List<String> selectedItems) {
              onSelectionChanged(selectedItems);
            },

            popupProps: PopupPropsMultiSelection.menu(
              showSearchBox: true, 
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search $label...",
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),

            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                hintText: "Select $label",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}