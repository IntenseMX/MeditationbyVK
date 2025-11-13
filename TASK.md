Brand Colors for Bottom Nav (2025-10-23)

- Added brand constants in `AppTheme`: `brandPrimaryLight=#AC7456`, `brandNeutralLight=#D5B09C`.
- Wired light theme BottomNavigationBar to use brand constants (selected/unselected).
- Left existing `shrine*` palette intact for backward compatibility.

Pop Red ThemeExtension (2025-10-23)

- Added `AppColors` ThemeExtension to `lib/core/theme.dart` with `pop=#D00000` and `onPop=#FFFFFF`.
- Applied on splash logo box in `lib/presentation/screens/splash_screen.dart` (solid red background, white “UP”).
- Does not alter `ColorScheme`; isolated, reusable for rare pop highlights.

# TASK.md - Meditation by VK

Last Updated: 2025-11-13

## 📚 Documentation Overview

**Essential Reading (in order):**
1. **[CODE_FLOW.md](./CODE_FLOW.md)** - Complete system architecture and data flows
2. **[APP_LOGIC.md](./APP_LOGIC.md)** - Quick reference for all modules/services

**Project Context:**
- **[PLANNING.md](./PLANNING.md)** - Architecture decisions and rationale
- **[CLAUDE.md](./CLAUDE.md)** - Development rules and guidelines
- **[README.md](./README.md)** - Project overview and setup instructions

## Current Status (2025-10-25)

- ✅ **Completed**: Phase 1 - Foundation (UI Skeleton with 7 visual checkpoints)
- ✅ **Completed**: Phase 1.5 - Infrastructure (Firebase + guest auth + player route)
- ✅ **Completed**: Phase 2 - Content System (Firebase integration)

### Phase 2 Completion (2025-10-25)
- ✅ Section A: Security rules + admin guard enforced in `app_router.dart` and Firestore rules
- ✅ Section B: Meditation editor (`meditation_editor_provider.dart` + screen)
- ✅ Section C: Uploads (image/audio) with progress and duration; CORS configured
- ✅ Section D: Meditations list + bulk actions (publish/unpublish/delete)
- ✅ Section E: Real-time sync verified
  - Home reads Firestore via Riverpod streams
  - Admin publishes → mobile updates within seconds (no refresh)
  - Three sections wired: Trending (belt), Recently Added (vertical), Recommended (horizontal)
  - Player loads by Firestore ID with not-found handling
  - Images shown across all sections with gradient overlays
  - Index note: status filter moved client-side to avoid composite index prompt (can re-enable server filter after index creation)

### Meditation Detail Screen - Phase 1 (2025-11-13) ✅ COMPLETE
- [x] Added route `/meditation-detail/:id` in `presentation/app_router.dart` (line 297)
- [x] Implemented `MeditationDetailScreen` (~150 lines) with compact horizontal card, Play CTA, and themed "Comments coming soon" block
- [x] Added `CompactMeditationCard` widget (~170 lines) with 96x96 Hero thumbnail, duration/category chips, circular Play button
- [x] Updated Home taps to navigate to detail screen (home_screen.dart lines 192, 334)
- [x] Updated CODE_FLOW.md with screen flow details (navigation, data providers, theme compliance)
- [x] Updated APP_LOGIC.md with MeditationDetailScreen and CompactMeditationCard descriptions
- Implementation:
  - Theme-aware colors only (no hardcoded colors)
  - Loading/error/unavailable states handled
  - Real-time Firestore data via Riverpod (`meditationByIdProvider`, `categoryMapProvider`)
  - Play button navigates to existing `/player/:id` route
- Notes: Comments UI placeholder added for Phase 1 design validation. Player screen remains unchanged.

UX/Infra improvements (2025-10-25)
- Extracted reusable bottom navigation `MainNavBar`; added routes `/discover`, `/progress`, `/profile`
- Attached bottom nav to Admin Dashboard for quick app navigation
- Editor reset on `/meditations/new` to always start fresh
- File picker buttons enabled outside of required-fields gate; validation remains on Save/Publish
 - Admin Login UX: Added top-left back button and "Return to Home" button under login (see `lib/presentation/screens/login_screen.dart`).

