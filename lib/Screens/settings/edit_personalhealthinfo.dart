import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/user_data.dart';
import 'package:dosely/services/user_service.dart';
import 'package:dosely/data/health_data.dart';
import '../../Widgets/custom_button.dart';
import '/theme.dart';

class EditPersonalHealthInfoScreen extends StatefulWidget {
  const EditPersonalHealthInfoScreen({super.key});

  @override
  State<EditPersonalHealthInfoScreen> createState() =>
      _EditPersonalHealthInfoScreenState();
}

class _EditPersonalHealthInfoScreenState
    extends State<EditPersonalHealthInfoScreen> {
  List<String> selectedAllergies = [];
  List<String> selectedChronic = [];
  List<String> selectedMeds = [];
  List<String> selectedSpecial = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserData>(context, listen: false);

    selectedAllergies = _splitToList(user.allergies);
    selectedChronic = _splitToList(user.chronicConditions);
    selectedMeds = _splitToList(user.currentMedications);
    selectedSpecial = _splitToList(user.specialConditions);
  }

  List<String> _splitToList(String value) {
    if (value.isEmpty) return [];
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<String> _enforceNoneRule(List<String> prev, List<String> next) {
    final prevHadNone = prev.contains('None');
    final nextHasNone = next.contains('None');

    if (!prevHadNone && nextHasNone) {
      return ['None'];
    }
    if (prevHadNone && nextHasNone && next.length > 1) {
      return next.where((e) => e != 'None').toList();
    }
    return next;
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    final allergies = selectedAllergies.join(', ');
    final chronic = selectedChronic.join(', ');
    final meds = selectedMeds.join(', ');
    final special = selectedSpecial.join(', ');

    try {
      await UserService.updateHealthInfo(
        allergies: allergies.isEmpty ? 'None' : allergies,
        chronicConditions: chronic.isEmpty ? 'None' : chronic,
        currentMedications: meds.isEmpty ? 'None' : meds,
        specialConditions: special.isEmpty ? 'None' : special,
      );

      if (mounted) {
        final userData = Provider.of<UserData>(context, listen: false);
        userData.updateHealthInfo(
          allergies: allergies,
          chronicConditions: chronic,
          currentMedications: meds,
          specialConditions: special,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('health_info_saved'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: Text(
          'personal_health_info'.tr(),
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'health_info_hint'.tr(),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('health_personalization'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),

            _buildMultiDropdown(
              label: 'allergies'.tr(),
              items: HealthData.allergies,
              selected: selectedAllergies,
              onChanged: (val) => setState(() => selectedAllergies = _enforceNoneRule(selectedAllergies, val)),
            ),
            const SizedBox(height: 16),

            _buildMultiDropdown(
              label: 'chronic_conditions'.tr(),
              items: HealthData.chronicConditions,
              selected: selectedChronic,
              onChanged: (val) => setState(() => selectedChronic = _enforceNoneRule(selectedChronic, val)),
            ),
            const SizedBox(height: 16),

            _buildMultiDropdown(
              label: 'current_medications'.tr(),
              items: HealthData.medications,
              selected: selectedMeds,
              onChanged: (val) => setState(() => selectedMeds = _enforceNoneRule(selectedMeds, val)),
            ),
            const SizedBox(height: 16),

            _buildMultiDropdown(
              label: 'special_conditions'.tr(),   // ← Clean, no "(optional)"
              items: HealthData.specialConditions,
              selected: selectedSpecial,
              onChanged: (val) => setState(() => selectedSpecial = _enforceNoneRule(selectedSpecial, val)),
            ),

            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: 'save_changes'.tr(),
                    onPressed: _saveChanges,
                  ),
          ],
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
    return DropdownSearch<String>.multiSelection(
      items: (filter, _) => items
          .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItems: selected,
      onChanged: onChanged,
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        constraints: const BoxConstraints(maxHeight: 350),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'search'.tr(),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(
          leading: Icon(
            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: isSelected ? AppColors.primaryBlue : Colors.grey,
          ),
          title: Text(
            item,
            style: TextStyle(
              fontWeight: item == 'None' ? FontWeight.bold : FontWeight.normal,
              color: item == 'None' ? Colors.grey.shade700 : Colors.black87,
            ),
          ),
        ),
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}