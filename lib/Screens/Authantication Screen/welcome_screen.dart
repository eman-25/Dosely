import 'package:flutter/material.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue,
              AppColors.primaryGreen,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(25),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                          'assets/images/dosely_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image not found
                            return const Icon(
                              Icons.medication_liquid_rounded, size: 80);
                          },
                        ),
                CustomButton(
                  text: "Login",
                  onPressed: () =>
                      Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(height: 15),
                CustomButton(
                  text: "Register",
                  onPressed: () =>
                      Navigator.pushNamed(context, '/register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
  }
  
}