### Splash Screen Enhancements (2025-10-29)
- [x] Slow CTA fade to 3× (1.35s) via `AnimationDurations.ctaReveal`
- [x] Add `ZenBackground` with animated gradient, parallax blobs, and sparse particles
- [x] Add `BreathingGlow` behind logo
- [x] Add subtle title shimmer using `ShaderMask`
- [x] Stagger CTA buttons with opacity+slide
- Files: `presentation/screens/splash_screen.dart`, `presentation/widgets/zen_background.dart`, `presentation/widgets/breathing_glow.dart`, `core/animation_constants.dart`

### Security & Guard Update (2025-10-21)
- Admin route guard expanded to protect `/admin/*`, `/meditations*`, and `/categories*` routes.
- Rationale: Ensure admin UIs are inaccessible to non-admin users even when routes are outside `/admin` prefix.

### Meditation Editor MVP (2025-10-21)
- Added `MeditationService` (create/update/publish/delete/get + audit logging)
- Added `meditation_editor_provider.dart` (form state + actions)
- Implemented `MeditationEditorScreen` (draft/publish/delete, basic form)
- Added routes: `/meditations/new`, `/meditations/:id`
- Dependency: `just_audio` added (duration detection will be wired in uploads section)

### Uploads Integration (2025-10-21)
### Section D: Meditations List + Bulk Actions (2025-10-22) ✅
- [x] Add `MeditationListItem` and list stream in `MeditationService`
- [x] Implement `bulkPublish`, `bulkUnpublish`, `bulkDelete` (WriteBatch + audit)
- [x] Create `meditations_list_provider.dart` (query state, stream, selection, actions)
- [x] Build `MeditationsListScreen` (filters, search client-side, multi-select, bottom action bar)
- [x] Add back button in AppBar to `/admin`
- [x] Firestore Rules: allow admin read of all meditations (draft + published)

Index Strategy (2025-10-22):
- Server filter: `status` only
- Client-side: `search` (title contains), `categoryId`, `difficulty`, `isPremium`
- Future: add composite indexes if moving filters server-side

- Added `UploadService` for image/audio uploads with progress and audio duration
- Added `FilePickerField` widget and integrated into Meditation Editor
- Added `file_picker` dependency and wired onPick handlers (image/audio)

### Resolved (2025-10-23): Provider mutation during build in Editor/Auth
- Issue: Navigating to `/meditations/:id` caused "Tried to modify a provider while the widget tree was building"
- Root Cause: Editor `initState()` invoked provider mutation; Auth provider mutated state during `build()`
- Fixes:
  - Editor: Converted to `NotifierProvider` and deferred `load(id)` via `addPostFrameCallback` in screen
  - Auth: Deferred `_init()` with `Future(() => _init())` to avoid build-time writes
- Impact: Stable navigation to editor; no lifecycle violations; aligns with Riverpod v3 APIs

## Local Testing Setup (2025-10-18)

**Firebase Emulator Suite** - Test locally before production deployment:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Initialize emulators: `firebase init emulators` (select Auth, Firestore, Storage)
3. Start emulators: `firebase emulators:start`
4. Configure app to switch between local emulator and production Firebase using environment flags
5. Test all features locally with zero cloud costs

---

### Phase 3 - Section C: Progress Tracking (2025-11-05) ✅ COMPLETE

- [x] Define sessions path `userProgress/{uid}/sessions/{sessionId}` and rules
- [x] Implement `ProgressService` (writeSession, upsertSession merge API, tryWriteSession for audio thread, streak calc UTC)
- [x] Increment `meditations/{id}.playCount` on completion (atomic batch)
- [x] Add `progressDtoProvider` emitting daily/weekly/monthly map for UI
- [x] Wire `ProgressScreen` to provider (replaced dummy data)
- [x] Start timestamp capture on first playing transition (playerStateStream)
- [x] Minute-by-minute upserts every 60 seconds (merge updates)
- [x] 90% completion threshold → full credit (duration = full track)
- [x] Thread safety: Firestore-only writes in audio callbacks (no SharedPreferences)
- [x] Round-up minutes in UI (`(seconds + 59) ~/ 60`)
- [x] Initialize `playCount=0` on meditation create
- [x] Sessions composite index verified (completed ASC, completedAt DESC)
- [ ] Enrich daily sessions list with titles (denormalized fetch)
- [ ] Add extended tests (offline replay, threshold, multi-device)

