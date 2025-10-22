# Firebase Setup Instructions

**Last Updated**: 2025-10-22

## Development Strategy: Emulator-First (2025-10-18)

### 🚨 IMPORTANT: Local Development Only Until Phase 3+
**All development happens in Firebase Emulators until the app is feature-complete.**

- **Phase 0-2**: Emulator-only development (current stage)
- **Phase 3+**: Cloud deployment when ready for production
- **Why**: Zero costs, instant resets, faster iteration, no accidental bills

### Running Local Emulators
```bash
# Start all emulators (Auth, Firestore, Storage)
firebase emulators:start

# Access Emulator UI
http://localhost:4000
```

**Note**: Java 11+ required for emulators. If not installed, development will pause until local environment is ready.

---

## Current Status
- ✅ Firebase project created: `meditation-by-vk`
- ✅ Firebase configuration file template created
- ⚠️ Cloud configuration deferred until Phase 3+ (using emulators for now)

## Steps to Complete Firebase Setup (Phase 3+ Only)

### ⚠️ SKIP THIS SECTION FOR NOW - Emulators Only Until Phase 3

### 1. Go to Firebase Console (Future - When Ready for Cloud)
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
  projectId: 'meditation-by-vk-89927',
  authDomain: 'meditation-by-vk-89927.firebaseapp.com',
  storageBucket: 'meditation-by-vk-89927.firebasestorage.app',
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

## Admin Setup (2025-10-22)

### Setting Admin Claims
Admin access requires custom claims set in Firebase Console:

1. Go to Firebase Console → Authentication → Users
2. Click on the user you want to make admin
3. Scroll to "Custom claims" section
4. Click "Edit" and paste:
   ```json
   {
     "admin": true
   }
   ```
5. Save changes
6. User must sign out and sign back in for claim to take effect

**Note**: You cannot verify admin claims in browser console (Flutter runs in Dart, not JavaScript). Admin status is checked automatically in `auth_provider.dart:47`.

## CORS Setup for Firebase Storage (2025-10-22)

### Why CORS?
Localhost uploads to Firebase Storage require CORS configuration to avoid cross-origin errors.

### One-Time Setup

**1. Install Google Cloud SDK**
- Download: https://cloud.google.com/sdk/docs/install
- Run installer, follow defaults
- Restart terminal after installation

**2. Authenticate**
```bash
gcloud auth login
```
Browser will open for Google sign-in.

**3. Set Project**
```bash
gcloud config set project meditation-by-vk-89927
```

**4. Create cors.json in meditation_by_vk/**
```json
[
  {
    "origin": ["http://localhost:*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```

**5. Apply CORS Config**
```bash
cd meditation_by_vk
gsutil cors set cors.json gs://meditation-by-vk-89927.firebasestorage.app
```

**6. Verify**
```bash
gsutil cors get gs://meditation-by-vk-89927.firebasestorage.app
```

**Done!** Uploads from localhost will now work. This is a permanent fix.

### Important: Storage Bucket URL
- **Modern bucket**: `meditation-by-vk-89927.firebasestorage.app` (use this)
- **Legacy bucket**: `meditation-by-vk-89927.appspot.com` (deprecated)

Ensure `lib/firebase_options.dart` uses `.firebasestorage.app`:
```dart
storageBucket: 'meditation-by-vk-89927.firebasestorage.app',
```

## Emulator Data Persistence (2025-10-22)

### Default Behavior
By default, emulator data is **wiped on every restart**.

### Persist Data Between Sessions
```bash
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
```

- `--import` loads previous data on startup
- `--export-on-exit` saves data when you stop emulators
- Creates `emulator-data/` folder with Firestore/Auth/Storage state

### Switching Between Emulator and Production

**Use Emulator:**
```bash
flutter run -d chrome --dart-define=USE_EMULATOR=true
```

**Use Production:**
```bash
flutter run -d chrome
# No flag = production Firebase
```

## Troubleshooting

### Categories Not Showing
- **In Emulator**: Database starts empty. Add test data via http://localhost:4000 or use `--import` flag
- **In Production**: Check Firestore security rules allow read access

### Upload Errors (CORS)
- Error: `blocked by CORS policy`
- **Fix**: Follow CORS Setup section above
- **Check bucket**: Ensure using `.firebasestorage.app` not `.appspot.com`

### Admin Login Issues
- **Can't verify claims in console**: Normal - Flutter uses Dart, not browser JavaScript
- **Access denied**: Check custom claims set correctly in Firebase Console
- **Still denied after setting claims**: Sign out and sign back in to refresh token

### Emulator Not Connecting
- Check console for `Connected to Firebase Emulators` message
- Ensure emulators running: `firebase emulators:start`
- Verify ports not in use: 9099 (Auth), 8080 (Firestore), 9199 (Storage)

### General Issues
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