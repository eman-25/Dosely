import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this for date formatting
import 'package:dropdown_search/dropdown_search.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers and State Variables
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;
  String _selectedCountry = "Select Country";

  // Date of Birth Picker Function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // Default starting point
      firstDate: DateTime(1900),   // Earliest date
      lastDate: DateTime.now(),    // Cannot be in the future
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.primaryGreen],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // FIX: Added IconButton with Navigator.pop
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                  const Text("Create Account", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),

                  // Existing Fields
                  const CustomTextField(hint: "Username"),
                  const SizedBox(height: 10),
                  const CustomTextField(hint: "Email"),
                  const SizedBox(height: 10),

                  // --- NEW FIELDS START HERE ---

                  // 1. Date of Birth (Calendar)
                  TextField(
                    controller: _dobController,
                    readOnly: true, // Prevents keyboard from opening
                    decoration: InputDecoration(
                      hintText: "Date of Birth",
                      suffixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 10),

                  // 2. Gender (Male/Female List)
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      hintText: "Gender",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ["Male", "Female"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 10),

                  // 3. Country List
                  InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        onSelect: (Country country) {
                          setState(() {
                            _selectedCountry = "${country.flagEmoji} ${country.name}";
                          });
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedCountry, style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),

                  // --- NEW FIELDS END HERE ---

                  const SizedBox(height: 10),
                  const CustomTextField(hint: "Password", isPassword: true),
                  const SizedBox(height: 10),
                  const CustomTextField(hint: "Confirm Password", isPassword: true),
                  const SizedBox(height: 25),

                  CustomButton(
                    text: "Next",
                    onPressed: () => Navigator.pushNamed(context, '/personalInfo'),
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