**Testing Notes:**
- Minutes increase each minute during playback
- Exit early shows minutes counted, but streak only increments if completed
- ≥90% completion marks session as completed and increments playCount
- Streaks computed only from completed sessions (UTC day boundaries)

### Achievements (2025-11-10) ✅ COMPLETE
- [x] Add `achievements` map to `AppUser` entity
- [x] Serialize `achievements` in `AppUserModel` (Firestore map<string, timestamp>)
- [x] Initialize empty `achievements` on new user creation (`AuthService`)
- [x] Auto-award achievements in `progressDtoProvider`:
  - Streak: `streak_5`, `streak_10`, `streak_30`
  - Sessions: `sessions_5`, `sessions_25`, `sessions_50`
  - Minutes: `minutes_50`, `minutes_100`, `minutes_300`
- [x] Display unlocked badges on `ProgressScreen` using real data

### Performance & UX Improvements (2025-11-10) ✅ COMPLETE
- [x] Splash CTAs gated until intro animation completes AND data-ready; add 4s “Skip (loading in background)” fallback
- [x] Remove offscreen Home warmup overlay and delete dead warmup constants
- [x] Add shimmer skeletons for Home sections (Recently Added, Trending, Recommended)
- [x] Virtualize Trending belt (modulo access); remove per-build 100× list allocation
- [x] Throttle auto-scroll with timer (~32ms), pause on user interaction
- [x] Use `CachedNetworkImageProvider(maxWidth: …)` in `MeditationCard` for downscaled decode/cache
- [x] Debug perf metrics hook (avg/p95/jank) via `addTimingsCallback` in `main.dart` (profile for authoritative)

## Phase 1: Foundation (Core Setup) ✅ COMPLETE

**🎯 Deliverable:** Working skeleton app with all UI screens and navigation

**Completion Date:** 2025-10-18

### Tasks Completed
- [x] Create Flutter project (iOS + Android + Web)
- [x] Set up folder structure
  - [x] lib/data/ (datasources with dummy data)
  - [x] lib/presentation/ (screens, widgets)
  - [x] lib/core/ (theme, constants)
  - [x] lib/providers/ (Riverpod state management)
- [x] Firebase basic setup
  - [x] Create Firebase project
  - [x] Configure firebase_core
  - [x] Basic initialization (emulator disabled for now)
- [x] Configure pubspec.yaml dependencies
  - [x] firebase_core
  - [x] flutter_riverpod
  - [x] go_router (routing configured)
- [x] Create theme.dart with light/dark variants
  - [x] Deep Crimson color palette (matching reference designs)
  - [x] All colors in ColorScheme
  - [x] Component themes (buttons, cards, navigation)
  - [x] Dark mode toggle functional
- [x] Build bottom navigation (4 tabs)
  - [x] Home - meditation cards, trending section
  - [x] Discover - category grid with search
  - [x] Progress - day/week/month stats with charts
  - [x] Profile - user stats, settings, dark mode
- [x] Add dummy meditation data (DummyData class)
- [x] Create meditation list UI with cards
- [x] Build splash screen with CLARITY logo animation

