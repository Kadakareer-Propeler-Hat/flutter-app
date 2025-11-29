// lib/screens/signup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController salarySchedule = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  File? idImage;
  final picker = ImagePicker();

  bool loading = false;

  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        idImage = File(picked.path);
      });
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

      // 1. Create Firebase user
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = cred.user!.uid;

      // 2. Upload ID
      final storageRef =
      FirebaseStorage.instance.ref("user_ids/$uid-id.jpg");
      await storageRef.putFile(idImage!);
      final idUrl = await storageRef.getDownloadURL();

      // 3. Store user info Firestore
      UserModel user = UserModel(
        uid: uid,
        email: email.text.trim(),
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        salarySchedule: salarySchedule.text.trim(),
        idImageUrl: idUrl,
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(user.toMap());

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.pop(context);

    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    }
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

              // First Name + Last Name
              Row(
                children: [
                  Expanded(
                    child: inputField(firstName, "First Name"),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: inputField(lastName, "Last Name"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Salary Schedule
              inputField(salarySchedule, "Salary Schedule",
                  icon: Icons.calendar_month_outlined),

              const SizedBox(height: 20),

              // Email
              inputField(email, "Email", icon: Icons.email_outlined),

              const SizedBox(height: 20),

              // Password
              inputField(password, "Password", password: true),

              const SizedBox(height: 30),

              // Upload ID
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white54,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.badge_outlined,
                          color: Colors.white, size: 60),
                      const SizedBox(height: 10),
                      Text(
                        idImage == null
                            ? "Upload Valid ID"
                            : "ID Uploaded ✓",
                        style:
                        const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your data is safe — ID deleted after 7 days.",
                        textAlign: TextAlign.center,
                        style:
                        TextStyle(color: Colors.white70, fontSize: 12),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Create Account Button
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
                          fontWeight: FontWeight.bold),
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
