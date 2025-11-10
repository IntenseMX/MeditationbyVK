Brand Color Wiring (2025-10-23)

- `AppTheme` exposes `brandPrimaryLight` (#AC7456) and `brandNeutralLight` (#D5B09C).
- `ThemeData.light()` uses these for BottomNavigationBar selected/unselected.
- No changes to dark theme nav colors.

Theme Flow Update (2025-10-23)

- `MyApp` wires `AppTheme.lightTheme`/`darkTheme`.
- Added ThemeExtension `AppColors { pop, onPop }` to centralize rare strong-accent red.
- Retrieval pattern: `final appColors = Theme.of(context).extension<AppColors>()!`.
- Example usage: `SplashScreen` logo box background uses `appColors.pop`; text uses `appColors.onPop`.

Theme Flow Update (2025-10-28)

- Extended ThemeExtension `AppColors` to include: `textOnGradient`, `statusSuccess`, `statusWarning`.
- Replaced hardcoded whites on gradient content (cards, trending belt, discover) with `appColors.textOnGradient`.
- Admin status icons now resolve via `statusSuccess`/`statusWarning` for brand-consistent theming.

Overlay Fade Change (2025-10-28)

- Foreground image overlays changed from uniform 45% gradient to a vertical fade (top transparent → bottom themed color) controlled by `AppTheme.thumbnailBottomFadeOpacity`.
- Improves thumbnail clarity while preserving text contrast.
- Touched files: `presentation/screens/home_screen.dart` (recommended + trending belt), `presentation/widgets/meditation_card.dart`.

Theme Presets (2025-10-28)

- 12 preset palettes defined in `config/theme_presets.dart` with light/dark `ColorScheme` + `AppColors`.
- `themeSelectionProvider` persists selected preset key in SharedPreferences.
- `currentLightThemeProvider/currentDarkThemeProvider` build ThemeData from the preset.
- Themes screen at `/themes` lets users preview and apply presets.

Theme Tinting System (2025-11-03)

- Background and surface tinting via `Color.alphaBlend()` in `_cs()` helper function.
- Mobile-first tinting constants (tuned for Android compositor):
  - `kLightBackgroundTint = 0.50` - Primary color blended into light scaffold background
  - `kDarkBackgroundTint = 0.32` - Primary color blended into dark scaffold background
  - `kLightSurfaceTint = 0.35` - Primary color blended into light mode cards/sheets
  - `kDarkSurfaceTint = 0.10` - Primary color blended into dark mode cards/sheets
  - `kSurfaceVariantOpacity = 0.18` - Reduced opacity for mobile compositor performance
- `scaffoldBackgroundColor` uses tinted `scheme.background` (not white/black default).
- Each theme's primary color tints the entire app background for visual distinction.
- Removed animated gradient overlay from `MainScaffold` to ensure theme background is visible.

Color Scheme Migration (2025-11-03)

- Migrated all hardcoded `AppTheme.*` colors to `Theme.of(context).colorScheme` properties.
- Updated screens: `home_screen.dart`, `progress_screen.dart`, `profile_screen.dart`, `discover_screen.dart`.
- Text colors, container backgrounds, borders, and icons now adapt to selected theme preset.
- Theme-aware colors: `onSurface`, `onSurfaceVariant`, `primary`, `tertiary`, `surfaceVariant`, `outline`.

Theme Mode Persistence (2025-11-03)

- `ThemeModeNotifier` persists theme mode (light/dark) in SharedPreferences with key `theme_mode_v1`.
- Default mode: `ThemeMode.light` (explicit, not system).
- `ThemeSelectionNotifier.load()` also loads persisted theme mode on app startup.
- Dark mode switch in Profile screen reflects effective theme mode and updates persistence.

# MEDITATION BY VK - CODE FLOW

This document provides a comprehensive overview of how code flows throughout the Meditation by VK Flutter application, detailing initialization, runtime behavior, and system interactions.

## 📚 Documentation Context

**Companion Documents:**
- **[APP_LOGIC.md](./APP_LOGIC.md)** - Quick reference with one-liner descriptions of all modules
- **[PLANNING.md](./PLANNING.md)** - Architecture decisions and technology rationale
- **[TASK.md](./TASK.md)** - Current implementation status and phase breakdown
- **[CLAUDE.md](./CLAUDE.md)** - Development rules and coding standards
 - **[docs/architecture/Theming.md](./docs/architecture/Theming.md)** - Theming system (presets, tinting, how to add themes)

**This document is the PRIMARY REFERENCE for:**
- System initialization sequences
- Data flow pipelines
- State management patterns
- Integration points between systems

## Table of Contents

### PART I: INITIALIZATION & BOOTSTRAP
1. [Application Entry & Bootstrap](#1-application-entry--bootstrap)
2. [Firebase Initialization Flow](#2-firebase-initialization-flow)
3. [Theme & Configuration Setup](#3-theme--configuration-setup)

### PART II: NAVIGATION & ROUTING
4. [GoRouter Configuration](#4-gorouter-configuration)
5. [Screen Navigation Flow](#5-screen-navigation-flow)
6. [Deep Linking Support](#6-deep-linking-support)

### PART III: STATE MANAGEMENT
7. [Riverpod Provider Architecture](#7-riverpod-provider-architecture)
8. [Provider Dependency Graph](#8-provider-dependency-graph)
9. [State Update Flow](#9-state-update-flow)

### PART IV: AUTHENTICATION SYSTEM
10. [Authentication Flow](#10-authentication-flow)
11. [Guest Mode Handling](#11-guest-mode-handling)
12. [Session Management](#12-session-management)

### PART V: AUDIO PLAYBACK
13. [Audio Service Architecture](#13-audio-service-architecture)
14. [Background Playback Setup](#14-background-playback-setup)
15. [Audio State Management](#15-audio-state-management)

### PART VI: DATA LAYER
16. [Firestore Integration](#16-firestore-integration)
17. [Model Serialization](#17-model-serialization)
18. [Offline Caching Strategy](#18-offline-caching-strategy)

### PART VII: USER INTERFACE
19. [Screen Architecture](#19-screen-architecture)
20. [Widget Composition](#20-widget-composition)
21. [Responsive Design](#21-responsive-design)

### PART VIII: FEATURES & SERVICES
22. [Meditation Discovery](#22-meditation-discovery)
23. [Progress Tracking](#23-progress-tracking)
24. [Streak Management](#24-streak-management)
25. [Premium Features](#25-premium-features)

### PART IX: PERSISTENCE & SYNC
26. [Local Storage](#26-local-storage)
27. [Cloud Sync](#27-cloud-sync)
28. [Data Migration](#28-data-migration)

---

## PART I: INITIALIZATION & BOOTSTRAP

### 1. Application Entry & Bootstrap

**Entry Point Flow:**
```
main.dart → main() → runApp()
├── WidgetsFlutterBinding.ensureInitialized() - Initialize Flutter engine
├── Firebase.initializeApp() - Setup Firebase with platform config
├── Error handling with try-catch for graceful failures
├── Connect to Firebase emulators if EnvConfig.useEmulator
└── runApp(ProviderScope(child: MyApp())) - Start app with Riverpod
```

**MyApp Widget:**
```
MyApp (StatelessWidget)
├── MaterialApp.router - Uses GoRouter for navigation
├── Apply light/dark themes from AppTheme
├── Set app title and disable debug banner
└── Configure router from appRouter instance
```

**Development vs Production:**
```
EnvConfig.useEmulator = true (Local development)
├── Connect to localhost emulators
├── Skip Firebase Analytics
├── Disable Crashlytics
└── Use test data

EnvConfig.useEmulator = false (Production)
├── Connect to Firebase Cloud
├── Enable Analytics tracking
├── Enable Crashlytics reporting
└── Use production data
```

### 2. Firebase Initialization Flow

**Firebase Setup Pipeline:**
```
Firebase.initializeApp()
├── Load firebase_options.dart configuration
│   └── IMPORTANT: storageBucket = 'meditation-by-vk-89927.firebasestorage.app' (modern, not .appspot.com)
├── Platform detection (Web/Android/iOS)
├── Initialize core services
└── Return Firebase app instance

Emulator Connection (if enabled):
├── FirebaseFirestore.useFirestoreEmulator(host, 8080)
├── FirebaseAuth.useAuthEmulator(host, 9099)
├── FirebaseStorage.useStorageEmulator(host, 9199)
└── Print success messages to console
```

**Service Initialization Order:**
1. Firebase Core - Platform detection and setup
2. Firebase Auth - Authentication service
3. Cloud Firestore - Database service
4. Firebase Storage - File storage service (CORS required for localhost uploads)
5. Firebase Analytics (production only)
6. Firebase Crashlytics (production only)

**Storage CORS Configuration (2025-10-22):**
```
Required for localhost development uploads:
├── Install Google Cloud SDK
├── Authenticate: gcloud auth login
├── Set project: gcloud config set project meditation-by-vk-89927
├── Create cors.json with localhost:* origin
├── Apply: gsutil cors set cors.json gs://meditation-by-vk-89927.firebasestorage.app
└── Verify: gsutil cors get gs://meditation-by-vk-89927.firebasestorage.app
```

### 3. Theme & Configuration Setup

**Theme System:**
```
AppTheme class (core/theme.dart)
├── lightTheme - Material3 light mode configuration
├── darkTheme - Material3 dark mode configuration
├── Deep Crimson color palette (#810000 primary)
│   ├── deepCrimson (#810000) - Primary brand color
│   ├── amberBrown (#944111) - Secondary accent
│   ├── agedGold (#C2A46C) - Tertiary highlights
│   ├── warmSandBeige (#EAE6DA) - Background/surfaces
│   ├── richTaupe (#BCA98C) - Dividers/borders
│   └── softCharcoal (#3B332C) - Text/contrast
├── Dark mode toggle via themeModeProvider (persisted in SharedPreferences)
├── Button styles with 12px border radius
└── Theme presets with tinted backgrounds (12 luxury palettes)

Theme Preset System (config/theme_presets.dart):
├── 12 preset themes with light/dark ColorScheme variants
├── Background tinting via Color.alphaBlend() for visual distinction
├── Mobile-optimized tinting constants (kLightBackgroundTint, kDarkBackgroundTint, etc.)
├── scaffoldBackgroundColor uses tinted scheme.background
└── All UI elements use Theme.of(context).colorScheme (no hardcoded colors)
```

**Configuration Constants:**
```
Constants class (core/constants.dart)
├── App metadata (name, version, build)
├── Network settings (timeout: 30s, retries: 3)
├── UI dimensions (padding: 16px, radius: 12px)
├── Animation durations (300ms default)
├── Meditation bounds (60s min, 3600s max)
└── Cache keys for local storage
```

---

## PART II: NAVIGATION & ROUTING

### 4. GoRouter Configuration (2025-10-28)

**Route Structure:**
```
appRouter (presentation/app_router.dart)
├── /splash → SplashScreen - Startup animation + CTA pause
├── / (home) → MainScaffold - Bottom navigation container
├── /player/:id → PlayerScreen - Audio playback with Hero card animation
├── /admin → AdminDashboardScreen (guarded by auth + admin claim)
└── /categories, /meditations, /meditations/:id (admin routes)
```

TEMP (2025-10-21):
- Settings shows Admin button unconditionally for development convenience; router guard still enforces admin access.

Admin Guard & Auth Gate:
```
Redirect checks `authProvider`:
├── If route starts with /admin, /meditations, /categories
├── And user unauthenticated or isAdmin == false → redirect '/login'
└── Else allow
```

Note (2025-10-23):
- `authProvider` initialization is deferred with a microtask to avoid provider state writes during widget tree build.

**Route-Specific Transitions:
├── Default pages: Slide + fade (right-to-left entry)
│   └── Secondary fade (background exits fast in first 30%)
└── Player route: Fade-only transition
    ├── Hero animation handles card expansion
    ├── Background fades out quickly (Interval 0.0-0.3)
    └── Player content fades in delayed (Interval 0.3-1.0)
```

**Route Guards:**
```
Redirect logic:
├── Check authentication state via authProvider
├── If route starts with /admin, /meditations, /categories
│   └── If not authenticated or isAdmin == false → redirect '/login'
├── If route is '/', '/discover', '/progress', '/profile' and no user → redirect '/splash'
└── Handle deep links for shared content
```

### 5. Screen Navigation Flow (2025-10-28)

**Navigation Patterns:**
```
Imperative Navigation:
├── context.go('/path') - Replace current route
├── context.push('/path') - Add to navigation stack
├── context.pop() - Remove from stack
└── context.goNamed('routeName') - Named navigation
```

Settings → Admin:
```
ProfileScreen → Settings list
├── TEMP: Admin Panel item always visible (revert to auth check later)
└── Tap → context.go('/admin') (transition + guard applied)
```

Settings → Subscription Management (2025-11-07)
- Gate: `ref.watch(subscriptionProvider).isPremium`.
- UI: ListTile "Manage Subscription" with external-link icon.
- Action: `_launchUrl` to platform subscriptions page (iOS/Android).
- Rationale: Show only to subscribed users to avoid irrelevant store pages.

**Page Transition System (2025-10-20):**
```
Custom Transitions (_buildPageWithTransition):
├── Primary animation: Slide right-to-left with fade
├── Secondary animation: Fast fade out (Interval 0.0-0.3)
│   └── Purpose: Exit background screen quickly during forward nav
├── Duration: 600ms (AnimationDurations.screenTransition)
└── Applied to: Splash, Main scaffold

Player Screen Transition (_buildPlayerTransition):
├── Fade-only approach (no slide)
├── Hero animation: Card expansion dominates visual
├── Secondary fade: Home screen cards disappear in first 30%
├── Delayed content fade: Interval 0.3-1.0 (emphasized curve)
├── Backdrop scrim: Fades to 50% opacity for depth
└── Duration: 750ms (AnimationDurations.long2)

Technical Implementation:
├── CustomTransitionPage with transitionsBuilder
├── Interval curves for staged animations
├── FadeTransition + SlideTransition composition
└── Animation constants from core/animation_constants.dart
```

**Screen Lifecycle:**
```
Screen Mount → initState() → Build UI → User Interaction → Navigation
├── ConsumerWidget for stateless screens
├── ConsumerStatefulWidget for stateful screens
├── ref.watch() for reactive updates
└── ref.read() for one-time reads
```

### 6. Deep Linking Support

**Deep Link Handling:**
```
URL Structure:
├── app://meditation/:id - Open specific meditation
├── app://category/:name - Browse category
├── app://profile - User profile
└── app://progress - Statistics view

Platform Setup:
├── iOS: Info.plist URL schemes
├── Android: AndroidManifest intent filters
└── Web: URL path matching
```

---

## PART III: STATE MANAGEMENT

### 7. Riverpod Provider Architecture

**Provider Types:**
```
Provider - Immutable value provider
StateProvider - Simple mutable state
FutureProvider - Async data loading
StreamProvider - Real-time data streams
StateNotifierProvider - Complex state logic
NotifierProvider - New generation providers
```

**Provider Organization:**
```
providers/
├── auth_provider.dart - Authentication state
├── meditation_provider.dart - Meditation list/details
├── audio_player_provider.dart - Playback state
├── progress_provider.dart - User statistics
├── settings_provider.dart - App preferences
└── user_provider.dart - Profile management
```

### Editor Provider Pattern (2025-10-23)
```
Meditation Editor:
├── Provider: `NotifierProvider<MeditationEditorNotifier, MeditationEditorState>`
│   └── Methods: load(id), setTitle/Description/Tags, saveDraft(), publish(), delete()
├── Screen: `MeditationEditorScreen`
│   ├── Defers `load(id)` via `WidgetsBinding.instance.addPostFrameCallback`
│   ├── Watches provider with `ref.watch(meditationEditorProvider)`
│   └── Prevents provider mutations during build/mount
└── Rationale: Riverpod v3 compatibility + safe lifecycle without build-time writes
```

### 8. Provider Dependency Graph

**Core Dependencies:**
```
authProvider
├── userProvider (depends on auth state)
│   ├── progressProvider (user statistics)
│   └── settingsProvider (user preferences)
├── meditationProvider (filter by user type)
└── audioPlayerProvider (track for user)

firestoreProvider
├── meditationProvider (data source)
├── progressProvider (session storage)
└── userProvider (profile storage)
```

### 9. State Update Flow

**Update Pipeline:**
```
User Action → Provider Update → State Change → UI Rebuild
├── User taps button
├── Call provider method
├── Update internal state
├── Notify listeners
├── Widgets using ref.watch() rebuild
└── UI reflects new state
```

**Optimization Patterns:**
```
select() - Listen to specific properties
when() - Conditional UI based on AsyncValue
family() - Parameterized providers
autoDispose() - Automatic cleanup
keepAlive() - Prevent disposal
```

---

## PART IV: AUTHENTICATION SYSTEM

### 10. Authentication Flow (2025-10-28)

**Email/Password Flow:**
```
Registration:
├── Validate email format
├── Check password strength
├── FirebaseAuth.createUserWithEmailAndPassword()
├── Send email verification
├── Create Firestore user profile
└── Navigate to home

States:
├── initial: no session (no auto-auth)
├── guest: anonymous Firebase user
└── authenticated: email/password user

Guest (2025-10-28):
├── Tap Continue as Guest on Splash (CTA; no auto-login)
├── authProvider.signInAnonymously()
└── Navigate to home

Login:
├── Validate credentials
├── authProvider.signInWithEmail()
├── Fetch admin claims (getIdTokenResult)
└── Navigate to home (or admin dashboard if admin)
```

**Google Sign-In Flow:**
```
GoogleSignIn.signIn()
├── Show account picker
├── Get Google auth credentials
├── FirebaseAuth.signInWithCredential()
├── Create/update user profile
├── Fetch admin claims
└── Navigate to home
```

**Admin Claims Verification (2025-10-22):**
```
Admin Access Check:
├── On auth state change → getIdTokenResult(true)
├── Extract token.claims?["admin"]
├── Store isAdmin flag in AuthState
├── Router guard checks isAdmin for /admin/* routes
└── Redirect to /login if not admin

Admin Setup Process:
├── Firebase Console → Authentication → Users
├── Select user → Edit Custom Claims
├── Set: {"admin": true}
├── User signs out and re-authenticates
└── Claims take effect on next token refresh
```

### 11. Guest Mode Handling (2025-10-28)

**Guest User Flow:**
```
Skip Authentication:
├── FirebaseAuth.signInAnonymously()
├── Create temporary user ID
├── Limited feature access
├── No cloud sync
├── Convert to full account option
└── Data deleted on sign out
```

**Guest Limitations:**
```
Disabled Features:
├── Progress sync across devices
├── Premium content access
├── Profile customization
├── Social features
└── Offline downloads (Phase 3)
```

### 12. Session Management

**Session Lifecycle:**
```
App Launch → Check Saved Session → Validate Token → Auto Login
├── SharedPreferences.getString('session_token')
├── Verify with Firebase Auth
├── Refresh if expired
├── Load user data
└── Update UI state

Session Expiry:
├── Token refresh on 401 errors
├── Background refresh every hour
├── Force logout on invalid token
└── Clear local data on logout
```

---

## PART V: AUDIO PLAYBACK

### 13. Audio Service Architecture

**just_audio Integration:**
```
AudioService (services/audio_service.dart)
├── AudioPlayer instance management
├── Stream URL loading from Firebase Storage
├── Playback control methods (play, pause, seek)
├── Position and duration streams
├── Background audio configuration
└── Error handling and retry logic
```

**Audio Pipeline:**
```
Load Meditation → Fetch Audio URL → Initialize Player → Start Playback
├── Get meditation document from Firestore
├── Extract audioUrl field
├── AudioPlayer.setUrl(audioUrl)
├── Handle loading state
├── AudioPlayer.play()
└── Update UI with position stream
```

### 14. Background Playback Setup

**iOS Configuration:**
```
Info.plist:
├── UIBackgroundModes: audio
├── Configure AVAudioSession
├── Handle interruptions
└── Now Playing info update

AppDelegate.swift:
├── Audio session category setup
├── Remote control events
└── Interruption handling
```

**Android Configuration:**
```
AndroidManifest.xml:
├── FOREGROUND_SERVICE permission
├── Audio service declaration
├── Wake lock permission
└── Media button receiver

AudioService:
├── Notification channel setup
├── Media session management
├── Playback state updates
└── Notification controls
```

### 15. Audio State Management

**AudioPlayerProvider State:**
```
AudioPlayerState:
├── currentMeditation - Active meditation
├── isPlaying - Playback status
├── position - Current position
├── duration - Total duration
├── isLoading - Loading state
├── error - Error message
└── completionPercentage - Progress
```

**State Updates:**
```
Stream Subscriptions:
├── playerStateStream → isPlaying updates
├── positionStream → position updates
├── durationStream → duration updates
├── processingStateStream → loading/error
└── sequenceStateStream → playlist updates
```

### 15.1 Interruption & Audio Session Flow (2025-10-27)
```
Initialization:
├── AppAudioHandler._initAudioSession()
│   ├── AudioSession.instance.configure(music)
│   ├── Subscribe interruptionEventStream
│   ├── Subscribe becomingNoisyEventStream
│   └── Set AndroidAudioAttributes (media/music)
└── AppAudioHandler._initStreams() (existing playback state wiring)

Runtime:
├── Interruption begin (pause/unknown) → handler.pause() → resume position saved
├── Interruption begin (duck) → volume 0.3
├── Interruption end (duck) → volume 1.0 (no auto-resume)
└── Becoming noisy (unplug) → handler.pause()

Resume Persistence:
├── Throttled writes every 15s during playback
├── On pause/stop/complete → write resume
└── On next load → seek to stored position (bounded by duration)
```

---

## PART VI: DATA LAYER

### 16. Firestore Integration

**Collection Structure:**
```
Firestore Database:
├── users/{userId} - User profiles
│   ├── email, displayName, photoUrl
│   ├── isPremium, isGuest
│   ├── createdAt, updatedAt
│   └── preferences (map)
├── meditations/{meditationId} - Content
│   ├── title, description, duration
│   ├── audioUrl, coverImageUrl
│   ├── categories (array)
│   ├── isPremium, isPublished
│   └── statistics (playCount, rating)
├── userProgress/{userId}/sessions/{sessionId}
│   ├── meditationId, userId
│   ├── startedAt, completedAt
│   ├── duration, completed
│   └── notes (optional)
└── categories/{categoryId}
    ├── name, icon, color
    ├── order, isActive
    └── meditationCount
```

Progress Tracking (Phase 3C - 2025-11-05)

- Sessions path: `userProgress/{uid}/sessions/{sessionId}`
- Session document fields:
  - `meditationId: string`
  - `meditationTitle: string?` (denormalized at write)
  - `startedAt: Timestamp (UTC)`
  - `completedAt: Timestamp (UTC)` (serverTimestamp on upsert)
  - `duration: int (seconds listened)`
  - `completed: bool`
- Start capture: First transition to playing detected via `playerStateStream` (handles auto-play and manual play)
- Progressive updates: Minute-by-minute upserts via `SetOptions(merge: true)` every 60 seconds with actual listened duration
- Completion trigger: 90% of track duration OR natural completion → marks completed=true, sets duration to full track length, increments playCount atomically
- Idempotency: `sessionId = "{uid}_{meditationId}_{startedAtMsUtc}"` ensures single session per play
- Threading: Audio callback uses Firestore-only writes (`tryWriteSession`, `upsertSession`) - no SharedPreferences/plugins in audio thread
- Offline: Firestore SDK handles offline queueing automatically; SharedPreferences queue only for foreground retry flows
- Streaks: Computed only from completed sessions (completed=true) using UTC day boundaries (current + longest streak)
- Provider output: Matches UI shape (`daily/weekly/monthly`) aggregated from last 60 days; minutes rounded UP (4.4 → 5)
- Index: Composite index on sessions collection: completed ASC, completedAt DESC (deployed as COLLECTION_GROUP)

**Query Patterns:**
```
Common Queries:
├── Get user by ID
├── List meditations by category
├── Filter premium content
├── Get user's recent sessions
├── Calculate streak from sessions
└── Top rated meditations
```

### 17. Model Serialization

**Model Classes:**
```
models/
├── user_model.dart
│   ├── User.fromJson(Map<String, dynamic>)
│   ├── User.toJson()
│   └── copyWith() method
├── meditation_model.dart
│   ├── Meditation.fromFirestore(DocumentSnapshot)
│   ├── Meditation.toFirestore()
│   └── Duration parsing
├── session_model.dart
│   ├── Session.fromJson()
│   ├── Session.toJson()
│   └── Completion calculation
└── category_model.dart
    ├── Category.fromJson()
    └── Category.toJson()
```

**Type Safety:**
```
JSON Serialization:
├── Explicit type casting
├── Null safety handling
├── Default values
├── Validation on parse
└── Error recovery
```

### 18. Offline Caching Strategy (2025-11-05)

**Firestore Offline (Phase 1-2):**
```
Built-in Caching:
├── Automatic offline persistence
├── Optimistic updates
├── Sync when online
├── Conflict resolution
└── Cache size limits

Configuration:
Mobile:
```
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```
Web:
```
await FirebaseFirestore.instance.enablePersistence(
  const PersistenceSettings(synchronizeTabs: true),
);
```

Reconnection Sync (Section F):
- `ProgressService.start()` subscribes to `Connectivity().onConnectivityChanged`
- API note (2025-11-05): v6 emits `List<ConnectivityResult>`; we treat any non-none as online
- On reconnect: calls `flushPending()` to write queued sessions
- Provider wiring ensures start/dispose lifecycle to avoid leaks

### Achievements (2025-11-10)

**Data Model:**
```
users/{uid}
├── achievements (map<string, timestamp>)  // e.g. "streak_5": 2025-11-10T12:34:56Z
```

**Awarding Logic:**
```
progressDtoProvider (providers/progress_provider.dart)
├── Listens to recent sessions + users/{uid}
├── Computes:
│   ├── current streak (days, completed-only, UTC)
│   ├── completed session count
│   └── total minutes (rounded up from seconds)
├── Unlocks missing achievements (idempotent):
│   ├── streak_5, streak_10, streak_30
│   ├── sessions_5, sessions_25, sessions_50
│   └── minutes_50, minutes_100, minutes_300
└── Writes: users/{uid}.achievements.{key} = serverTimestamp() (merge update)
```

**UI Integration:**
```
ProgressScreen (presentation/screens/progress_screen.dart)
├── Receives achievements list from progressDtoProvider
└── Renders dynamic badges (Wrap) with unlocked state
```

UI Indicator (2025-11-05):
- `isOfflineProvider` (Riverpod StreamProvider) emits offline state
- `MaterialApp.router(builder:)` wraps child with `OfflineBanner` when offline
- `OfflineBanner` uses theme `ColorScheme` (no hardcoded colors), 36px height, icon + text
```

**Local Audio Cache (Phase 3):**
```
Future Implementation:
├── Download meditation audio
├── Store in app documents directory
├── Track cached files in SharedPreferences
├── LRU eviction policy
├── Size limit management (500MB free, unlimited premium)
└── Background download service
```

---

## PART VII: USER INTERFACE

### 19. Screen Architecture

**Implemented Screens (Phase 1):**
```
presentation/screens/
├── splash_screen.dart - CLARITY logo with layered zen animations (see §19.1)
├── main_scaffold.dart - Bottom navigation container (IndexedStack)
├── home_screen.dart - Meditation cards, search, trending section
├── discover_screen.dart - Category grid with filter button
├── progress_screen.dart - Day/Week/Month tabs, charts, badges
└── profile_screen.dart - User stats, settings, dark mode toggle

presentation/widgets/
└── meditation_card.dart - Reusable meditation display card
```

**Screen Patterns:**
```
Base Structure:
├── ConsumerWidget (stateless) or ConsumerStatefulWidget base
├── Scaffold with SafeArea
├── CustomScrollView with Slivers for performance
├── Dummy data from DummyData class
└── Theme-aware styling (AppTheme constants)

Common Elements:
├── Bottom navigation (4 tabs: Home, Discover, Progress, Settings)
├── Gradient backgrounds on cards
├── Premium badges where applicable
└── Consistent spacing (20px padding)
```

### 20. Widget Composition

**Reusable Components:**
```
widgets/
├── MeditationCard - Grid/list item display
├── CategoryChip - Category selection
├── ProgressRing - Circular progress
├── StatCard - Metric display
├── AudioControls - Playback buttons
├── TimerDisplay - Duration countdown
├── StreakBadge - Achievement display
└── PremiumBadge - Premium indicator
```

**Component Props:**
```
MeditationCard:
├── meditation (required) - Data model
├── onTap (required) - Tap handler
├── showDuration - Display time
├── showCategory - Display tags
└── isCompact - Dense layout
```

### 21. Responsive Design

**Breakpoints:**
```
Screen Sizes:
├── Mobile: < 600px width
├── Tablet: 600-1200px width
├── Desktop: > 1200px width

Layout Adaptation:
├── Mobile: Single column
├── Tablet: 2-3 columns
├── Desktop: 4+ columns
└── Adaptive navigation (drawer vs rail)
```

**Responsive Utilities:**
```
MediaQuery Usage:
├── MediaQuery.of(context).size
├── MediaQuery.of(context).orientation
├── MediaQuery.of(context).padding
└── MediaQuery.of(context).textScaleFactor

LayoutBuilder:
├── Adaptive grid columns
├── Conditional widget display
└── Dynamic spacing
```

---

### 19.1 Splash Screen Animations (2025-10-29)

Overview:
```
Layers (back → front):
1) ZenBackground (animated gradient, parallax blobs, sparse particles)
2) Logo tile with BreathingGlow (soft radial pulse)
3) Title with subtle shimmer (ShaderMask sweep)
4) Tagline
5) CTA stack with staggered entrance
```

Timing & Curves:
```
Config in core/animation_constants.dart → SplashAnimationConfig
├── gradientCycle: 12s (infinite)
├── parallaxPeriod: 18s (infinite)
├── particleDriftPeriod: 16s (infinite)
├── glowPulse: 5s (auto-reverse)
├── shimmerSweep: 3.5s (loop)
├── ctaReveal: 1.35s (AnimatedSwitcher)
├── ctaStagger: 120ms between buttons
└── ctaItemDuration: 450ms per button (opacity + slide)
Curves: AnimationCurves.standardEasing for CTA transitions
```

Files:
```
lib/presentation/screens/splash_screen.dart
lib/presentation/widgets/zen_background.dart
lib/presentation/widgets/breathing_glow.dart
lib/core/animation_constants.dart (SplashAnimationConfig)
```

Performance Guards:
- Particle count capped (12) with deterministic seed
- Off-screen drawing minimized; heavy blur limited to 3 blobs
- RepaintBoundary around animated background
- All timings centralized; easy to disable/retune

Behavior:
- Splash holds ~2s brand moment, then reveals CTAs
- No auto-navigation; user explicitly continues (guest or sign-in)


## PART VIII: FEATURES & SERVICES

### 22. Meditation Discovery

**Browse Features:**
```
Discovery Screen:
├── Category filtering with chips
├── Search by title/description
├── Sort by popularity/duration/newest
├── Premium filter toggle
├── Pagination with infinite scroll
└── Recently played section
```

**Recommendation Engine (Future):**
```
Planned Algorithm:
├── Collaborative filtering
├── Content-based matching
├── Time-of-day suggestions
├── Mood-based recommendations
└── ML model integration
```

### 23. Progress Tracking

**Session Recording:**
```
Track Session:
├── Start time on play
├── Pause/resume handling
├── Completion threshold (80%)
├── Auto-save every 30 seconds
├── Final save on complete/exit
└── Sync to Firestore
```

**Statistics Calculation:**
```
Metrics:
├── Total meditation time
├── Sessions this week/month
├── Average session duration
├── Favorite meditation
├── Category distribution
└── Time of day patterns
```

### 24. Streak Management

**Streak Logic:**
```
Daily Streak:
├── Check last session date
├── Compare with today
├── Increment if consecutive
├── Reset if gap > 1 day
├── Store current and longest
└── Notification reminders
```

**Streak Recovery (Premium):**
```
Freeze Feature:
├── Skip 1 day without reset
├── Limited uses per month
├── Premium only
└── Manual activation
```

### 25. Premium Features (2025-11-07)

**Premium Gates:**
```
Feature Access:
├── Check user.isPremium flag
├── Show upgrade prompt if false
├── Track feature usage attempts
├── A/B test paywall designs
└── Grace period for trials
```

**Premium Content:**
**Subscription Flow (Monthly, $4.99):**
```
Paywall → Subscribe
├── subscriptionProvider.purchaseMonthly()
├── SubscriptionService.buyMonthly() → in_app_purchase
├── purchaseStream → status=purchased/restored
├── SubscriptionService._grantPremiumEntitlement()
│   └── ProgressService.upsertUserPremium(isPremium: true)
├── Firestore users/{uid}.isPremium = true
└── UI observes users/{uid} → subscriptionProvider updates isPremium
```

**Routes:**
```
app_router.dart
├── /paywall → PaywallScreen
└── Guards: None (public)
```

**IAP Kill Switch (2025-11-07):**
```
SubscriptionConfig.enableIAP
├── false (dev default):
│   ├── Skip in_app_purchase initialization
│   ├── isAvailable() → false
│   ├── queryProducts() → [] (UI uses fallback price)
│   └── Gates still enforced via users/{uid}.isPremium
└── true (prod testing):
    └── Full store flows enabled (Apple/Google)
```
```
Exclusive Access:
├── Premium meditations
├── Advanced programs
├── Offline downloads (Phase 3)
├── Unlimited favorites
├── Statistics export
└── Priority support
```

### 25.1 Home Premium UI Consistency (2025-11-07)
- Trending belt and Recommended lists now render via `MeditationCard` in compact mode.
- Premium treatment (badge + lock overlay) and paywall-gated taps are centralized in `MeditationCard`.
- Result: Identical premium visuals/behavior across Recently Added, Trending, and Recommended.

---

### Admin: Meditations List (2025-10-22)

Overview:
```
Route: /meditations (guarded by admin)
Files:
├── presentation/screens/admin/meditations_list_screen.dart
├── providers/meditations_list_provider.dart
└── services/meditation_service.dart (stream + bulk ops)
```

Data Flow:
```
MeditationService.streamMeditations(status?) → StreamProvider (meditationsStreamProvider)
 → Client-side filters (search/title contains, categoryId, difficulty, isPremium)
 → UI table with multi-select + bottom action bar
 → Bulk actions call service: bulkPublish / bulkUnpublish / bulkDelete
```

UI Behavior:
- Columns: thumbnail, title, category, status, duration, created date
- Row click navigates to editor: `/meditations/:id`
- Multi-select checkboxes, sticky bottom bar with Publish / Unpublish (confirm) / Delete (confirm)
- Back button in AppBar navigates to `/admin`

### Admin: Meditation Editor (2025-10-23)

Overview:
```
Route: /meditations/new, /meditations/:id (guarded by admin)
Files:
├── presentation/screens/admin/meditation_editor_screen.dart
└── providers/meditation_editor_provider.dart (NotifierProvider)
```

Data Flow:
```
On open with :id → Screen schedules provider.load(id) post-frame →
Provider sets isSaving=true and fetches document →
State populated (title/description/tags/category/difficulty/isPremium/status/imageUrl/audioUrl/durationSec) →
UI binds TextEditingControllers and fields to provider setters →
Save/Publish/Delete call service methods and update state
```

Lifecycle Safety:
- No provider writes during build; loading is deferred post-frame.
- Works with Riverpod v3 without AsyncNotifier APIs.

Query & Index Strategy:
- Server-side filter: `status` (safe, avoids composite index sprawl)
- Client-side filters: `search` (case-insensitive title), `categoryId`, `difficulty`, `isPremium`
- Consider adding composite indexes later if moving filters server-side

Security Rules (2025-10-22):
- Admins can read all meditations (draft + published)
- Public reads restricted to `status == 'published'`


## PART IX: PERSISTENCE & SYNC

### 26. Local Storage

**SharedPreferences Usage:**
```
Local Data:
├── Session token
├── Last sync timestamp
├── User preferences
├── Draft session data
├── Cache metadata
└── Feature flags
```

**Storage Patterns:**
```
Key Naming:
├── Prefix with app name
├── Use underscores
├── Version suffix if needed
├── Clear on logout
└── Migrate on app update
```

### 27. Cloud Sync

**Sync Strategy:**
```
Sync Triggers:
├── App launch
├── Network reconnection
├── Session completion
├── Profile update
├── Every 5 minutes (active)
└── Before app background
```

**Conflict Resolution:**
```
Resolution Rules:
├── Server wins for profile
├── Latest timestamp for sessions
├── Merge for preferences
├── Highest value for streaks
└── User choice for conflicts
```

### 28. Data Migration

**Migration Pipeline:**
```
Version Check:
├── Compare stored version
├── Run migrations sequentially
├── Update version number
├── Backup before migration
└── Rollback on failure
```

**Migration Scripts:**
```
Migrations:
├── v1_to_v2: Add streak fields
├── v2_to_v3: Rename duration field
├── v3_to_v4: Add premium flag
└── Future migrations...
```

---

## Architecture Decisions

### State Management Choice
**Riverpod over Provider** - Better performance, compile-time safety, and DevEx

### Backend Choice
**Firebase over Custom** - Faster time-to-market, managed infrastructure

### Audio Library
**just_audio** - Industry standard, background support, streaming capability

### Navigation
**GoRouter** - Official package, declarative routing, deep link support

### Architecture Pattern
**Clean Architecture** - Separation of concerns, testability, maintainability

---

## Performance Optimizations

### Image Loading
- Use cached_network_image package
- Lazy load with fade transitions
- Thumbnail generation for lists
- WebP format where possible

### List Performance
- Use ListView.builder for long lists
- Implement pagination (20 items/page)
- Add item extent for known heights
- Use const constructors

### State Updates
- Use select() to limit rebuilds
- Implement equality checks
- Cache computed values
- Debounce search inputs

---

## Error Handling Strategy

### Network Errors
```dart
try {
  await apiCall();
} on FirebaseException catch (e) {
  showSnackBar(e.message);
} on TimeoutException {
  showRetryDialog();
} catch (e) {
  logError(e);
  showGenericError();
}
```

### Audio Errors
- Fallback to lower quality stream
- Show retry button
- Cache last position
- Auto-resume on recovery

### Auth Errors
- Clear invalid tokens
- Show specific error messages
- Provide recovery options
- Log security events

---

## Testing Strategy

### Unit Tests
- Test providers independently
- Mock Firebase services
- Test model serialization
- Validate business logic

### Widget Tests
- Test screen rendering
- Verify navigation flows
- Test user interactions
- Check error states

### Integration Tests
- Test full user journeys
- Verify Firebase integration
- Test offline scenarios
- Performance testing

---

## Deployment Pipeline

### Development
- Firebase emulators for local testing
- Hot reload for rapid iteration
- Debug mode assertions
- Verbose logging

### Staging
- TestFlight / Play Console beta
- Separate Firebase project
- Limited user testing
- Performance monitoring

### Production
- CI/CD via GitHub Actions
- Automated version bumping
- Gradual rollout
- Crash monitoring with Sentry

---

## Quick Reference

### Common Patterns

**Provider Usage:**
```dart
final dataProvider = ref.watch(someProvider);
final notifier = ref.read(someProvider.notifier);
```

**Navigation:**
```dart
context.go('/path');
context.goNamed('routeName', params: {'id': '123'});
```

**Async Data Handling:**
```dart
ref.watch(futureProvider).when(
  data: (data) => DataWidget(data),
  loading: () => LoadingWidget(),
  error: (err, stack) => ErrorWidget(err),
);
```

### Key Files
- `main.dart` - App entry point
- `app_router.dart` - Navigation configuration
- `firebase_options.dart` - Firebase config
- `theme.dart` - Visual theming
- `constants.dart` - App constants

---

## Category Filtering Flow (2025-11-05)

- Discover → tap category card navigates to `/category/:id`.
- Route defined in `presentation/app_router.dart` (not part of admin-guarded paths).
- `CategoryMeditationsScreen` initializes `meditationsQueryProvider` to `{ status: 'published', categoryId }`.
- `meditationsStreamProvider` streams and client-filters by `categoryId` and `search`.
- Renders list using `MeditationCard` with theme `ColorScheme` gradients.

### Category Pagination (2025-11-05)

- Server-side filtering & pagination via `MeditationService.fetchPublishedByCategory()`
- Cursor-based pages ordered by `publishedAt desc`
- `categoryPaginationProvider(categoryId)` manages `loadFirstPage()` / `loadMore()`
- Screen shows “Load More” when `canLoadMore` is true

**Last Updated**: 2025-11-10

### Splash UX/Data Gating (2025-11-10)

- CTAs are now gated until BOTH intro animation completes and initial data is ready.
- A 4s fallback reveals a “Skip (loading in background)” button to proceed with Home skeletons active.
- Removed offscreen Home warmup overlay to avoid duplicate tree builds; image precache remains.
- Files: `presentation/screens/splash_screen.dart`

### Home Loading Skeletons (2025-11-10)

- Added shimmer skeletons for “Recently Added”, “Trending Now”, and “Recommended”.
- Smooth `AnimatedSwitcher` transitions replace spinners during first load.
- Files: `presentation/screens/home_screen.dart` (shimmer)

### Trending Belt Virtualization & Auto-Scroll (2025-11-10)

- Removed per-build 100× list allocation; now virtualized with modulo indexing.
- Replaced per-frame `jumpTo` with timer-throttled (~32ms) incremental scrolling, pausing on user interaction.
- Files: `presentation/screens/home_screen.dart` (TrendingBelt)

### Category Map Memoization (2025-11-10)

- Introduced `categoryMapProvider` to compute `categoryId -> name` only when category stream changes.
- Files: `providers/category_map_provider.dart`; consumed by `home_screen.dart`.

### Image Caching & Downscaling (2025-11-10)

- `MeditationCard` now uses `CachedNetworkImageProvider(maxWidth: …)` for downscaled decode and caching.
- Reduces memory and decode time for card thumbnails.
- Files: `presentation/widgets/meditation_card.dart`, `pubspec.yaml` (dependency)

### Perf Metrics Hook (2025-11-10)

- In debug, `WidgetsBinding.instance.addTimingsCallback` logs frame avg/p95 and jank count.
- Use profile mode + DevTools for authoritative measurements; debug logs are indicative.
- Files: `lib/main.dart`