### Visual Checkpoints Delivered
1. ✅ Splash screen - Animated logo with gradient
2. ✅ Theme system - Deep Crimson (#810000) palette
3. ✅ Bottom navigation - IndexedStack with state preservation
4. ✅ Home screen - Search, meditation cards, trending horizontal scroll
5. ✅ Discover screen - 2-column category grid with gradients
6. ✅ Progress screen - Circular progress, bar charts, achievement badges
7. ✅ Settings/Profile - Stats cards, premium banner, settings list

### Technical Notes
- All screens use dummy data from `lib/data/datasources/dummy_data.dart`
- Theme uses constants (no magic numbers) per CLAUDE.md rules
- Fixed infinite width constraint on TextButton
- Replaced `Colors.white.withOpacity()` with theme-aware colors
- App runs clean on Chrome/Web (tested), ready for mobile testing

Theme Cleanup (2025-10-28)

- Replaced 30+ hardcoded `Colors.white` usages across gradient cards, discover, home, progress, particles, and breathing widgets with theme-driven colors.
- Extended `AppColors` ThemeExtension: added `textOnGradient`, `statusSuccess`, `statusWarning`.
- Admin status icons now use theme (`statusSuccess/statusWarning`) instead of green/orange literals.
- Verified zero remaining `Colors.white` usages in `lib/` besides centralized constant in `AppTheme`.

Theme Presets & Picker (2025-10-28)

- Added 12 theme presets mapped to luxury palettes: see `lib/config/theme_presets.dart`.
- New Themes screen (`/themes`) with preview grid and Apply.
- Persist selected theme using `shared_preferences`; applied app-wide via providers.
- `main.dart` now reads selected preset and builds ThemeData dynamically.

Theme Tinting & Color Migration (2025-11-03)

- Implemented background/surface tinting via `Color.alphaBlend()` in theme preset builder.
- Mobile-first tinting constants: `kLightBackgroundTint=0.50`, `kDarkBackgroundTint=0.32`, `kLightSurfaceTint=0.35`, `kDarkSurfaceTint=0.10`, `kSurfaceVariantOpacity=0.18`.
- Migrated all hardcoded colors to `Theme.of(context).colorScheme` across home, progress, profile, discover screens.
- Removed animated gradient overlay from `MainScaffold` to ensure theme background is visible.
- Added theme mode persistence (SharedPreferences) with default `ThemeMode.light`.
- Each of 12 themes now visibly tints the entire app background for clear distinction.

### New Theme Presets (2025-11-03)
- Added three presets in `lib/config/theme_presets.dart` (total now 15):
  - `winter_wonderland` (cool blues: Frosted Mist, Powder Blue, Ice Lake, Arctic Sky)
  - `burgundy_luxe` (deep burgundy with soft gold accents)
  - `racing_green_gold` (British racing green with gold)
- Updated docs: `APP_LOGIC.md` and `docs/architecture/Theming.md`.

---

### Daily Goal (2025-11-09)

- Added `dailyGoldGoal` (int) to `users/{uid}` Firestore document (default 10).
- Updated `AppUser` entity and `AppUserModel` serialization.
- `AuthService` sets default on user creation and exposes `updateDailyGoldGoal(int)`.
- `progressDtoProvider` now reads goal from Firestore with fallback to 10.
- New dialog `GoalSettingsDialog` for editing goal; wired in `ProfileScreen` → Settings → Goals.

---

## Phase 1.5: Infrastructure ✅ COMPLETE (2025-10-19)

### Deliverables
- Firebase web configuration populated in `lib/firebase_options.dart` (web)
- Emulator toggle enabled in `lib/core/environment.dart` (`useEmulator = true`)
- Anonymous guest login auto-enabled via `lib/providers/auth_provider.dart`
- Firebase Auth wrapper created at `lib/services/auth_service.dart`
- Player route added in `lib/presentation/app_router.dart` → `/player/:id`
- Player UI screen created at `lib/presentation/screens/player_screen.dart`
- Home cards navigate to player via `context.go('/player/:id')`

### Verification
- Emulators running on: Auth 9099, Firestore 8080, Storage 9199, UI 4000
- App logs show: "Firebase initialized successfully" and "Connected to Firebase Emulators"
- Emulator UI shows an anonymous user upon app start

### Notes
- Measurement ID added but Analytics disabled in dev
- Storage bucket standardized to `*.firebasestorage.app`

---

## Phase 2: Content System (Modular CMS + Admin Panel)

**🎯 Deliverable:** No-code content management - admins can upload meditations without developer

### Admin Authentication Setup (2025-10-22) ✅
- [x] Configure custom claims for admin access
- [x] Set up admin route guards in app_router.dart
- [x] Verify admin claim checking in auth_provider.dart
- [x] Document admin setup process in FIREBASE_SETUP.md
- [x] Fix storage bucket configuration (use .firebasestorage.app)
- [x] Configure CORS for localhost uploads (Google Cloud SDK + gsutil)
- [x] Test admin login flow with custom claims
- [x] Verify file upload functionality

### Tasks
- [ ] **Database Schema Implementation**
  - [ ] Create Firestore collections (users, meditations, categories, userProgress)
  - [ ] Write Firebase Security Rules
  - [ ] Set up composite indexes
  - [ ] Test security rules in emulator
- [ ] **Admin Panel (Flutter Web or React)**
  - [ ] Project setup (separate from main app)
  - [ ] Authentication (admin-only)
  - [ ] Dashboard UI
- [ ] **Upload Interface**
  - [ ] Audio file upload to Cloud Storage
  - [ ] Cover image upload
  - [ ] Metadata form (title, description, duration, categories)
  - [ ] Premium/free toggle
  - [ ] Tags and difficulty level
- [ ] **Content Management**
  - [ ] View all meditations (table/grid)
  - [ ] Edit existing meditations
  - [ ] Delete meditations
  - [ ] Bulk operations (publish, unpublish)
- [ ] **Category Management**
  - [ ] Create/edit categories
  - [ ] Set category order
  - [ ] Upload category icons
- [ ] **Auto-Sync Pipeline**
  - [ ] Automatic thumbnail generation
  - [ ] Audio duration extraction
  - [ ] Versioning system (track changes)
  - [ ] Content preview before publishing
- [ ] **User Management (Basic)**
  - [ ] View user list
  - [ ] View user stats
  - [ ] Grant/revoke premium access

---

## Phase 3: Core Features

**🎯 Deliverable:** Functioning meditation app - works like a real meditation app

See detailed plan: [PHASE_3_CORE_FEATURES.md](./PHASE_3_CORE_FEATURES.md)

### Tasks
- [ ] **Audio Player (just_audio)**
  - [ ] Install and configure just_audio
  - [ ] Stream audio from Firebase Storage URLs
  - [ ] Play/pause controls
  - [ ] Seek bar with position
  - [ ] Skip forward/back buttons
  - [ ] Background audio support (iOS/Android)
  - [ ] Lock screen controls
  - [ ] Resume from last position
- [ ] **Real Data Integration**
  - [ ] Replace dummy data with Firestore queries
  - [ ] Pagination for meditation lists
  - [ ] Category filtering
  - [ ] Search functionality
- [ ] **Progress Tracking**
  - [ ] Track session start/completion
  - [ ] Calculate daily/weekly/monthly stats
  - [ ] Streak calculation (current + longest)
  - [ ] Total listening time
  - [ ] Completed meditation count
- [ ] **Discover Page**
  - [ ] Search bar
  - [ ] Category chips
  - [ ] Trending section (most played)
  - [ ] Recently added
  - [ ] Recommended for you
- [ ] **Home Page**
  - [ ] Daily meditation suggestion
  - [ ] Continue listening (resume)
  - [ ] Quick stats (streak, total time)
  - [ ] Category sections
- [ ] **Progress Page**
  - [ ] Weekly goal setting
  - [ ] Stats visualization (charts/graphs)
  - [ ] Session history
  - [ ] Achievements/milestones
- [ ] **Offline Caching & Download**
  - [ ] Firestore offline persistence
  - [ ] Hive setup for metadata cache
  - [ ] Download meditation for offline (premium)
  - [ ] Cache management UI
  - [ ] Background sync when online
  - [ ] Queue offline writes (progress tracking)
  - [ ] Storage limit handling

---

## Phase 4: Monetization & Accounts

**🎯 Deliverable:** Revenue-ready app - subscriptions live, ready for soft launch

### Tasks
- [ ] **Premium Content Gates**
  - [ ] Lock premium meditations for free users
  - [ ] "Upgrade to Premium" prompts
  - [ ] Preview premium content (30 seconds)
-- [ ] **Subscription Integration**
  - [x] Add `in_app_purchase` dependency (2025-11-07)
  - [x] Implement `SubscriptionService` with lifecycle and purchase stream (2025-11-07)
  - [x] Add `SubscriptionProvider` (Riverpod Notifier) (2025-11-07)
  - [x] Create `PaywallScreen` and route `/paywall` (2025-11-07)
  - [x] Sync entitlement to Firestore (`users/{uid}.isPremium`) via `ProgressService` (2025-11-07)
  - [x] Add IAP kill switch `SubscriptionConfig.enableIAP` (default false in dev) (2025-11-07)
  - [ ] Gate premium playback for non-premium users (redirect to `/paywall`)
  - [ ] Product ID config per store (update `SubscriptionConfig.monthlyProductId`)
  - [ ] Receipt verification (server-side) before granting entitlement
  - [ ] Restore purchases UX polish and platform notes
- [ ] **Profile Management**
  - [ ] Edit profile (name, photo)
  - [ ] Account settings
  - [ ] Notification preferences
  - [ ] Theme selection (light/dark/system)
  - [ ] Logout
  - [ ] Delete account
- [ ] **Subscription Management**
  - [ ] View active subscription
  - [ ] Restore purchases
  - [ ] Cancel subscription
  - [ ] Billing history
  - [x] Add "Manage Subscription" link in Profile (platform external page) — 2025-11-07
- [ ] **Push Notifications (FCM)**
  - [ ] Firebase Cloud Messaging setup
  - [ ] Request notification permission
  - [ ] Local notifications (daily reminders)
  - [ ] Server-triggered notifications
    - [ ] Streak break alerts
    - [ ] New content notifications
    - [ ] Weekly summary
  - [ ] Deep linking from notifications
  - [ ] Notification settings (types, frequency)

---

## Phase 5: Polish & Web Version

**🎯 Deliverable:** Production-ready multi-platform app - polished, marketed, ready for app stores

### Tasks
- [ ] **Visual Polish**
  - [ ] Add animations (page transitions, loading states)
  - [ ] Gradient backgrounds
  - [ ] Smooth scrolling
  - [ ] Haptic feedback
  - [ ] Dark mode refinement
- [ ] **Flutter Web Version**
  - [ ] Configure for web build
  - [ ] Responsive layouts for desktop/tablet
  - [ ] Web-specific optimizations
  - [ ] Deploy to Firebase Hosting
- [ ] **SEO Landing Page**
  - [ ] Create marketing site (Flutter Web or static)
  - [ ] Feature showcase
  - [ ] Testimonials/reviews
  - [ ] Pricing page
  - [ ] Download links (App Store, Play Store)
  - [ ] Blog/content section (optional)
  - [ ] SEO optimization (meta tags, sitemap)
- [ ] **Quality Assurance**
  - [ ] Unit tests for critical providers
  - [ ] Integration tests for user flows
  - [ ] Manual testing on multiple devices
  - [ ] iOS testing (real devices)
  - [ ] Android testing (multiple manufacturers)
  - [ ] Accessibility testing (screen readers, contrast)
- [ ] **Performance Optimization**
  - [ ] Bundle size reduction
  - [ ] Image compression
  - [ ] Code splitting
  - [ ] Lazy loading optimizations
  - [ ] Memory leak detection
- [ ] **App Store Preparation**
  - [ ] Create app screenshots
  - [ ] Write app descriptions
  - [ ] App Store listing (iOS)
  - [ ] Play Store listing (Android)
  - [ ] Privacy policy
  - [ ] Terms of service
  - [ ] App review submission
- [ ] **Deployment & Scaling**
  - [ ] Set up CI/CD pipeline (GitHub Actions)
  - [ ] Staged rollout strategy
  - [ ] Firebase budget alerts
  - [ ] Monitoring and analytics
  - [ ] Crash reporting (Firebase Crashlytics)

---

## Database Schema Enhancements (Consider for Future)

- [ ] Add `favorites` subcollection under users
- [ ] Add `tags` array to meditations (beyond categories)
- [ ] Add `lastPlayedPosition` field for resume functionality
- [ ] Consider `playlists` collection for curated sequences
- [ ] Add `downloadUrl` field for offline support
- [ ] Add `relatedMeditations` array for recommendations

---

## Performance Targets

| Metric | Target | Phase |
|--------|--------|-------|
| App launch | < 2 seconds | Phase 1 |
| Audio start | < 1 second | Phase 3 |
| Screen transitions | < 300ms | Phase 5 |
| Firebase queries | < 500ms | Phase 2 |
| Offline playback | Instant | Phase 3 |
| Download speed | 1MB/s minimum | Phase 3 |

---

## Known Issues & Resolutions

### Resolved (2025-10-25): Secret in git history
### Resolved (2025-10-28): Home thumbnails looked blurry
- Issue: Full-card gradient overlay at 45% made images appear dull/soft.
- Root Cause: Uniform foreground gradient applied across entire thumbnail for text legibility.
- Solution: Switched to bottom-only vertical fade (transparent → themed color) with configurable `AppTheme.thumbnailBottomFadeOpacity`.
- Files: `lib/core/theme.dart`, `lib/presentation/screens/home_screen.dart`, `lib/presentation/widgets/meditation_card.dart`.
- Removed `serviceAccountKey.json` from commit e0454ce via interactive rebase (edit → rm → amend → continue)
- Force-pushed with lease; SHAs after that point changed
- Revoked exposed GCP key and ensured `.gitignore` excludes `serviceAccountKey.json`

### Resolved (2025-10-22): Admin Authentication & Storage Upload
- **Issue**: Admin claims couldn't be verified in browser console
  - **Root Cause**: Flutter runs in Dart environment, not browser JavaScript
  - **Solution**: Admin claims checked automatically in auth_provider.dart:47
  - **Setup**: Custom claims set in Firebase Console → User → Edit Custom Claims → `{"admin": true}`

- **Issue**: CORS errors when uploading files from localhost
  - **Root Cause**: Firebase Storage blocks localhost by default
  - **Solution**: Configure CORS via Google Cloud SDK:
    1. Install gcloud CLI
    2. `gcloud auth login && gcloud config set project meditation-by-vk-89927`
    3. Create cors.json with `"origin": ["http://localhost:*"]`
    4. `gsutil cors set cors.json gs://meditation-by-vk-89927.firebasestorage.app`
  - **Permanent Fix**: One-time setup, works forever

- **Issue**: Uploads hitting wrong storage bucket (.appspot.com instead of .firebasestorage.app)
  - **Root Cause**: firebase_options.dart had legacy bucket URL
  - **Solution**: Changed storageBucket to `meditation-by-vk-89927.firebasestorage.app`

### Resolved (2025-10-21): Admin categories reorder
  - Moved to `CustomScrollView + SliverReorderableList`
  - Explicit drag handle with Material proxy for drag overlay
  - Optimistic local order with delayed clear after stream sync
  - Stabilized subtitle (AnimatedSwitcher + computed index) to prevent list jump

---

## Ideas for Later (Post-Launch Backlog)

### Features
- Social features (friend meditation sessions, challenges)
- Meditation programs (multi-day courses)
- AI-personalized recommendations
- Sleep timer functionality
- Widgets for quick access
- Apple Watch / WearOS support
- Spotify-like year recap feature
- Guided meditation creation tools
- Community-submitted meditations

### Technical
- GraphQL for more flexible queries
- Dedicated CDN for audio (CloudFlare)
- Server-side rendering for SEO
- A/B testing framework
- Advanced analytics (user cohorts, funnels)

### Monetization
- Lifetime subscription option
- Gift subscriptions
- Corporate/enterprise plans
- Affiliate program for instructors

---

## 🔗 Complete Documentation Map

### Core References (MUST READ)
- **[CODE_FLOW.md](./CODE_FLOW.md)** - System architecture, data flows, initialization sequences
- **[APP_LOGIC.md](./APP_LOGIC.md)** - One-liner module descriptions, quick reference

### Development Guides
- **[CLAUDE.md](./CLAUDE.md)** - Development rules, coding standards, workflow
- **[PLANNING.md](./PLANNING.md)** - Architecture decisions, tech stack rationale

### Technical Documentation
- **[docs/architecture/Firebase.md](./docs/architecture/Firebase.md)** - Backend architecture, security rules
- **[PHASE_0_BOOTSTRAP.md](./PHASE_0_BOOTSTRAP.md)** - Initial setup steps (95% complete)
- **[meditation_by_vk/FIREBASE_SETUP.md](./meditation_by_vk/FIREBASE_SETUP.md)** - Emulator configuration guide
 - **[docs/architecture/Theming.md](./docs/architecture/Theming.md)** - Theming system (presets, tinting, adding themes)

### Project Management
- **[README.md](./README.md)** - Project overview, getting started
- **This file (TASK.md)** - Current progress and todo items