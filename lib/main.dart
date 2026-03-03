import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart'; // ← Add this
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
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

// New: Email Verification Pending Screen (create a simple one or reuse VerificationScreen)
class EmailVerificationPendingScreen extends StatelessWidget {
  const EmailVerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please verify your email',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'We sent a verification link to your email. Check your inbox and click the link.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.currentUser?.reload();
                  if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email not verified yet')),
                    );
                  }
                },
                child: const Text('I\'ve Verified - Continue'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email resent')),
                  );
                },
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New: AuthWrapper to handle login state + verification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (!user.emailVerified) {
            return const EmailVerificationPendingScreen();
          }
          // Load user data from Firestore (optional here, or do in HomeScreen)
          return const HomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set persistence for staying logged in
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

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
      theme: ThemeData(useMaterial3: true, fontFamily: 'SF Pro Display'),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(), // ← Changed to AuthWrapper
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