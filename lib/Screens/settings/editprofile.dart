// lib/screens/editprofile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import '../../models/user_data.dart';
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
  String _selectedCountry = "Select Country";

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserData>(context, listen: false);

    _usernameController = TextEditingController(text: user.username);
    _emailController = TextEditingController(text: user.email);
    _dobController = TextEditingController(text: user.dob);

    _selectedGender = user.gender.isEmpty ? null : user.gender;
    _selectedCountry = user.country.isEmpty ? "Select Country" : user.country;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
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
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Photo
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 60, color: AppColors.primaryBlue),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18, color: AppColors.primaryBlue),
                    onPressed: () {
                      // TODO: Add image picker later
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo upload coming soon')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            CustomTextField(hint: "Username", controller: _usernameController),
            const SizedBox(height: 16),
            CustomTextField(
              hint: "Email",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Date of Birth
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: CustomTextField(
                  hint: "Date of Birth",
                  controller: _dobController,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              hint: const Text("Gender"),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              items: ["Male", "Female"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 16),

            // Country
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  onSelect: (country) {
                    setState(() {
                      _selectedCountry = "${country.flagEmoji} ${country.name}";
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
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
            const SizedBox(height: 40),

            CustomButton(
              text: "Save changes",
              onPressed: () {
                final userData = Provider.of<UserData>(context, listen: false);
                userData.updateProfile(
                  username: _usernameController.text.trim(),
                  email: _emailController.text.trim(),
                  dob: _dobController.text,
                  gender: _selectedGender,
                  country: _selectedCountry,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Profile updated successfully')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}