import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final special   = selectedSpecial.join(', ');

    try {
      await UserService.updateHealthInfo(
        allergies:          allergies.isEmpty ? 'None' : allergies,
        chronicConditions:  chronic.isEmpty   ? 'None' : chronic,
        currentMedications: 'None',
        specialConditions:  special.isEmpty   ? 'None' : special,
      );
      if (mounted) {
        Provider.of<UserData>(context, listen: false).updateHealthInfo(
          allergies: allergies, chronicConditions: chronic,
          currentMedications: '', specialConditions: special,
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
          overflow: TextOverflow.ellipsis,
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

            // ── 3. Special Conditions ───────────────────────────────────
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
    return GestureDetector(
      onTap: () => _showCustomBottomSheet(
        hint: hint,
        items: items,
        currentSelection: selected,
        onChanged: onChanged,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: selected.isEmpty
                  ? Text(
                      hint,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selected.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.grey.shade600,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomBottomSheet({
    required String hint,
    required List<String> items,
    required List<String> currentSelection,
    required Function(List<String>) onChanged,
  }) {
    List<String> tempSelection = List.from(currentSelection);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = items
                .where((i) =>
                    i.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (tempSelection.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${tempSelection.length} selected',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'search'.tr(),
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = tempSelection.contains(item);
                        final hasNone = tempSelection.contains('None');
                        final isDisabledByNone = hasNone && item != 'None';

                        return Opacity(
                          opacity: isDisabledByNone ? 0.4 : 1.0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isDisabledByNone
                                  ? null
                                  : () {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelection.remove(item);
                                        } else {
                                          if (item == 'None') {
                                            tempSelection = ['None'];
                                          } else {
                                            tempSelection.remove('None');
                                            tempSelection.add(item);
                                          }
                                        }
                                      });
                                      onChanged(List.from(tempSelection));
                                    },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryBlue
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryBlue
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded,
                                              size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: item == 'None'
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: item == 'None'
                                              ? Colors.grey.shade700
                                              : (isSelected
                                                  ? AppColors.primaryBlue
                                                  : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'done'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.7)),
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
            color: color.withValues(alpha: 0.10),
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