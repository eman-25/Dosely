import 'package:flutter/material.dart';
import 'screens/Authantication Screen/welcome_screen.dart';
import 'screens/Authantication Screen/login_screen.dart';
import 'screens/Authantication Screen/register_screen.dart';
import 'screens/Authantication Screen/personal_info_screen.dart'; 
import 'screens/Authantication Screen/register_success_screen.dart';
import 'screens/Authantication Screen/forgot_password_screen.dart';
import 'screens/Authantication Screen/verification_screen.dart';
import 'screens/Authantication Screen/change_password_screen.dart';
import 'screens/Authantication Screen/password_changed_screen.dart';
import 'Screens/HOME/home_screen.dart';


void main() {
  runApp(const DoselyApp());
}

class DoselyApp extends StatelessWidget {
  const DoselyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dosely',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // optional; if not available, it falls back
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/personalInfo': (context) => PersonalInfoScreen(),
        '/registerSuccess': (context) => RegisterSuccessScreen(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/verification': (context) => VerificationScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/passwordChanged': (context) => PasswordChangedScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
