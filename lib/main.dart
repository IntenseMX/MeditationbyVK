import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audio_service/audio_service.dart';
import 'firebase_options.dart';
import 'core/environment.dart';
import 'core/theme.dart';
import 'presentation/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/audio_player_provider.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  // Will work once firebase_options.dart is configured with real values
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Connect to Firebase Emulators when in dev mode
    if (EnvConfig.useEmulator) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator(
          EnvConfig.host,
          EnvConfig.firestorePort,
        );

        await FirebaseAuth.instance.useAuthEmulator(
          EnvConfig.host,
          EnvConfig.authPort,
        );

        await FirebaseStorage.instance.useStorageEmulator(
          EnvConfig.host,
          EnvConfig.storagePort,
        );

        debugPrint('Connected to Firebase Emulators');
      } catch (e) {
        debugPrint('Error connecting to emulators: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
    debugPrint('Please configure firebase_options.dart with your project values');
  }

  // Initialize a single shared audio handler for background/lock screen controls
  final audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.meditation_by_vk.audio',
      androidNotificationChannelName: 'Meditation Playback',
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler as AppAudioHandler),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Trigger auth initialization (anonymous sign-in on launch)
    ref.watch(authProvider);

    return MaterialApp.router(
      title: 'CLARITY',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
    );
  }
}