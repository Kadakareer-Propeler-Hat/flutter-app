// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'service/firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:horizonai/screens/login_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar + navbar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }
}
