// lib/screens/signup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

import '../models/user_model.dart';
import 'login_screens.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController salarySchedule = TextEditingController();
  final TextEditingController salaryIncome = TextEditingController(); // NEW
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  File? idImage;
  final picker = ImagePicker();
  bool loading = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => idImage = File(picked.path));
    }
  }

  Future<void> registerUser() async {
    if (idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your valid ID")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // 1. Firebase Auth
      UserCredential cred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = cred.user!.uid;

      // 2. Upload ID to Supabase
      final supabase = Supabase.instance.client;
      final fileName = "$uid-id.jpg";

      await supabase.storage.from("user_ids").upload(
        fileName,
        idImage!,
        fileOptions:
        const FileOptions(cacheControl: '3600', upsert: true),
      );

      final idUrl =
      supabase.storage.from("user_ids").getPublicUrl(fileName);

      // 3. Save to Firestore with salaryIncome
      UserModel user = UserModel(
        uid: uid,
        email: email.text.trim(),
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        salarySchedule: salarySchedule.text.trim(),
        salaryIncome: salaryIncome.text.trim(), // NEW
        idImageUrl: idUrl,
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(user.toMap());

      setState(() => loading = false);

      // 4. Show welcome popup
      _showWelcomePopup();

    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    }
  }

  void _showWelcomePopup() {
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (_) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Material(
              type: MaterialType.transparency,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/logo/Welcome.PNG",
                      height: 250,
                    ),
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(seconds: 1),
                      child: const Text(
                        "Congratulations and\nWelcome to HorizonAI!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1538),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
            ),
          ],
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1538),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 50),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text("HorizonAI",
                  style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Register",
                  style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(child: inputField(firstName, "First Name")),
                  const SizedBox(width: 10),
                  Expanded(child: inputField(lastName, "Last Name")),
                ],
              ),

              const SizedBox(height: 20),
              inputField(salarySchedule, "Salary Schedule",
                  icon: Icons.calendar_month_outlined),

              const SizedBox(height: 20),
              inputField(salaryIncome, "Salary Income",
                  icon: Icons.money_outlined), // NEW

              const SizedBox(height: 20),
              inputField(email, "Email", icon: Icons.email_outlined),

              const SizedBox(height: 20),
              inputField(password, "Password", password: true),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.badge_outlined,
                          color: Colors.white, size: 60),
                      const SizedBox(height: 10),
                      Text(
                        idImage == null ? "Upload Valid ID" : "ID Uploaded ✓",
                        style:
                        const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your data is safe — ID deleted after 7 days.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: registerUser,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField(TextEditingController ctrl, String text,
      {IconData? icon, bool password = false}) {
    return TextField(
      controller: ctrl,
      obscureText: password,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon:
        icon != null ? Icon(icon, color: Colors.white) : null,
        hintText: text,
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

