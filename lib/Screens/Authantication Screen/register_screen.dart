import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';
import '/theme.dart'; // Assuming this contains AppColors
import '../../models/user_data.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';
import 'personal_info_screen.dart'; // Importing the next screen to navigate to

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables
  String? _selectedGender;
  String _selectedCountry = "Select Country";

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
        _selectedCountry != "Select Country" &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
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
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text, // ← prefer named color if available
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form fields
                    CustomTextField(
                      hint: "Username",
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      hint: "Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Date of Birth",
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      hint: const Text("Gender"),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = "${country.flagEmoji} ${country.name}";
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCountry,
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedCountry == "Select Country"
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
                      hint: "Password",
                      isPassword: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      hint: "Confirm Password",
                      isPassword: true,
                      controller: _confirmPasswordController,
                    ),
                    const SizedBox(height: 32),

                    // Next Button
                    CustomButton(
                      text: "Next",
                      onPressed: () {
                        if (!_isFormValid()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please complete all required fields"),
                            ),
                          );
                          return;
                        }

                        if (_passwordController.text != _confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords do not match")),
                          );
                          return;
                        }

                        final userData = Provider.of<UserData>(context, listen: false);
                        userData.username = _usernameController.text.trim();
                        userData.email = _emailController.text.trim();
                        userData.dob = _dobController.text;
                        userData.gender = _selectedGender ?? "Prefer not to say";
                        userData.country = _selectedCountry;

                        Navigator.pushNamed(context, '/personalInfo');
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
}