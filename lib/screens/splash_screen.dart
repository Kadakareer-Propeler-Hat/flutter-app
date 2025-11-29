// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:horizonai/screens/login_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      _goToLogin();
    });
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        pageBuilder: (context, animation, secondary) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1538),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circle
              Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "HorizonAI",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Your financial companion",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 120),

              Column(
                children: const [
                  Text(
                    "Powered by:",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Propeller Hat & Home Credit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
