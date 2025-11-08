# PHASE 0: Bootstrap & Setup

**Created**: 2025-10-18
**Last Updated**: 2025-10-18

---

## 🎯 Goal

Get the project from zero to running skeleton with Firebase Emulator Suite, Clean Architecture structure, and basic navigation.

**Success Criteria:**
- ✅ Flutter project created and pushed to GitHub
- ✅ Firebase Emulator Suite running locally
- ✅ Clean Architecture folder structure established
- ✅ App runs with navigation and theme
- ✅ Ready for Phase 1 (authentication implementation)

---

## 📋 Step-by-Step Implementation Plan

### STEP 1 — Create the Flutter Project (2025-10-18)

**Location**: Project root
**Commands**:
```bash
flutter create meditation_by_vk
cd meditation_by_vk
```

**Actions**:
- Delete default counter app code from `/lib`
- Keep only `main.dart` (will rewrite it)

**📊 Scope**: 1 command, ~5 minutes

---

### STEP 2 — Initialize Git & Push to Repo (2025-10-18)

**Repository**: `https://github.com/IntenseMX/MeditationbyVK.git`

**Commands**:
```bash
git init
git add .
git commit -m "Initial Flutter project setup"
git branch -M main
git remote add origin https://github.com/IntenseMX/MeditationbyVK.git
git push -u origin main
```

**📊 Scope**: 5 git commands, ~2 minutes

---

### STEP 3 — Create Clean Architecture Folder Structure (2025-10-18)

**Location**: `/lib`

**Structure to create**:
```
lib/
 ┣ core/
 ┃  ┣ theme.dart
 ┃  ┣ constants.dart
 ┃  ┗ environment.dart
 ┣ data/
 ┃  ┣ datasources/
 ┃  ┗ repositories/
 ┣ domain/
 ┃  ┣ entities/
 ┃  ┗ usecases/
 ┣ presentation/
 ┃  ┣ screens/
 ┃  ┃  ┣ home_screen.dart
 ┃  ┃  ┣ discover_screen.dart
 ┃  ┃  ┣ progress_screen.dart
 ┃  ┃  ┗ profile_screen.dart
 ┃  ┣ widgets/
 ┃  ┗ providers/
 ┗ main.dart
```

**Initial files to create**:
- `lib/core/theme.dart` — Material theme with light/dark variants
- `lib/core/constants.dart` — App-wide constants
- `lib/core/environment.dart` — Environment config for emulator switching
- `lib/presentation/screens/*.dart` — Placeholder screens
- `lib/presentation/app_router.dart` — GoRouter configuration

**📊 Scope**: ~20 files/folders, ~100 lines initial code

---

### STEP 4 — Initialize Firebase + Emulator Suite (2025-10-18)

**Commands**:
```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project
firebase init
```

**Firebase Init Options** (select these):
- ✅ Authentication
- ✅ Cloud Firestore
- ✅ Cloud Storage
- ✅ Emulators (Auth, Firestore, Storage)

**Start Emulators**:
```bash
firebase emulators:start
```

**Install Flutter Firebase Dependencies**:
```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutterfire configure
```

**Note**: When running `flutterfire configure`, you will be prompted to select your Firebase project. Choose the project you created in the Firebase Console.

**Create Environment Config** (`lib/core/environment.dart`):
```dart
class EnvConfig {
  static const useEmulator = true; // Switch to false for production
  static const host = 'localhost';
  static const firestorePort = 8080;
  static const authPort = 9099;
  static const storagePort = 9199;
}
```

