import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ✅ NEW: Check if email exists in Firestore
  Future<bool> _emailExistsInFirestore(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ✅ NEW: Try to login with the existing account and complete registration
  Future<bool> _tryRecoverOrphanedAccount(String email, String password) async {
    try {
      print('🔄 Trying to recover orphaned account: $email');
      
      // Try to sign in with provided credentials
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Signed in to existing account, now creating Firestore profile');

      // Send verification if not verified
      if (!credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }

      // Save profile to Firestore
      await UserService.saveBasicProfile(
        username: _usernameController.text.trim(),
        email: email,
        dob: _dobController.text,
        gender: _selectedGender ?? 'Prefer not to say',
        country: _selectedCountry ?? '',
      );

      print('✅ Profile saved successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Recovery failed: ${e.code}');
      // If wrong password, the email truly belongs to someone else
      return false;
    } catch (e) {
      print('❌ Recovery error: $e');
      return false;
    }
  }

  Future<void> _register() async {
    // At the very start of _register() function
    await FirebaseAuth.instance.signOut();
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

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // 1️⃣ Try to create new Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ Send verification
      await credential.user!.sendEmailVerification();

      // 3️⃣ Save to Firestore
      await UserService.saveBasicProfile(
        username: _usernameController.text.trim(),
        email: email,
        dob: _dobController.text,
        gender: _selectedGender ?? 'Prefer not to say',
        country: _selectedCountry ?? '',
      );

      // 4️⃣ Update local provider
      if (mounted) {
        final userData = Provider.of<UserData>(context, listen: false);
        userData.updateProfile(
          username: _usernameController.text.trim(),
          email: email,
          dob: _dobController.text,
          gender: _selectedGender ?? 'Prefer not to say',
          country: _selectedCountry ?? '',
        );

        Navigator.pushNamed(context, '/personalInfo');
      }
    } on FirebaseAuthException catch (e) {
      // ✅ FIX: Handle "email-already-in-use" smartly
      if (e.code == 'email-already-in-use') {
        print('⚠️ Email exists in Auth, checking Firestore...');
        
        // Check if email exists in Firestore
        final existsInFirestore = await _emailExistsInFirestore(email);
        
        if (!existsInFirestore) {
          // ✅ Orphaned account! Try to recover it
          print('🔧 Orphaned account detected - attempting recovery');
          
          final recovered = await _tryRecoverOrphanedAccount(email, password);
          
          if (recovered) {
            // Successfully recovered!
            if (mounted) {
              final userData = Provider.of<UserData>(context, listen: false);
              userData.updateProfile(
                username: _usernameController.text.trim(),
                email: email,
                dob: _dobController.text,
                gender: _selectedGender ?? 'Prefer not to say',
                country: _selectedCountry ?? '',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welcome back! Completing your registration...'),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pushNamed(context, '/personalInfo');
            }
            return;
          } else {
            // Wrong password for orphaned account
            if (mounted) {
              _showRecoveryDialog(email);
            }
            return;
          }
        } else {
          // Email truly exists with full profile
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('email_already_used'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Other Firebase Auth errors
      String message;
      switch (e.code) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Show dialog for orphaned account recovery
  void _showRecoveryDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Account Already Exists'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An account with $email already exists.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can either:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Login if you remember your password',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Reset your password if you forgot it',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Use a different email address',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context, '/forgotPassword', (route) => false);
            },
            child: const Text('Reset Password'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
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