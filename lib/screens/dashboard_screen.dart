import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:horizonai/components/custom_appbar.dart';
import 'package:horizonai/components/custom_creditscore_card.dart';
import 'package:horizonai/components/custom_outstanding_card.dart';
import 'package:horizonai/components/custom_quickactions.dart';
import 'package:horizonai/components/custom_navbar.dart';
import 'package:horizonai/components/custom_profile.dart';   // <-- ADD THIS
import 'package:horizonai/screens/login_screens.dart';     // <-- ADD THIS (your login file)

class DashboardScreen extends StatefulWidget {
  final bool showWelcomePopup;

  const DashboardScreen({
    super.key,
    this.showWelcomePopup = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  String firstName = "";
  bool popupVisible = false;

  int selectedIndex = 0;

  // Animation Controllers
  late AnimationController popupAnimation;
  late Animation<double> scaleAnimation;
  String animatedText = "";
  int typingIndex = 0;

  // Drawer controller
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserName();

    popupAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    scaleAnimation = CurvedAnimation(
      parent: popupAnimation,
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    setState(() {
      firstName = doc.data()?["firstName"] ?? "User";
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _showWelcomePopup();
    });
  }

  void _showWelcomePopup() {
    setState(() {
      popupVisible = true;
    });

    popupAnimation.forward();
    _startTypingText("Welcome Back, $firstName! I missed you ❤️");
  }

  void _startTypingText(String fullText) {
    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (typingIndex < fullText.length) {
        setState(() {
          animatedText += fullText[typingIndex];
          typingIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _closePopup() {
    popupAnimation.reverse();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        popupVisible = false;
        animatedText = "";
        typingIndex = 0;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() => selectedIndex = index);
  }

  // ---------------------------------------------------------------------
  // SETTINGS ACTIONS
  // ---------------------------------------------------------------------

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomProfileScreen()),
    );
  }

  void logoutUser() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Profile"),
                    onTap: openProfile,
                  ),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: logoutUser,
                  ),
                ],
              ),
            ),
          ),

          backgroundColor: const Color(0xFFF7F7F7),

          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(150),
            child: CustomAppBar(
              firstName: firstName,
              onSettingsPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                CustomCreditScoreCard(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                ),

                const SizedBox(height: 20),
                const CustomOutstandingCard(),
                const SizedBox(height: 20),
                const CustomQuickActions(),
                const SizedBox(height: 80),
              ],
            ),
          ),

          bottomNavigationBar: CustomNavBar(
            selectedIndex: selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),

        // ------------------------------------------------------------------
        // POPUP OVERLAY
        // ------------------------------------------------------------------
        if (popupVisible)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.35),
            child: Center(
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/logo/Welcome.PNG",
                        height: 250,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        animatedText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 35),

                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1538),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _closePopup,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Text(
                              "Got it!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}
