import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/theme.dart';
import '../../models/user_data.dart';
import 'package:dosely/services/user_service.dart';
import 'package:dosely/data/health_data.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;

  List<String> selectedAllergies = [];
  List<String> selectedChronic = [];
  List<String> selectedSpecial = [];

  bool _isMale = false;
  bool _isUnder65 = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> _filteredSpecialConditions() {
    return HealthData.specialConditions.where((item) {
      if (_isMale) {
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

  Future<void> _nextStep() async {
    if (_currentStep == 0 && selectedAllergies.isEmpty) {
      _showSnackBar('Please select at least one option');
      return;
    }
    if (_currentStep == 1 && selectedChronic.isEmpty) {
      _showSnackBar('Please select at least one option');
      return;
    }
    if (_currentStep == 2 && selectedSpecial.isEmpty) {
      _showSnackBar('Please select at least one option');
      return;
    }

    if (_currentStep == 2) {
      await _submitHealthData();
    } else {
      _animationController.reset();
      setState(() => _currentStep++);
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() => _currentStep--);
      _animationController.forward();
    }
  }

  Future<void> _submitHealthData() async {
    setState(() => _isLoading = true);

    final allergies = selectedAllergies.join(', ');
    final chronic = selectedChronic.join(', ');
    final special = selectedSpecial.join(', ');

    try {
      await UserService.saveHealthInfo(
        allergies: allergies.isEmpty ? 'None' : allergies,
        chronicConditions: chronic.isEmpty ? 'None' : chronic,
        currentMedications: 'None',
        specialConditions: special.isEmpty ? 'None' : special,
      );

      if (mounted) {
        Provider.of<UserData>(context, listen: false).updateHealthInfo(
          allergies: allergies,
          chronicConditions: chronic,
          currentMedications: '',
          specialConditions: special,
        );

        setState(() => _currentStep = 4);
        _animationController.reset();
        _animationController.forward();

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to save health info: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserData>(context, listen: false);

    _isMale = user.gender.toLowerCase() == 'male' || user.gender.toLowerCase() == 'm';
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
          child: _currentStep == 4 ? _buildSuccessScreen() : _buildStepScreen(),
        ),
      ),
    );
  }

  Widget _buildStepScreen() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(_animationController),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(_animationController),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProgressBar(),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep == 0) _buildAllergyStep(),
                    if (_currentStep == 1) _buildChronicStep(),
                    if (_currentStep == 2) _buildSpecialStep(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: _buildNavigationButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of 3',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Step 1: Allergies
  Widget _buildAllergyStep() {
    return _buildStepCard(
      icon: Icons.no_food_rounded,
      iconColor: Colors.deepOrange,
      title: 'Drug & Food Allergies',
      subtitle: 'Select any allergies you have',
      hint: 'Knowing your allergies helps us warn you about dangerous medicine combinations.',
      dropdown: _buildModernDropdown(
        hint: 'Tap to select allergies',
        items: HealthData.allergies,
        selected: selectedAllergies,
        onChanged: (val) => setState(() {
          selectedAllergies = _enforceNoneRule(selectedAllergies, val);
        }),
      ),
    );
  }

  // ✅ Step 2: Chronic
  Widget _buildChronicStep() {
    return _buildStepCard(
      icon: Icons.favorite_border_rounded,
      iconColor: Colors.red,
      title: 'Chronic Conditions',
      subtitle: 'Long-term health conditions you have',
      hint: 'This helps us identify medicines that might not be suitable for your health.',
      dropdown: _buildModernDropdown(
        hint: 'Tap to select conditions',
        items: HealthData.chronicConditions,
        selected: selectedChronic,
        onChanged: (val) => setState(() {
          selectedChronic = _enforceNoneRule(selectedChronic, val);
        }),
      ),
    );
  }

  // ✅ Step 3: Special
  Widget _buildSpecialStep() {
    return _buildStepCard(
      icon: Icons.person_pin_circle_rounded,
      iconColor: Colors.purple,
      title: 'Special Conditions',
      subtitle: 'Any special situations we should know about',
      hint: 'This helps us provide personalized medicine recommendations based on your situation.',
      dropdown: _buildModernDropdown(
        hint: 'Tap to select conditions',
        items: _filteredSpecialConditions(),
        selected: selectedSpecial,
        onChanged: (val) => setState(() {
          selectedSpecial = _enforceNoneRule(selectedSpecial, val);
        }),
      ),
    );
  }

  // ✅ Reusable step card
  Widget _buildStepCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String hint,
    required Widget dropdown,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Icon + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // ✅ Dropdown
          dropdown,
          
          const SizedBox(height: 16),
          
          // ✅ Hint box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primaryBlue.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E40AF),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ COMPLETELY CUSTOM: No more buggy library! Full control.
  Widget _buildModernDropdown({
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

  // ✅ Custom bottom sheet with full control - NO duplicate checkboxes!
  void _showCustomBottomSheet({
    required String hint,
    required List<String> items,
    required List<String> currentSelection,
    required Function(List<String>) onChanged,
  }) {
    // Local copy that updates as user taps
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
            // Filter items based on search
            final filteredItems = items
                .where((i) =>
                    i.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  // ✅ Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Title
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
                        // ✅ Selection counter
                        if (tempSelection.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.1),
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

                  // ✅ Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
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

                  // ✅ List of items - SINGLE CHECKBOX!
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
                                          // Deselect
                                          tempSelection.remove(item);
                                        } else {
                                          // Select with None rule
                                          if (item == 'None') {
                                            // If selecting None, clear everything else
                                            tempSelection = ['None'];
                                          } else {
                                            // If selecting other, remove None first
                                            tempSelection.remove('None');
                                            tempSelection.add(item);
                                          }
                                        }
                                      });
                                      // ✅ AUTO-SAVE on every tap!
                                      onChanged(List.from(tempSelection));
                                    },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                          .withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // ✅ ONLY ONE CHECKBOX!
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
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

                  // ✅ Done button at bottom (closes sheet)
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
                        child: const Text(
                          'Done',
                          style: TextStyle(
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

  // ✅ Navigation buttons
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep > 0 ? 1 : 1,
          child: SizedBox(
            height: 56,
            child: _isLoading
                ? Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue),
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 3 ? 'Complete' : 'Next',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep == 3
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ✅ Success screen
  Widget _buildSuccessScreen() {
    return Center(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(_animationController),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(_animationController),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'All Set! 🎉',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your health information has been saved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'We\'re ready to help keep you safe!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Redirecting to home...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}