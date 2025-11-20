Brand Palette (2025-10-23)

- Introduced `brandPrimaryLight` and `brandNeutralLight` in `AppTheme`.
- Applied to light mode BottomNavigationBar selected/unselected item colors.
- Keeps older `shrine*` names for compatibility; new code should prefer brand names.

UI Theming (2025-10-23)

- Introduced `AppColors` ThemeExtension for rare accent color usage.
- Keys: `pop` (#D00000), `onPop` (white). Registered in both light/dark themes.
- Used by `SplashScreen` logo tile; available app-wide via `Theme.of(context).extension<AppColors>()`.

UI Theming (2025-10-28)

- `AppColors` extended with `textOnGradient`, `statusSuccess`, `statusWarning`.
- Gradient-based UIs (MeditationCard, Discover, Home trending/recommended) now use `textOnGradient` for legible per-theme text.
- Admin status icons themed via `statusSuccess/statusWarning`.

Theme Presets (2025-10-28)

- `ThemePreset` model in `config/theme_presets.dart` with 15 entries.
- `themeSelectionProvider` stores current preset key in SharedPreferences.
- `ThemesScreen` (`/themes`) shows 12 preview tiles and Apply button.
- `main.dart` builds ThemeData from the selected preset.

Theme Tinting System (2025-11-03)

- Background tinting via `Color.alphaBlend()` applies primary color to scaffold/surface backgrounds.
- Mobile-first constants: `kLightBackgroundTint=0.50`, `kDarkBackgroundTint=0.32`, `kLightSurfaceTint=0.35`, `kDarkSurfaceTint=0.10`.
- Each theme's background is visibly tinted by its primary color for distinction.

New Presets Added (2025-11-03)

- `winter_wonderland` — cool blue palette inspired by frosted tones
- `burgundy_luxe` — deep burgundy with soft gold accents
- `racing_green_gold` — British racing green with gold detailing
- Removed animated gradient overlay from `MainScaffold` to show theme background.

Color Scheme Migration (2025-11-03)

- Replaced hardcoded `AppTheme.*` colors with `Theme.of(context).colorScheme` across all screens.
- Updated: `home_screen.dart`, `progress_screen.dart`, `profile_screen.dart`, `discover_screen.dart`.
- All UI elements (text, backgrounds, borders, icons) now adapt to selected theme preset.

Theme Mode Persistence (2025-11-03)

- `ThemeModeNotifier` persists light/dark mode in SharedPreferences (`theme_mode_v1` key).
- Default mode: `ThemeMode.light` (explicit).
- Loaded on app startup via `ThemeSelectionNotifier.load()`.

# MEDITATION BY VK - APP LOGIC

This document provides concise descriptions of all systems, services, and features in the Meditation by VK application.

**Last Updated**: 2025-11-20

### Performance & UX Updates (2025-11-10)

- SplashScreen: CTAs gated until intro animation completes AND initial data loads; 4s fallback shows “Skip (loading in background)”. Offscreen Home warmup overlay removed; image precache kept.
- HomeScreen: Added shimmer skeletons for Recently Added, Trending, Recommended; smooth transitions replace spinners.
- TrendingBelt: Virtualized list via modulo; auto-scroll now timer-throttled (~32ms), pauses on user interaction.
- Category Map: Added `categoryMapProvider` to memoize `categoryId → name`; Home consumes this provider.
- MeditationCard: Uses `CachedNetworkImageProvider(maxWidth: …)` to downscale/cache images, reducing memory/decodes.
- Perf Metrics: Debug-only frame timing logs (avg/p95/jank) via `addTimingsCallback` in `main.dart` (use profile for accurate).

## 📚 Documentation Context

**Primary Companion:**
- **[CODE_FLOW.md](./CODE_FLOW.md)** - Detailed system flows and data pipelines

**Related Documents:**
- **[PLANNING.md](./PLANNING.md)** - Architecture decisions and rationale
- **[TASK.md](./TASK.md)** - Implementation progress and todos
- **[CLAUDE.md](./CLAUDE.md)** - Development guidelines
 - **[docs/architecture/Theming.md](./docs/architecture/Theming.md)** - Theming system guide

**This document is the QUICK REFERENCE for:**
- Finding any module/service in the codebase
- Understanding what each component does
- One-liner descriptions for rapid lookup

---

## Core Systems (Phase 1 - Implemented)

### main.dart
- Application entry point that initializes Firebase, sets up Riverpod, and launches app with splash screen

### MyApp (main.dart)
- Root widget that configures MaterialApp with theme switching and Go Router navigation

### SplashScreen (presentation/screens/splash_screen.dart) (2025-10-29)
- Layered zen animations: animated gradient + parallax blobs + sparse particles (ZenBackground), breathing glow behind logo (BreathingGlow), subtle title shimmer, staggered CTA reveal.
- Reveals CTAs after ~2s brand moment. No auto-navigation; user must tap to proceed.

### MainScaffold (presentation/screens/main_scaffold.dart)
- Bottom navigation wrapper using IndexedStack to preserve state across 4 tabs

### ProviderScope (main.dart)
- Riverpod's root widget enabling state management throughout entire application

---

## Configuration & Environment

### EnvConfig (core/environment.dart)
- Environment configuration controlling emulator usage, feature flags, and development/production modes

### AppTheme (core/theme.dart)
- Defines Material3 light and dark themes with Deep Crimson color palette (#810000) and system fonts (no Google Fonts)

### Constants (core/constants.dart)
- Central location for app-wide constants including network settings, UI dimensions, and cache keys

---

## Navigation & Routing (Phase 1.5 - Updated 2025-10-20)

### AppRouter (presentation/app_router.dart)
- GoRouter configuration with routes: `/splash`, `/`, `/meditation-detail/:id`, `/player/:id`
- Custom page transitions: slide+fade for standard pages, fade-only for player
- Secondary fade animation: Fast exit (0-30% of transition) for background screens during Hero card animations

### MeditationDetailScreen (presentation/screens/meditation_detail_screen.dart) (2025-11-13)
- Intermediary screen with compact horizontal card (96x96 thumbnail, title/desc/chips) and Play CTA
- Shows styled "Comments coming soon" placeholder block with divider (Phase 1 design validation)
- Consumes `meditationByIdProvider(id)` and `categoryMapProvider` for real-time Firestore data
- Loading/error/unavailable states with themed placeholders

### Mood System (2025-11-20)
- `lib/domain/mood.dart`: Mood model (id, name, tagline, description, icon, categoryIds, tags)
- `lib/config/moods.dart`: MVP hardcoded moods (Calm, Focus, Sleep) + card constants + mood tags for future filtering/UI
- `lib/presentation/widgets/mood_carousel_3d.dart`: 3D fan deck carousel (Stack-based, 3-card)
- `lib/presentation/screens/mood_detail_screen.dart`: Decorative gradient header, actions, recommended meditations using compact cards
- `lib/services/meditation_service.dart`: `streamByCategoryIds(List<String> ids, {int limit})` for multi-category filtering
- Home insertion: Recently Added → Mood Carousel → Trending → Recommended
- Routing: `/mood/:moodId` added in `presentation/app_router.dart`

### MeditationCompactCard (2025-11-20)
- `lib/presentation/widgets/meditation_compact_card.dart`: Shared compact meditation card for horizontal belts (thumbnail, title, duration, premium badge)
- Used by `MeditationDetailScreen` related section and `MoodDetailScreen` recommended strip for consistent visuals

### Mood Carousel Rewrite (2025-11-18)
- Replaced `PageView` with Stack of 3 visible cards (+1 hidden) for precise control
- Discrete swipe controller:
  - Distance threshold: 40px; velocity threshold: 250 px/s
  - Side taps promote to center; center tap navigates to mood detail
- Transforms: ±140px X, -100 Z, rotateY ±0.35, scale 0.8 (sides), center scale 1.0
- Performance: Only 3-4 widgets rendered; `RepaintBoundary` per card; no shadows

### CompactMeditationCard (presentation/widgets/compact_meditation_card.dart) (2025-11-13)
- Horizontal layout card with 96x96 Hero thumbnail, metadata chips (duration, category), and circular Play button
- Premium badge if isPremium=true; styled chips with theme colors
- Tap Play → invokes onPlay callback (navigates to `/player/:id`)

### Page Transitions (2025-10-20)
- Standard transition: Right-to-left slide with fade-in/out (600ms)
- Player transition: Fade-only with delayed content appearance (750ms)
- Hero animation support: Background fades quickly to prevent card ghosting
- Backdrop scrim on player: 50% opacity black overlay for depth

### MainScaffold Bottom Navigation
- 4 tabs (Home, Discover, Progress, Profile) using IndexedStack for state preservation

### Splash to Main Navigation (2025-10-28)
- No auto-navigation. Splash pauses ~2s then shows CTA buttons.
- Buttons: "Continue/Continue as Guest" (anonymous auth) and "Sign In" (email/password).
- For full flow details, see CODE_FLOW.md §4-5.

#### Admin Navigation from Settings (2025-10-21)
- Profile → Settings list shows an **Admin Panel** item
- TEMP: Always visible until authentication is integrated; will revert to `authProvider.isAdmin` gate
- Tap navigates with `context.go('/admin')` (app_router guard remains in place)
- Non-admin users do not see this item

---

## Authentication System (Phase 1.5 - Updated 2025-10-28)

### AuthProvider (providers/auth_provider.dart)
- Explicit states: `initial`, `guest`, `authenticated`, `error`
- Methods: `checkAuthState()`, `signInAnonymously()`, `signInWithEmail()`, `signOut()`
- No automatic authentication; constructor only checks existing Firebase user
- Admin claim read via `getIdTokenResult(true)` when authenticated
- Checks `token.claims?["admin"] == true` for admin access verification
- Initialization deferred via `Future(() => _init())` to avoid provider mutation during widget build (2025-10-23)

### AuthService (services/auth_service.dart)
- Firebase Authentication wrapper with `signInAnonymously`, `signOut`, `currentUser`, `authStateChanges`
- Creates/updates `users/{uid}` document on sign-in (2025-11-07)

### Admin Claims System (2025-10-22)
- Custom claims set in Firebase Console determine admin access
- Claims format: `{"admin": true}` in user's Custom Claims field
- User must sign out and re-authenticate for claims to take effect
- Verified automatically on auth state changes and token refresh

### Guest Mode Handler (2025-10-28)
- Anonymous authentication for guest users; providers read `uid` only after auth ready.
- Splash CTA initiates guest sign-in; router guards ensure tabs require a user.
- See CODE_FLOW.md §10-11 for sequence diagrams and guard rules.

### Session Manager
- Handles token refresh, session persistence, and automatic re-authentication on app launch

---

## User Management (Phase 1 - Implemented)

### DummyData.userProfile (data/datasources/dummy_data.dart)
- Mock user profile data (name, email, stats, premium status) for UI development

### ProfileScreen (presentation/screens/profile_screen.dart)
- User stats cards (sessions, time, streak), premium upgrade banner, settings list, dark mode toggle, sign out button
- TEMP (2025-10-21): Admin users and non-admins both see an **Admin Panel** row for now; re-gate after login system is active

#### Manage Subscription (2025-11-07)
- Profile → Settings shows "Manage Subscription" only when `subscriptionProvider.isPremium == true`.
- Tap opens platform account subscriptions via `_launchUrl`:
  - iOS: `https://apps.apple.com/account/subscriptions`
  - Android: `https://play.google.com/store/account/subscriptions`

### ThemeModeProvider (providers/theme_provider.dart)
- Riverpod state for theme mode (light/dark) with toggle functionality

---

## Meditation Content (Phase 1 - Implemented)

// Section B (2025-10-28): Real data integration
### MeditationService (services/meditation_service.dart)
- Firestore streams for meditations with server-side filters: trending/recent/recommended
- Personalized recommendations: `streamRecommendedForUser(uid)`
  - Uses recent completed sessions to find top 2 categories
  - Returns 6 items (4 from top category, 2 from second)
  - In-memory cache for meditationId → categoryId to minimize repeated doc reads
- Pagination helpers (`fetchPublishedPage`) for scalable lists
- Used by Riverpod providers in `providers/meditations_list_provider.dart`

### CategoryService (services/category_service.dart)
- Firestore stream of active categories ordered by `order`; Discover uses live data

### MeditationCard (presentation/widgets/meditation_card.dart) (2025-11-07)
- Reusable widget displaying meditation with gradient background, premium badge, duration, play button
- Props: `compact` (dense layout for belts), `category` (optional chip)
- Handles premium lock overlay and paywall-gated tap centrally

### Thumbnail Overlay (2025-10-28)

- Introduced `AppTheme.thumbnailBottomFadeOpacity` to avoid magic numbers.
- Home lists and `MeditationCard` now use a bottom-only fade (transparent → themed color at configured opacity) to keep text legible without dulling images.
- Files: `core/theme.dart`, `presentation/screens/home_screen.dart`, `presentation/widgets/meditation_card.dart`.

### MeditationCard Overlay & Clipping + Compact Centering (2025-11-18)

- Switched from `BoxDecoration.image` to an explicit `Image` inside the card's `Stack`; apply the bottom fade as a `Positioned.fill` gradient so tint covers only the image layer.
- Wrapped the image+gradient stack with `ClipRRect(borderRadius: BorderRadius.circular(20))` to guarantee rounded-corner clipping and eliminate bottom-corner bleed; removed `foregroundDecoration`.
- For `compact: true` belts, set the card container `margin` to `EdgeInsets.zero` (retain `EdgeInsets.only(bottom: 16)` for non‑compact) to center 140dp cards within 160dp belts.
- Fixed `MainAxisAlignment.space_between` → `MainAxisAlignment.spaceBetween`.
- Touched: `lib/presentation/widgets/meditation_card.dart`.

### HomeScreen (presentation/screens/home_screen.dart) (2025-11-07)
- Search bar, "Suggested for you" meditation cards (3)
- Trending and Recommended now reuse `MeditationCard(compact: true)` with premium tag/lock and gated tap for consistency

### DiscoverScreen (presentation/screens/discover_screen.dart)
- Search bar with filter button, 2-column category grid with gradient backgrounds and icons

---

## Admin CMS - Section D (2025-10-22)

### MeditationsListScreen (presentation/screens/admin/meditations_list_screen.dart)
- Admin table of meditations with filters (status/category/difficulty/premium), search (title contains, client-side),
  multi-select, and bulk actions (publish/unpublish/delete). Real-time via Firestore snapshots.

### Meditations List Providers (providers/meditations_list_provider.dart)
- `MeditationsQuery` state (NotifierProvider)
- `meditationsStreamProvider` wrapping `MeditationService.streamMeditations(status)` with client-side filters
- Selection Notifier + Actions (bulk publish/unpublish/delete)

### MeditationService (services/meditation_service.dart)
### MeditationEditorProvider (providers/meditation_editor_provider.dart) (2025-10-23)
- NotifierProvider holding editor form state
- Exposes: `load(id)`, setters, `saveDraft()`, `publish()`, `delete()`
- Designed to avoid lifecycle mutations; screen triggers `load(id)` post-frame

### MeditationEditorScreen (presentation/screens/admin/meditation_editor_screen.dart) (2025-10-23)
- Uses `ref.watch(meditationEditorProvider)`
- Defers initial `load(id)` with `addPostFrameCallback`
- Binds inputs to provider setters; shows saving/progress states
- `streamMeditations({status})` real-time list (ordered by createdAt desc)
- `bulkPublish`, `bulkUnpublish`, `bulkDelete` via WriteBatch + audit log

### Firestore Rules Update (2025-10-22)
- Admins can read any `meditations/{id}` (draft or published). Public read only if `status == 'published'`.


## Audio Playback

### AudioService (services/audio_service.dart)
- just_audio wrapper managing audio player instance, streaming, and playback controls
- Progressive audio caching: instant playback from disk (cache HIT) or stream + background download (cache MISS)
- Exposes bufferedPositionStream for loading UI with 30-second initial buffer
- Configures audio_session as music; handles interruptions (duck/pause) and becoming noisy (auto-pause)
- Sets AndroidAudioAttributes (usage=media, contentType=music) for proper focus

### AudioPlayerProvider (providers/audio_player_provider.dart)
- State management for playback including position, duration, and playing status; exposes play/pause/seek/stop
- Lifecycle-safe: `_isMounted` flag guards state updates, disposal sets flag FIRST then cancels subscriptions
- Exposes bufferedPositionStream for loading UI (2025-11-14)

### PlayerScreen (presentation/screens/player_screen.dart) (2025-11-15)
- UI-only player; receives meditationId from route, shows cover/title/subtitle, play/pause toggle, disabled slider
- Metadata row: category chip, loop toggle, sleep timer with live countdown when active
- Sleep timer: live countdown updates every second, shows remaining time (e.g., "🌙 2:51") instead of static icon
- Sleep timer dialog: 6 duration options (Off, 5, 10, 15, 30, 60min), repeat toggle auto-enables/disables with timer selection

### BackgroundAudioHandler
- Enables audio playback to continue when app is backgrounded or screen is locked

### MediaNotificationService
- Shows playback controls in system notification and lock screen

### Audio Progress Tracking Update (2025-11-16)
- Loop-accurate, idempotent tracking using base + position:
  - Minute upserts write `durationSec = max(lastWritten, accumulatedBase + position)` (never decreases).
  - Baseline persisted per `uid+meditationId`: `{startedAtUtc, accumulatedSeconds, lastWrittenDuration}`.
- Finalization rules (single point):
  - Finalize only on explicit stop/exit or non-loop completion; not on background.
  - At finalize, `completed = true` iff totalListened >= 90% of single track duration (prevents session spam).
  - `playCount` increments only on finalize (via `ProgressService.upsertSession` when `completed=true`).
- Public handler hooks:
  - `onLoopRestart()` — increment base by single track duration at loop rollover.
  - `finalizeSession()` — write final totals and set completed flag once.

---

## Progress Tracking (Phase 1 - Implemented)

### DummyData.progressData (data/datasources/dummy_data.dart)
- Mock progress data with daily/weekly/monthly stats, sessions, streaks, achievements

### ProgressScreen (presentation/screens/progress_screen.dart)
- Day/Week/Month tabs with TabController, circular progress indicator, bar charts for weekly data, stat cards, achievement badges

---

## Progress Tracking (Phase 3C - 2025-11-05)

- ProgressService (`lib/services/progress_service.dart`)
  - `writeSession()`: Foreground session write with SharedPreferences fallback
  - `upsertSession()`: Merge-based upsert for minute-by-minute updates (duration increments, completion flag); batches playCount increment only when completed=true
  - `tryWriteSession()`: Firestore-only write for audio thread (no plugins)
  - `flushPending()`: Foreground retry for SharedPreferences queue (not used in audio callbacks)
  - `streamRecentSessions()`: Queries last 60 days, orders by `completedAt` DESC (includes incomplete sessions; `completedAt` set on all upserts)
  - `calculateStreak()`: UTC day boundaries, counts any day with recorded activity (completed or not). Current resets only if latest activity is neither today nor yesterday.

- Achievements (2025-11-10)
  - `AppUser` includes `achievements: Map<String, DateTime>` (entity)
  - `AppUserModel` serializes `achievements` to Firestore as `Map<String, Timestamp>`
  - `AuthService` creates users with an empty `achievements` map
  - `progressDtoProvider` computes thresholds and writes missing keys:
    - Streaks: `streak_5`, `streak_10`, `streak_30`
    - Sessions: `sessions_5`, `sessions_25`, `sessions_50`
    - Minutes: `minutes_50`, `minutes_100`, `minutes_300`
  - `ProgressScreen` renders badges dynamically from provider-emitted achievements

- progressDtoProvider (`lib/providers/progress_provider.dart`)
  - Aggregates sessions from last 60 days
  - Emits map matching `ProgressScreen` expectations:
    - `daily: { percentage, minutesCompleted (rounded UP), goalMinutes, sessions[] (with denormalized titles) }`
    - `weekly: { data[7] (rounded UP), streak (from completed only), currentMinutes (rounded UP) }`
    - `monthly: { streak (longest from completed), currentMinutes (rounded UP) }`
  - Rounding: `(totalSeconds + 59) ~/ 60` for all minute displays

- Audio integration (`lib/services/audio_service.dart`)
  - Start timestamp: Captured on first transition to playing (playerStateStream) - handles auto-play and manual play
  - Minute upserts: Every 60 seconds, updates same sessionId with current listened duration (merge)
  - Completion: At ≥90% threshold or natural end → marks completed=true, sets duration to full track length, increments playCount
  - Thread safety: All writes use Firestore-only methods (no SharedPreferences in audio callbacks)
  - Deterministic `sessionId = uid_meditationId_startedAtMsUtc`

## Offline Support (Section F - 2025-11-05)
- Firestore persistence configured in `main.dart` (mobile explicit, web via `enablePersistence`)
- `ProgressService.start()` listens to connectivity changes and calls `flushPending()` on reconnect
- `progressServiceProvider` starts the service and disposes it to prevent leaks
- Dependency added: `connectivity_plus`
 - API note: `connectivity_plus` v6 emits `List<ConnectivityResult>`; listener handles multi-connection
 - UI: `isOfflineProvider` + `OfflineBanner` persistently indicate offline mode at the top of the app

## Home Dashboard

### HomeScreen (presentation/screens/home_screen.dart)
- Main dashboard showing quick stats, recent meditations, and recommended content

### QuickStartCard (widgets/quick_start_card.dart)
- Featured meditation for immediate playback from home screen

### DailyQuote (widgets/daily_quote.dart)
- Inspirational quote widget that updates daily

### StreakWidget (widgets/streak_widget.dart)
- Visual display of current streak with motivational messages

---

## Category System (2025-10-21)

### CategoryProvider (providers/category_provider.dart)
- Manages meditation categories stream and admin actions (create/rename/archive/reorder)

### CategoryService (services/category_service.dart)
- Firestore operations for category data. Reorder writes incremental `order` values (gaps of 10).

### CategoriesScreen - Admin (presentation/screens/admin/categories_screen.dart)
- CustomScrollView + SliverReorderableList for smooth drag/drop
- Explicit drag handle (click-and-drag on web/mouse)
- Optimistic local list during drag/save; delayed clear post-frame after stream match
- Drag proxy styled via Material (card color, rounded corners, elevation)
- Stabilized subtitle using AnimatedSwitcher; shows computed position during reorder to avoid jumps

### CategoryChip (widgets/category_chip.dart)
- Selectable chip widget for category filtering in discovery

---

## Premium Features

### Premium Subscriptions (2025-11-07)
- SubscriptionService (`lib/services/subscription_service.dart`)
  - In-app purchase integration (monthly SKU) with lifecycle `init/start/dispose`
  - Listens to purchase stream and grants entitlement via ProgressService (sets `users/{uid}.isPremium = true`)
  - Queries product pricing from store using `SubscriptionConfig`
- SubscriptionProvider (`lib/providers/subscription_provider.dart`)
  - Riverpod Notifier managing `isPremium`, `priceText`, `storeAvailable`, `error`, `isLoading`
  - Observes `users/{uid}` doc to react to entitlement changes
- SubscriptionConfig (`lib/config/subscription_config.dart`)
  - Central product IDs and display fallbacks (`monthlyProductId = 'premium_monthly'`)
- PaywallScreen (`lib/presentation/screens/paywall_screen.dart`)
  - Themed purchase UI with benefits list, Subscribe and Restore buttons
  - Route: `/paywall` (see `presentation/app_router.dart`)

#### IAP Kill Switch (2025-11-07)
- Config: `SubscriptionConfig.enableIAP`
  - `false` (default in dev): skips store initialization and purchase queries; paywall shows fallback price; gates still work
  - `true` (prod testing): enables App Store/Play Billing flows
  - Location: `lib/config/subscription_config.dart`

---

## Data Persistence

### FirestoreService (services/firestore_service.dart)
- Base service for all Firestore operations with error handling and offline support

### LocalStorageService (services/local_storage_service.dart)
- SharedPreferences wrapper for caching user data and preferences locally

### SyncService (services/sync_service.dart)
- Manages data synchronization between local storage and cloud

### MigrationService (services/migration_service.dart)
- Handles database schema migrations and data structure updates

---

## File Upload System (Phase 2 - Added 2025-10-22)

### UploadService (services/upload_service.dart)
- Firebase Storage wrapper for image and audio uploads with progress tracking
- Handles content type detection and file metadata
- Extracts audio duration using just_audio player for uploaded meditation files
- Returns download URLs after successful upload

### Storage Configuration (2025-10-22)
- Uses modern Firebase Storage bucket: `meditation-by-vk-89927.firebasestorage.app`
- CORS configured for localhost development via Google Cloud SDK (gsutil)
- Allows uploads from `http://localhost:*` with GET/POST/PUT/DELETE/HEAD methods

---

## Models & Serialization

### UserModel (models/user_model.dart)
- User profile data structure with JSON serialization methods

### MeditationModel (models/meditation_model.dart)
- Meditation content data structure with Firestore conversion

### SessionModel (models/session_model.dart)
- Meditation session record with completion tracking

### CategoryModel (models/category_model.dart)
- Category metadata with icon and color information

---

## UI Components

### LoadingWidget (widgets/loading_widget.dart)
- Consistent loading indicator used throughout the app

### ErrorWidget (widgets/error_widget.dart)
- Standard error display with retry functionality

### EmptyStateWidget (widgets/empty_state.widget.dart)
- Placeholder shown when lists are empty with helpful actions

### CustomAppBar (widgets/custom_app_bar.dart)
- Reusable app bar with consistent styling and actions

---
### ZenBackground (presentation/widgets/zen_background.dart) (2025-10-29)
- Animated gradient backdrop with subtle parallax blobs and sparse drifting particles. Tuned for calm motion and low CPU.

### BreathingGlow (presentation/widgets/breathing_glow.dart) (2025-10-29)
- Soft radial glow that gently pulses behind the logo. Size/color configurable.

### SplashAnimationConfig (core/animation_constants.dart) (2025-10-29)
- Centralized splash timings (gradientCycle, parallaxPeriod, particleDriftPeriod, glowPulse, shimmerSweep, ctaReveal, ctaStagger, ctaItemDuration) and counts/sizes.

## Utilities

### DateFormatter (utils/date_formatter.dart)
- Formats dates and durations for display throughout the app

### Validators (utils/validators.dart)
- Input validation for forms including email and password rules

### Logger (utils/logger.dart)
- Centralized logging with different levels for debug/production

### NetworkManager (utils/network_manager.dart)
- Monitors connectivity and handles offline scenarios

---

## Settings & Preferences

### SettingsProvider (providers/settings_provider.dart)
- Manages app settings including theme, notifications, and audio preferences

### SettingsScreen (presentation/screens/settings_screen.dart)
- User interface for app configuration and preferences

### ThemeManager
- Handles theme switching between light, dark, and system modes

### NotificationSettings
- Configure reminder times and notification preferences

---

## Onboarding

### OnboardingScreen (presentation/screens/onboarding_screen.dart)
- First-time user experience with app introduction and setup

### OnboardingProvider (providers/onboarding_provider.dart)
- Tracks onboarding progress and completion status

### WelcomeSlides (widgets/welcome_slides.dart)
- Swipeable introduction slides explaining app features

---

## Search & Discovery

### SearchProvider (providers/search_provider.dart)
- Manages search queries and filters for content discovery

### SearchBar (widgets/search_bar.dart)
- Reusable search input with debouncing and suggestions

### FilterSheet (widgets/filter_sheet.dart)
- Bottom sheet for applying advanced filters to content

### RecommendationEngine
- Suggests meditations based on user history and preferences

---

## Social Features (Future)

### CommunityProvider
- Manages social interactions and user connections (planned)

### FriendsService
- Friend system for sharing progress and challenges (planned)

### GroupMeditationService
- Synchronized group meditation sessions (planned)

---

## Analytics & Monitoring

### AnalyticsService (services/analytics_service.dart)
- Firebase Analytics wrapper for tracking user events

### CrashlyticsService (services/crashlytics_service.dart)
- Error reporting and crash analytics for production

### PerformanceMonitor
- Tracks app performance metrics and identifies bottlenecks

---

## Background Services

### BackgroundFetchService
- Periodic background tasks for data sync and notifications

### DownloadManager (Phase 3)
- Manages offline meditation downloads and storage

### NotificationScheduler
- Schedules local notifications for reminders and streaks

---

## Admin Features (Future)

### AdminPanel (Web)
- Web interface for content management and user administration

### ContentUploader
- Tool for adding new meditations and managing metadata

### AnalyticsDashboard
- Admin view of app usage statistics and trends

---

## Testing & Debug

### DebugPanel (debug/debug_panel.dart)
- Developer tools for testing features and viewing logs

### MockDataGenerator
- Creates test data for development and testing

### FeatureFlagManager
- Controls feature rollout and A/B testing

---

## Platform-Specific

### IOSAudioSession
- iOS-specific audio session configuration for background playback

### AndroidForegroundService
- Android service for maintaining audio playback

### WebAudioAdapter
- Web platform audio handling (if web support added)

---

## State Management Helpers

### AsyncValueWidget
- Helper widget for handling loading/error/data states

### RefreshIndicatorWrapper
- Consistent pull-to-refresh implementation

### PaginationController
- Manages infinite scroll and pagination state

---

## Animations & Transitions

### PageTransitions (2025-10-20)
- Custom page transition system in app_router.dart with two strategies:
  - Standard: Slide (right-to-left) + fade for general navigation
  - Player: Fade-only to complement Hero card expansion animation
- Fast background exit: Secondary fade animation (Interval 0.0-0.3) removes home screen cards quickly during player transition
- Delayed player content: Interval 0.3-1.0 fade prevents content appearing before Hero animation completes

### AnimatedProgressBar
- Smooth progress indicators for playback

### BreathingAnimation
- Visual breathing guide for meditation exercises

---

## Caching Strategy

### ImageCacheManager
- Manages meditation cover image caching

### AudioCacheManager (Phase 3)
- Handles offline audio file storage

### DataCacheManager
- Caches frequently accessed Firestore documents

---

## Error Handling

### ErrorBoundary
- Catches and displays errors gracefully

### RetryLogic
- Automatic retry for failed network requests

### FallbackHandlers
- Provides offline functionality when network unavailable

---

## Localization (Future)

### LocalizationService
- Multi-language support system (planned)

### TranslationProvider
- Manages active language and translations (planned)

### LanguageSelector
- UI for choosing app language (planned)

---

## Quick Reference

### Key Flows

**App Launch:**
main() → Firebase.init → ProviderScope → MyApp → HomeScreen

**Play Meditation:**
MeditationCard tap → Load audio URL → Initialize player → Start playback → Track session

**User Authentication:**
LoginScreen → FirebaseAuth.signIn → Create session → Load profile → Navigate home

**Session Tracking:**
Start meditation → Record start time → Monitor progress → Save on complete → Update stats

**Data Sync:**
Local change → Queue for sync → Network available → Upload to Firestore → Confirm sync

### Critical Services

- **AuthService** - Authentication and session management
- **AudioService** - Audio playback control
- **FirestoreService** - Database operations
- **SyncService** - Local/cloud synchronization
- **AnalyticsService** - User behavior tracking

### State Providers

- **authProvider** - Authentication state
- **userProvider** - User profile data
- **meditationProvider** - Meditation content
- **audioPlayerProvider** - Playback state
- **progressProvider** - User statistics
- **settingsProvider** - App preferences

---

## CategoryMeditationsScreen (2025-11-05)

- Route: `/category/:id` (see `presentation/app_router.dart`).
- On init: sets `meditationsQueryProvider` to filter `{ status: 'published', categoryId }`.
- Consumes `meditationsStreamProvider` for live list, client-filtered by category and search.
- Header title resolves via `categoriesStreamProvider` to display category name.
- Tapping a list item navigates to `/player/:id`.

---

## Performance Metrics

### Target Metrics
- App launch: < 2 seconds
- Screen navigation: < 300ms
- Audio start: < 1 second
- List scroll: 60 FPS
- Image load: < 500ms

### Optimization Points
- Lazy load images with placeholders
- Pagination at 20 items per page
- Cache frequently accessed data
- Debounce search inputs by 300ms
- Use const constructors for widgets

---

## Security Considerations

### Data Protection
- Encrypt sensitive local storage
- Use Firebase Security Rules
- Validate all user inputs
- Sanitize display content
- Secure API keys in environment

### Authentication Security
- Enforce strong passwords
- Implement rate limiting
- Use secure token storage
- Handle session expiry
- Log security events

---

**This document serves as a complete reference for all systems and features in the Meditation by VK application.**