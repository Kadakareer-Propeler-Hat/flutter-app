// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get android {
    return const FirebaseOptions(
      apiKey: "YOUR_ANDROID_API_KEY",
      appId: "YOUR_ANDROID_APP_ID",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      projectId: "YOUR_PROJECT_ID",
      storageBucket: "YOUR_STORAGE_BUCKET",
    );
  }

  /// Automatically choose Android only
  static FirebaseOptions get currentPlatform {
    return android;
  }
}
