import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';
import 'auth/sign_in_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    // 1. Safe Firebase Init
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Firebase init fallback: $e');
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyAS-OwI9KkvdeULAyS50VeIJ3GvZj_5zlc",
              appId: "1:599539577362:android:adb6b9554c7734ab4b9ecb",
              messagingSenderId: "599539577362",
              projectId: "paws-26918",
              storageBucket: "paws-26918.firebasestorage.app",
            ),
          );
        }
      } catch (_) {}
    }

    // 2. Safe Supabase Init
    try {
      await SupabaseService.init().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Supabase init fallback: $e');
    }

    // 3. Minimum splash branding delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 4. Check Auth State and Navigate
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        return;
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    // Default to SignInScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/sign_ic_logo.png',
          width: 140,
          height: 70,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
