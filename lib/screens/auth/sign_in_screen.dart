import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../main_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signInUser() async {
    final email = _emailController.text.trim().toLowerCase();
    final pass = _passwordController.text;

    if (email.isEmpty) {
      _showToast("Inserisci l'email");
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showToast("Email non valida");
      return;
    }
    if (pass.isEmpty) {
      _showToast("Inserisci la password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.signIn(email, pass);
      if (!mounted) return;
      _showToast("Accesso eseguito!");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showToast("Errore: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Reimposta Password"),
        content: TextField(
          controller: emailResetController,
          decoration: const InputDecoration(hintText: "Inserisci la tua email"),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () async {
              final resetEmail = emailResetController.text.trim();
              if (resetEmail.isNotEmpty) {
                try {
                  await FirebaseService.sendPasswordResetEmail(resetEmail);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  if (mounted) {
                    _showToast("Email di reset inviata!");
                  }
                } catch (e) {
                  if (mounted) {
                    _showToast("Errore invio email: ${e.toString()}");
                  }
                }
              }
            },
            child: const Text("Invia"),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/sign_ic_logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),

                // Tabs (SIGN IN / SIGN UP)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Column(
                          children: [
                            const Text(
                              "SIGN IN",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 50,
                              height: 3,
                              color: AppColors.primaryOrange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => const SignUpScreen(),
                              transitionDuration: Duration.zero,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            const Text(
                              "SIGN UP",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 50,
                              height: 3,
                              color: Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Input Fields
                CustomInputField(
                  controller: _emailController,
                  hintText: "Email",
                  iconAsset: 'assets/icons/user.svg',
                  keyboardType: TextInputType.emailAddress,
                ),
                CustomInputField(
                  controller: _passwordController,
                  hintText: "Password",
                  iconAsset: 'assets/icons/lock.svg',
                  isPassword: true,
                  isPasswordVisible: _isPasswordVisible,
                  onTogglePassword: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Sign In Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: "SIGN IN",
                        onPressed: _signInUser,
                      ),
                const SizedBox(height: 16),

                // Forgot Password
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
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
