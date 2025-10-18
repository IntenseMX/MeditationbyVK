# Firebase Setup Instructions

## Current Status
- ✅ Firebase project created: `meditation-by-vk`
- ✅ Firebase configuration file template created
- ⚠️ Need to get actual configuration values from Firebase Console

## Steps to Complete Firebase Setup

### 1. Go to Firebase Console
Visit: https://console.firebase.google.com/

### 2. Select Your Project
Look for "meditation-by-vk" in your projects list

### 3. Add Web App
1. Click the gear icon ⚙️ → Project Settings
2. Scroll down to "Your apps" section
3. Click "Add app" → Select Web (</> icon)
4. Register app with nickname: "Meditation Web"
5. Copy the configuration object

### 4. Update firebase_options.dart
Replace the placeholder values in `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',     // e.g., "AIzaSy..."
  appId: 'YOUR_ACTUAL_APP_ID',       // e.g., "1:123456789:web:..."
  messagingSenderId: 'YOUR_SENDER_ID', // e.g., "123456789"
  projectId: 'meditation-by-vk',      // Keep this as-is
  authDomain: 'meditation-by-vk.firebaseapp.com',
  storageBucket: 'meditation-by-vk.appspot.com',
);
```

### 5. Add Android App (Optional for now)
1. In Firebase Console → Add app → Android
2. Package name: `com.example.meditation_by_vk`
3. Download `google-services.json`
4. Place it in `android/app/`
5. Update firebase_options.dart with Android values

### 6. Add iOS App (Optional for now)
1. In Firebase Console → Add app → iOS
2. Bundle ID: `com.example.meditationByVk`
3. Download `GoogleService-Info.plist`
4. Add to iOS project via Xcode
5. Update firebase_options.dart with iOS values

### 7. Enable Authentication
In Firebase Console:
1. Go to Authentication → Get Started
2. Enable these sign-in methods:
   - Email/Password
   - Google
   - Anonymous (for guest mode)

### 8. Create Firestore Database
1. Go to Firestore Database → Create Database
2. Start in Test mode (for development)
3. Choose location closest to you

### 9. Setup Cloud Storage
1. Go to Storage → Get Started
2. Start in Test mode (for development)
3. Choose same location as Firestore

## Alternative: Use FlutterFire CLI
If the Firebase project shows up in your account later:
```bash
cd meditation_by_vk
dart pub global run flutterfire_cli:flutterfire configure
```

This will automatically create the firebase_options.dart file with correct values.

## Testing Firebase Connection
Once configured, the app will:
1. Show "Firebase initialized successfully" in console
2. Connect to real Firebase (or emulators if Java installed)
3. Be ready for authentication implementation

## Troubleshooting
- **Project not showing in CLI**: Check Firebase Console directly
- **No billing account**: Firebase has a generous free tier
- **Java not installed**: Firebase emulators need Java 11+
- **Configuration errors**: Double-check API keys match exactly

## Next Steps
After Firebase is configured:
1. Test authentication flows
2. Create first Firestore documents
3. Upload test meditation audio files
4. Begin Phase 1 implementation