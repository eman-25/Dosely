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
  List<String> selectedChronic   = [];
  List<String> selectedMeds      = [];
  List<String> selectedSpecial   = [];
  bool _isLoading = false;
  bool _isMale    = false;
  bool _isUnder65 = true;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserData>(context, listen: false);

    selectedAllergies = _splitToList(user.allergies);
    selectedChronic   = _splitToList(user.chronicConditions);
    selectedMeds      = _splitToList(user.currentMedications);
    selectedSpecial   = _splitToList(user.specialConditions);

    _isMale = user.gender.toLowerCase() == 'male' ||
              user.gender.toLowerCase() == 'm';

    final dob = DateTime.tryParse(user.dob);
    if (dob != null) {
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      _isUnder65 = age < 65;
    }
  }

  List<String> _splitToList(String value) => value.isEmpty
      ? []
      : value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  List<String> _enforceNoneRule(List<String> prev, List<String> next) {
    if (!prev.contains('None') && next.contains('None')) return ['None'];
    if (prev.contains('None') && next.contains('None') && next.length > 1) {
      return next.where((e) => e != 'None').toList();
    }
    return next;
  }

  List<String> _filteredSpecialConditions() {
    return HealthData.specialConditions.where((item) {
      if (_isMale) {
        if (item == 'Pregnant' ||
            item == 'Breastfeeding / Lactating' ||
            item == 'Trying to Conceive') return false;
      }
      if (_isUnder65 && item == 'Elderly (65+)') return false;
      return true;
    }).toList();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final allergies = selectedAllergies.join(', ');
    final chronic   = selectedChronic.join(', ');
    final meds      = selectedMeds.join(', ');
    final special   = selectedSpecial.join(', ');

    try {
      await UserService.updateHealthInfo(
        allergies:          allergies.isEmpty ? 'None' : allergies,
        chronicConditions:  chronic.isEmpty   ? 'None' : chronic,
        currentMedications: meds.isEmpty      ? 'None' : meds,
        specialConditions:  special.isEmpty   ? 'None' : special,
      );
      if (mounted) {
        Provider.of<UserData>(context, listen: false).updateHealthInfo(
          allergies: allergies, chronicConditions: chronic,
          currentMedications: meds, specialConditions: special,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('health_info_saved'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_save'.tr())),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'personal_health_info'.tr(),
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 20-day update reminder ──────────────────────────────────
            _UpdateReminderBanner(),
            const SizedBox(height: 16),

            // ── Info banner ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF2E7D32), size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'health_info_hint'.tr(),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF2E7D32), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 1. Allergies ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.no_food_rounded,
              label: 'allergies'.tr(),
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 8),
            _buildMultiDropdown(
              hint: 'select'.tr(),
              items: HealthData.allergies,
              selected: selectedAllergies,
              onChanged: (val) => setState(
                  () => selectedAllergies = _enforceNoneRule(selectedAllergies, val)),
            ),
            const SizedBox(height: 20),

            // ── 2. Chronic Conditions ───────────────────────────────────
            _SectionHeader(
              icon: Icons.favorite_border_rounded,
              label: 'chronic_conditions'.tr(),
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildMultiDropdown(
              hint: 'select'.tr(),
              items: HealthData.chronicConditions,
              selected: selectedChronic,
              onChanged: (val) => setState(
                  () => selectedChronic = _enforceNoneRule(selectedChronic, val)),
            ),
            const SizedBox(height: 20),

            // ── 3. Current Medications ──────────────────────────────────
            _SectionHeader(
              icon: Icons.medication_rounded,
              label: 'current_medications'.tr(),
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 8),
            _buildMultiDropdown(
              hint: 'select'.tr(),
              items: HealthData.medications,
              selected: selectedMeds,
              onChanged: (val) => setState(
                  () => selectedMeds = _enforceNoneRule(selectedMeds, val)),
            ),
            const SizedBox(height: 8),
            // Medication hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 15,
                      color: AppColors.primaryBlue.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Can't find your medication in the list? You can add it "
                      'by searching by name, uploading a photo, or scanning its box.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 4. Special Conditions ───────────────────────────────────
            _SectionHeader(
              icon: Icons.person_pin_circle_rounded,
              label: 'special_conditions'.tr(),
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            _buildMultiDropdown(
              hint: 'select'.tr(),
              items: _filteredSpecialConditions(),
              selected: selectedSpecial,
              onChanged: (val) => setState(
                  () => selectedSpecial = _enforceNoneRule(selectedSpecial, val)),
            ),
            const SizedBox(height: 36),

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
    required String hint,
    required List<String> items,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return DropdownSearch<String>.multiSelection(
      items: (filter, _) => items
          .where((i) => i.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItems: selected,
      onChanged: onChanged,
      popupProps: PopupPropsMultiSelection.modalBottomSheet(
        showSearchBox: true,
        modalBottomSheetProps: const ModalBottomSheetProps(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        constraints: const BoxConstraints(maxHeight: 520),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'search'.tr(),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(
          dense: true,
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          title: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              fontWeight: item == 'None' ? FontWeight.w700 : FontWeight.normal,
              color: item == 'None' ? Colors.grey.shade600 : Colors.black87,
            ),
          ),
        ),
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── 60-day update reminder banner ─────────────────────────────────────────────
class _UpdateReminderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.update_rounded, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep your health data up to date',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'For consistently accurate safety results, please review and '
                  'confirm your health information every 60 days — especially if '
                  'your medications or conditions have changed.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF92400E),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}