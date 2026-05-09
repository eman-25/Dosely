import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/user_data.dart';
import 'package:dosely/services/user_service.dart';
import '../../Widgets/custom_textfield.dart';
import '../../Widgets/custom_button.dart';
import '/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;

  String? _selectedGender;
  String  _selectedCountry = '';

  File? _pickedImage;
  bool  _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserData>(context, listen: false);

    _usernameController = TextEditingController(text: user.username);
    _emailController    = TextEditingController(text: user.email);
    _dobController      = TextEditingController(text: user.dob);

    _selectedGender  = user.gender.isEmpty ? null : user.gender;
    _selectedCountry = user.country.isEmpty ? '' : user.country;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primaryBlue),
              title: Text('choose_from_gallery'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setState(() => _pickedImage = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primaryBlue),
              title: Text('take_a_photo'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (picked != null) setState(() => _pickedImage = File(picked.path));
              },
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text('remove_photo'.tr(),
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pickedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await UserService.updateProfile(
        username: _usernameController.text.trim(),
        email:    _emailController.text.trim(),
        dob:      _dobController.text,
        gender:   _selectedGender ?? '',
        country:  _selectedCountry,
      );
      if (mounted) {
        Provider.of<UserData>(context, listen: false).updateProfile(
          username: _usernameController.text.trim(),
          email:    _emailController.text.trim(),
          dob:      _dobController.text,
          gender:   _selectedGender,
          country:  _selectedCountry,
          avatar:   _pickedImage != null ? FileImage(_pickedImage!) : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_updated'.tr())),
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
    final user = Provider.of<UserData>(context, listen: false);

    final ImageProvider avatarImage = _pickedImage != null
        ? FileImage(_pickedImage!)
        : (user.avatar ??
            const AssetImage('assets/images/default_avatar.png'));

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
          'edit_profile'.tr(),
          style: const TextStyle(
              color: AppColors.text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Health data update reminder ─────────────────────────────
            _HealthUpdateReminder(
              onTap: () => Navigator.pushNamed(context, '/editHealthInfo'),
            ),
            const SizedBox(height: 20),

            // ── Avatar ─────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: avatarImage,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Form fields ────────────────────────────────────────────
            CustomTextField(
              hint: 'username'.tr(),
              controller: _usernameController,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              hint: 'email'.tr(),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: CustomTextField(
                  hint: 'date_of_birth'.tr(),
                  controller: _dobController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              hint: Text('gender'.tr()),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              items: [
                DropdownMenuItem(
                    value: 'Male', child: Text('male'.tr())),
                DropdownMenuItem(
                    value: 'Female', child: Text('female'.tr())),
              ],
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  onSelect: (country) => setState(() {
                    _selectedCountry =
                        '${country.flagEmoji} ${country.name}';
                  }),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCountry.isNotEmpty
                          ? _selectedCountry
                          : 'select_country'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedCountry.isEmpty
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

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
}

// ── Health update reminder widget ─────────────────────────────────────────────
class _HealthUpdateReminder extends StatelessWidget {
  final VoidCallback onTap;
  const _HealthUpdateReminder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.30)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.health_and_safety_rounded,
                color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review your health information',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  SizedBox(height: 3),
                  const Text(
                    'For accurate safety results, update your health data '
                    'every 60 days or whenever your medications or conditions change.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E40AF),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }
}