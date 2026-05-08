import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../models/user_data.dart';
import 'package:dosely/services/user_service.dart';
import 'package:dosely/data/health_data.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  List<String> selectedAllergies   = [];
  List<String> selectedChronic     = [];
  List<String> selectedMeds        = [];
  List<String> selectedSpecial     = [];
  bool _isLoading = false;

  // ── Computed from UserData (set in build) ──────────────────────────────────
  bool _isMale    = false;
  bool _isUnder65 = true;

  // ── Gender/age-aware special conditions filter ─────────────────────────────
  List<String> _filteredSpecialConditions() {
    return HealthData.specialConditions.where((item) {
      if (_isMale) {
        // Disable pregnancy / breastfeeding / trying to conceive for males
        if (item == 'Pregnant' ||
            item == 'Breastfeeding / Lactating' ||
            item == 'Trying to Conceive') return false;
      }
      if (_isUnder65) {
        if (item == 'Elderly (65+)') return false;
      }
      return true;
    }).toList();
  }

  List<String> _enforceNoneRule(List<String> prev, List<String> next) {
    if (!prev.contains('None') && next.contains('None')) return ['None'];
    if (prev.contains('None') && next.contains('None') && next.length > 1) {
      return next.where((e) => e != 'None').toList();
    }
    return next;
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final allergies = selectedAllergies.join(', ');
    final chronic   = selectedChronic.join(', ');
    final meds      = selectedMeds.join(', ');
    final special   = selectedSpecial.join(', ');

    try {
      await UserService.saveHealthInfo(
        allergies:          allergies.isEmpty  ? 'None' : allergies,
        chronicConditions:  chronic.isEmpty    ? 'None' : chronic,
        currentMedications: meds.isEmpty       ? 'None' : meds,
        specialConditions:  special.isEmpty    ? 'None' : special,
      );
      if (mounted) {
        Provider.of<UserData>(context, listen: false).updateHealthInfo(
          allergies: allergies, chronicConditions: chronic,
          currentMedications: meds, specialConditions: special,
        );
        Navigator.pushNamed(context, '/registerSuccess');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save health info: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserData>(context, listen: false);

    // Compute gender and age once per build
    _isMale = user.gender.toLowerCase() == 'male' ||
              user.gender.toLowerCase() == 'm';

    final dob = DateTime.tryParse(user.dob);
    if (dob != null) {
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      _isUnder65 = age < 65;
    }

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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primaryBlue),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),

                    // Header
                    Text(
                      'health_personalization'.tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'health_info_hint'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info banner
                    _infoBanner(
                      'Your health information helps us personalise safety checks '
                      'and medication warnings. You can update it anytime.',
                    ),
                    const SizedBox(height: 24),

                    // ── 1. Allergies ──────────────────────────────────────
                    _SectionHeader(
                      icon: Icons.no_food_rounded,
                      label: 'allergies'.tr(),
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 8),
                    _buildMultiDropdown(
                      hint: 'Select all that apply',
                      items: HealthData.allergies,
                      selected: selectedAllergies,
                      onChanged: (val) => setState(() {
                        selectedAllergies = _enforceNoneRule(selectedAllergies, val);
                      }),
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Chronic Conditions ─────────────────────────────
                    _SectionHeader(
                      icon: Icons.favorite_border_rounded,
                      label: 'chronic_conditions'.tr(),
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildMultiDropdown(
                      hint: 'Select all that apply',
                      items: HealthData.chronicConditions,
                      selected: selectedChronic,
                      onChanged: (val) => setState(() {
                        selectedChronic = _enforceNoneRule(selectedChronic, val);
                      }),
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Current Medications ────────────────────────────
                    _SectionHeader(
                      icon: Icons.medication_rounded,
                      label: 'current_medications'.tr(),
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 8),
                    _buildMultiDropdown(
                      hint: 'Select all that apply',
                      items: HealthData.medications,
                      selected: selectedMeds,
                      onChanged: (val) => setState(() {
                        selectedMeds = _enforceNoneRule(selectedMeds, val);
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Medication hint
                    _medicationHint(),
                    const SizedBox(height: 20),

                    // ── 4. Special Conditions ─────────────────────────────
                    _SectionHeader(
                      icon: Icons.person_pin_circle_rounded,
                      label: 'special_conditions'.tr(),
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildMultiDropdown(
                      hint: 'Select all that apply',
                      items: _filteredSpecialConditions(),
                      selected: selectedSpecial,
                      onChanged: (val) => setState(() {
                        selectedSpecial = _enforceNoneRule(selectedSpecial, val);
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            text: 'submit'.tr(),
                            onPressed: _submit,
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

  Widget _infoBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2E7D32),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicationHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: 16, color: AppColors.primaryBlue.withOpacity(0.8)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Can't find your medication in the list? You can add it later by "
              "searching by name, uploading a photo, or scanning its box.",
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
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
                color: isSelected ? AppColors.primaryBlue : Colors.grey.shade400,
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
          fillColor: Colors.grey.shade50,
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

// ── Reusable section header ────────────────────────────────────────────────────
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