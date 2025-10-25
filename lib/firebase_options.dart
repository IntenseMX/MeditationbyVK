// File generated manually - replace with actual values from Firebase Console
// After creating project in Firebase Console:
// 1. Go to Project Settings
// 2. Add Web, Android, and iOS apps
// 3. Copy configuration values here

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAzupQqwXnViVKkwe7aEx5Oecvm1SIw-vY',
    appId: '1:93424872011:web:9e1f58c75a125d53737bce',
    messagingSenderId: '93424872011',
    projectId: 'meditation-by-vk-89927',
    authDomain: 'meditation-by-vk-89927.firebaseapp.com',
    storageBucket: 'meditation-by-vk-89927.firebasestorage.app',
    measurementId: 'G-9BHFQHQKKR',
  );

  // TODO: Replace with your actual Firebase Web configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC39vVURaV9BYnAqQXOIH0dB1vMudcAaS0',
    appId: '1:93424872011:android:fd80c9cbb252fce8737bce',
    messagingSenderId: '93424872011',
    projectId: 'meditation-by-vk-89927',
    storageBucket: 'meditation-by-vk-89927.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase Android configuration

  // TODO: Replace with your actual Firebase iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'meditation-by-vk-89927',
    storageBucket: 'meditation-by-vk-89927.firebasestorage.app',
    iosBundleId: 'com.example.meditationByVk',
  );
}