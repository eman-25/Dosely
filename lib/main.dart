import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserData(),
      child: const DoselyApp(),
    ),
  );
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
        fontFamily: 'SF Pro Display',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/personalInfo': (context) => const PersonalInfoScreen(),
        '/registerSuccess': (context) => const RegisterSuccessScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/passwordChanged': (context) => const PasswordChangedScreen(),
        '/home': (context) => const HomeScreen(),

        // Settings Routes
        '/editProfile': (context) => const EditProfileScreen(),
        '/editPersonalHealthInfo': (context) => const EditPersonalHealthInfoScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/language': (context) => const LanguageScreen(),
        '/security': (context) => const SecurityScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/helpSupport': (context) => const HelpSupportScreen(),
        '/aboutUs': (context) => const AboutUsScreen(),
        '/reportProblem': (context) => const ReportProblemScreen(),
        '/logout': (context) => const LogoutScreen(),
      },
    // ✅ IMPORTANT: allow mouse + trackpad dragging (Windows/Web/Desktop)
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),

    );
  }
}