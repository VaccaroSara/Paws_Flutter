import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../main_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _capController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _accountType = "Private User";
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final List<String> _accountTypes = ["Private User", "Animal Shelter"];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _capController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _signUpUser() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final city = _cityController.text.trim();
    final province = _provinceController.text.trim();
    final cap = _capController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final pass = _passwordController.text;
    final phone = _phoneController.text.trim();

    if (email.isEmpty) {
      _showToast("Inserisci un'email");
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showToast("Email non valida");
      return;
    }
    if (pass.isEmpty || pass.length < 6) {
      _showToast("La password deve essere di almeno 6 caratteri");
      return;
    }
    if (username.isEmpty) {
      _showToast("Inserisci uno username");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.signUp(
        firstName: firstName,
        lastName: lastName,
        city: city,
        province: province,
        cap: cap,
        username: username,
        email: email,
        password: pass,
        phone: phone,
        accountType: _accountType,
      );

      if (!mounted) return;
      _showToast("Registrazione completata!");
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
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/sign_ic_logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),

                // Tabs (SIGN IN / SIGN UP)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => const SignInScreen(),
                              transitionDuration: Duration.zero,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            const Text(
                              "SIGN IN",
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
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "SIGN UP",
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
                  ],
                ),
                const SizedBox(height: 24),

                // Form Fields
                CustomInputField(
                  controller: _firstNameController,
                  hintText: "Nome",
                  iconAsset: 'assets/icons/user.svg',
                ),
                CustomInputField(
                  controller: _lastNameController,
                  hintText: "Cognome",
                  iconAsset: 'assets/icons/user.svg',
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomInputField(
                        controller: _cityController,
                        hintText: "Città",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: CustomInputField(
                        controller: _provinceController,
                        hintText: "Prov (es. MI)",
                      ),
                    ),
                  ],
                ),
                CustomInputField(
                  controller: _capController,
                  hintText: "CAP",
                  keyboardType: TextInputType.number,
                ),
                CustomInputField(
                  controller: _usernameController,
                  hintText: "Username",
                  iconAsset: 'assets/icons/user.svg',
                ),
                CustomInputField(
                  controller: _emailController,
                  hintText: "Email",
                  iconAsset: 'assets/icons/mail.svg',
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
                CustomInputField(
                  controller: _phoneController,
                  hintText: "Telefono",
                  iconAsset: 'assets/icons/phone.svg',
                  keyboardType: TextInputType.phone,
                ),

                // Account Type Dropdown
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, color: AppColors.iconDark, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _accountType,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                            items: _accountTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _accountType = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Sign Up Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: "SIGN UP",
                        onPressed: _signUpUser,
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
