import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:dosely/services/user_service.dart';
import 'package:dosely/models/user_data.dart';
import '/theme.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // ← NEW

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true); // ← show loader

    try {
      // 1️⃣ Sign in with Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2️⃣ Check email verification
      if (!credential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('verify_email'.tr())),
          );
        }
        return;
      }

      // 3️⃣ Load all user data from Firestore into Provider
      if (mounted) {
        final userData = Provider.of<UserData>(context, listen: false);
        await UserService.loadUserIntoProvider(userData);
      }

      // 4️⃣ Navigate to home
      if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'user_not_found'.tr();
          break;
        case 'wrong-password':
          message = 'wrong_password'.tr();
          break;
        case 'invalid-credential':
          message = 'invalid_credentials'.tr();
          break;
        default:
          message = 'login_failed'.tr(namedArgs: {'message': e.message ?? ''});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error'.tr(namedArgs: {'error': e.toString()})),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // ← hide loader
    }
  }

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'welcome_back'.tr(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hint: 'enter_email'.tr(),
                  controller: _emailController,
                ),
                CustomTextField(
                  hint: 'enter_password'.tr(),
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/forgotPassword'),
                    child: Text('forgot_password'.tr()),
                  ),
                ),
                const SizedBox(height: 15),

                // ← Shows spinner while loading, button otherwise
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: 'login'.tr(),
                        onPressed: _login,
                      ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/register'),
                    child: Text('no_account'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}