import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/theme.dart';
import '../../models/user_data.dart';
import 'package:dosely/services/user_service.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  String? _selectedCountry;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  bool _isFormValid() {
    return _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _dobController.text.isNotEmpty &&
        _selectedGender != null &&
        _selectedCountry != null &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  Future<void> _register() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('complete_fields'.tr())),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('passwords_no_match'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2️⃣ Send email verification
      await credential.user!.sendEmailVerification();

      // 3️⃣ Save basic profile to Firestore (linked to UID)
      await UserService.saveBasicProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        dob: _dobController.text,
        gender: _selectedGender ?? 'Prefer not to say',
        country: _selectedCountry ?? '',
      );

      // 4️⃣ Also update local provider so next screen has data
      if (mounted) {
        final userData = Provider.of<UserData>(context, listen: false);
        userData.updateProfile(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender ?? 'Prefer not to say',
          country: _selectedCountry ?? '',
        );

        // 5️⃣ Go to health personalization screen
        Navigator.pushNamed(context, '/personalInfo');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'email_already_used'.tr();
          break;
        case 'weak-password':
          message = 'weak_password'.tr();
          break;
        case 'invalid-email':
          message = 'invalid_email'.tr();
          break;
        default:
          message = e.message ?? 'error'.tr(namedArgs: {'error': ''});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      // Firestore save error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'create_account'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      hint: 'username'.tr(),
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'email'.tr(),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'date_of_birth'.tr(),
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      hint: Text('gender'.tr()),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: [
                        DropdownMenuItem(value: "Male", child: Text('male'.tr())),
                        DropdownMenuItem(value: "Female", child: Text('female'.tr())),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry =
                                  "${country.flagEmoji} ${country.name}";
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCountry ?? 'select_country'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedCountry == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'password'.tr(),
                      isPassword: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'confirm_password'.tr(),
                      isPassword: true,
                      controller: _confirmPasswordController,
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            text: 'next'.tr(),
                            onPressed: _register,
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
}