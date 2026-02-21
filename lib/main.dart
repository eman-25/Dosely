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
import 'models/user_data.dart';

// Settings Screens
import 'screens/settings/editprofile.dart';
import 'screens/settings/edit_personalhealthinfo.dart';
import 'screens/settings/Security.dart';
import 'screens/settings/privacy.dart';
import 'screens/settings/language.dart';
import 'screens/settings/Notifications.dart';
import 'screens/settings/HelpandSupprot.dart';
import 'screens/settings/aboutus.dart';
import 'screens/settings/report_problem.dart';
import 'screens/settings/logout.dart';
import 'screens/HOME/settings_panel.dart';
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
        '/settings': (context) => const SettingsPanel(),

        // Settings Routes
        '/editProfile': (context) => const EditProfileScreen(),
        '/editPersonalHealthInfo': (context) => const EditPersonalHealthInfoScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/language': (context) => const LanguageScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/helpSupport': (context) => const HelpSupportScreen(),
        '/aboutUs': (context) => const AboutUsScreen(),
        '/reportProblem': (context) => const ReportProblemScreen(),
        '/logout': (context) => const LogoutScreen(),
        '/security': (context) => const SecurityScreen(),
        
      },
    );
  }
}