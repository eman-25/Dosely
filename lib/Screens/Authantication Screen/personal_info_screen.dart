import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../models/user_data.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'health_personalization'.tr(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'health_info_hint'.tr(),
                              style: const TextStyle(
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
                    _buildMultiDropdown(
                      label: 'allergies'.tr(),
                      items: const ["Peanuts", "Dust", "Latex", "Penicillin", "Shellfish", "None"],
                      selected: selectedAllergies,
                      onChanged: (val) => setState(() => selectedAllergies = val),
                    ),
                    _buildMultiDropdown(
                      label: 'chronic_conditions'.tr(),
                      items: const ["Diabetes", "Hypertension", "Asthma", "Arthritis", "Thyroid", "None"],
                      selected: selectedChronic,
                      onChanged: (val) => setState(() => selectedChronic = val),
                    ),
                    _buildMultiDropdown(
                      label: 'current_medications'.tr(),
                      items: const ["Aspirin", "Insulin", "Metformin", "Lisinopril", "Panadol", "None"],
                      selected: selectedMeds,
                      onChanged: (val) => setState(() => selectedMeds = val),
                    ),
                    _buildMultiDropdown(
                      label: 'special_conditions'.tr(),
                      items: const ["Pregnant", "Breastfeeding", "Post-surgery", "Elderly", "Child", "None"],
                      selected: selectedSpecial,
                      onChanged: (val) => setState(() => selectedSpecial = val),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'submit'.tr(),
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
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownSearch<String>.multiSelection(
            items: (filter, _) => items
                .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                .toList(),
            selectedItems: selected,
            onChanged: onChanged,
            popupProps: PopupPropsMultiSelection.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'search'.tr(),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                hintText: '${'select'.tr()} $label',
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