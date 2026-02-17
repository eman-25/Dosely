import 'package:flutter/material.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';
import 'password_changed_screen.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.primaryGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
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

                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),

                const SizedBox(height: 20),

                const CustomTextField(hint: "New Password", isPassword: true),

                const CustomTextField(
                  hint: "Confirm New Password",
                  isPassword: true,
                ),

                const SizedBox(height: 25),

                // FIX: Ensure this route exists in your main.dart
                CustomButton(
                  text: "Submit",
                  color: AppColors.darkButton,
                  onPressed: () {
                    // This replaces the current screen with the success screen
                    Navigator.pushReplacementNamed(
                      context,
                      '/passwordChanged',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}