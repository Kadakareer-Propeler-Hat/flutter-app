// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get android {
    return const FirebaseOptions(
      apiKey: "AIzaSyAABuRxKkmhwarJra8I3Zk5vSvJhmqpWRg",
      appId: "1:465512709100:android:7cc280164a8234ea789ec9",
      messagingSenderId: "465512709100",
      projectId: "kadakareer-5d385",
      storageBucket: "kadakareer-5d385.firebasestorage.app",
    );
  }

  static FirebaseOptions get currentPlatform => android;
}