**Update main.dart** to connect to emulators:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'core/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ⬇️ Insert this block AFTER Firebase.initializeApp()
  // Connect to Firebase Emulators when in dev mode
  if (EnvConfig.useEmulator) {
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
  }

  runApp(const MyApp());
}
```

**📊 Scope**: ~50 lines across 2 files, ~15 minutes

---

### STEP 5 — Add Core Dependencies (2025-10-18)

**Install packages**:
```bash
flutter pub add flutter_riverpod go_router google_fonts google_sign_in
```

**Note**: `google_sign_in` is added now for Phase 1 authentication (Google Sign-In flow).

**Create Theme System** (`lib/core/theme.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4EFF),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4EFF),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  );
}
```

**Create Router** (`lib/presentation/app_router.dart`):
```dart
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/discover',
      name: 'discover',
      builder: (context, state) => const DiscoverScreen(),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
```

**Create Placeholder Screens**:
- `home_screen.dart` — Simple "Home" text centered
- `discover_screen.dart` — Simple "Discover" text centered
- `progress_screen.dart` — Simple "Progress" text centered
- `profile_screen.dart` — Simple "Profile" text centered

**Update main.dart** to use theme and router:
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Meditation by VK',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
```

**📊 Scope**: ~150 lines across 7 files

---

### STEP 6 — Test the Skeleton (2025-10-18)

**IMPORTANT**: Before running the app, ensure Firebase Emulators are running in a **separate terminal**:
```bash
firebase emulators:start
```

**Run the app** (in a new terminal):
```bash
flutter run
```

**Verify**:
- ✅ App builds without errors
- ✅ Firebase Emulators are running (check terminal output for "All emulators ready!")
- ✅ App connects to local emulators (no production Firebase calls — check emulator UI at http://localhost:4000)
- ✅ Navigation works between screens
- ✅ Theme applies correctly (light/dark mode)

**📊 Scope**: 1 command, manual testing

---

## 🎯 This Week's Goal

**By end of Phase 0:**
- ✅ App builds and runs from `main`
- ✅ Firebase Emulator Suite configured and functional
- ✅ Folder structure + theming + navigation established
- ✅ Committed and pushed to GitHub
- ✅ Ready to implement authentication (guest + Google in Phase 1)

---

## 📊 Total Scope Estimate

**Lines of Code**: ~300 lines
**Files Created**: ~20 files
**Time Estimate**: 1-2 hours (includes setup, testing, git push)
**Dependencies**: 8 packages (firebase_core, firebase_auth, cloud_firestore, firebase_storage, flutter_riverpod, go_router, google_fonts, google_sign_in)

---

## 🔗 Next Steps

Once Phase 0 is complete:
1. **Phase 1: Foundation** — Implement authentication (guest, email, Google)
2. **Claude** handles CI/CD setup via GitHub Actions
3. **Developer** handles provider scaffolding and dummy data integration

---

## 🧑‍💻 Responsibilities

- **Developer**: Execute all steps, verify functionality
- **Claude**: Guide implementation, verify architecture compliance
- **ChatGPT**: Review architecture decisions, provide system design feedback

---

## 📝 Notes

- Firebase Emulator Suite runs on localhost — zero production costs during development
- `EnvConfig.useEmulator` flag switches between local and production Firebase
- All placeholder screens return simple centered text — real UI comes in Phase 1
- Theme uses Material 3 with Google Fonts (Poppins) — can customize later
- GoRouter setup uses named routes for type-safe navigation

---

## ✅ Completion Checklist

- [ ] Flutter project created
- [ ] Git initialized and pushed to GitHub
- [ ] Clean Architecture folder structure created
- [ ] Firebase CLI installed and logged in
- [ ] Firebase project initialized with emulators
- [ ] Emulators running successfully
- [ ] Flutter Firebase dependencies installed
- [ ] Environment config created
- [ ] main.dart connects to emulators
- [ ] Core dependencies installed (Riverpod, GoRouter, GoogleFonts)
- [ ] Theme system created
- [ ] Router configured
- [ ] Placeholder screens created
- [ ] App runs without errors
- [ ] Navigation tested between all screens
- [ ] Firebase connection verified (check emulator logs)
- [ ] Changes committed and pushed to GitHub

---

**Once all checkboxes are complete, Phase 0 is done. Move to Phase 1. 🚀**
