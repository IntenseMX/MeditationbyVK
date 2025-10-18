import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/environment.dart';
import 'core/theme.dart';
import 'presentation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip Firebase initialization for now - needs configuration
  // TODO: Run `flutterfire configure` after setting up Firebase project

  // // Initialize Firebase
  // await Firebase.initializeApp();

  // // Connect to Firebase Emulators when in dev mode
  // if (EnvConfig.useEmulator) {
  //   try {
  //     FirebaseFirestore.instance.useFirestoreEmulator(
  //       EnvConfig.host,
  //       EnvConfig.firestorePort,
  //     );

  //     await FirebaseAuth.instance.useAuthEmulator(
  //       EnvConfig.host,
  //       EnvConfig.authPort,
  //     );

  //     await FirebaseStorage.instance.useStorageEmulator(
  //       EnvConfig.host,
  //       EnvConfig.storagePort,
  //     );

  //     debugPrint('Connected to Firebase Emulators');
  //   } catch (e) {
  //     debugPrint('Error connecting to emulators: $e');
  //   }
  // }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Meditation by VK',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(AppTheme.lightTheme.textTheme),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(AppTheme.darkTheme.textTheme),
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}