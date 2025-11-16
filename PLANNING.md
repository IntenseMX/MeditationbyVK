# PLANNING.md - Meditation by VK

Last Updated: 2025-11-10

## 📚 Related Documentation

**Before reading this document, ensure you've reviewed:**
- **[CODE_FLOW.md](./CODE_FLOW.md)** - Complete system architecture and data flows
- **[APP_LOGIC.md](./APP_LOGIC.md)** - One-liner descriptions of all modules

**This document covers:**
- Architecture decisions and rationale
- Technology choices and trade-offs
- Development pipeline and deployment strategy

**See also:**
- **[TASK.md](./TASK.md)** - Current implementation status
- **[CLAUDE.md](./CLAUDE.md)** - Development rules and guidelines
- **[docs/architecture/Firebase.md](./docs/architecture/Firebase.md)** - Backend architecture details
 - **[docs/architecture/Theming.md](./docs/architecture/Theming.md)** - Theming system guide

## Development Strategy: Local-First (2025-10-18)

### 🚨 Firebase Emulator-Only Development Until Phase 3+
**All development happens locally with Firebase Emulators until app is feature-complete.**

- **Phase 0-2**: Complete local development with emulators (current stage)
- **Phase 3+**: Deploy to Firebase Cloud only when ready for production
- **Benefits**:
  - Zero Firebase costs during development
  - Instant database resets for testing
  - No risk of production data corruption
  - Faster iteration without network latency
- **Requirements**: Java 11+ for Firebase Emulators

This approach ensures we build and test everything locally before incurring any cloud costs.

---

## Phase Mapping

| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| **Phase 1: Foundation** | Architecture, Firebase setup, auth, navigation | Working skeleton app with dummy data |
| **Phase 2: Content System** | Admin panel, CMS, upload pipeline | No-code content management |
| **Phase 3: Core Features** | Audio player, progress tracking, **offline cache** | Functioning meditation app |
| **Phase 4: Monetization** | Subscriptions, **notifications**, premium gates | Revenue-ready app |
| **Phase 5: Polish** | **Web version, SEO, landing page**, QA, optimization | Production-ready multi-platform |

---

## Architecture Overview

### Why Flutter + Firebase?
- **Flutter**: Single codebase for iOS/Android, excellent performance, rich UI components
- **Firebase**: Managed backend, real-time sync, built-in auth, scales automatically
- **Decision**: Best time-to-market with production quality (Phase 1)

### Why Riverpod over Provider?
- **Performance**: Better rebuild optimization, compile-time safety
- **DevX**: Auto-dispose, family modifiers, better testing
- **Future-proof**: Active development, modern patterns
- **Decision**: Worth the slightly steeper learning curve (Phase 1)

Note (2025-10-23):
- Given `flutter_riverpod: ^3.x`, we standardized on `NotifierProvider` for editor state and avoided `AsyncNotifier` APIs.
- Lifecycle safety is enforced by deferring initial loads from screens (post-frame) and deferring auth init with a microtask.

### Why GoRouter?
- **Declarative**: Type-safe routes, deep linking support
- **Integration**: Works perfectly with Riverpod
- **Features**: Guards, redirects, nested navigation
- **Decision**: Official Google package, production-ready (Phase 1)

### Why Clean Architecture?
- **Testable**: Business logic separate from UI/Firebase
- **Scalable**: Easy to add features without breaking existing code
- **Solo-dev friendly**: Clear boundaries prevent spaghetti code
- **Decision**: Slight upfront cost, massive long-term savings (Phase 1)

### Offline Caching Strategy (Phase 3)
- **Approach**: Firestore offline persistence + local audio cache
- **Storage**: Hive for metadata, device storage for audio files
- **Sync**: Background sync when online, queue writes offline
- **Decision**: Premium feature, builds user loyalty

### Notification Architecture (Phase 4)
- **FCM**: Firebase Cloud Messaging for push notifications
- **Types**: Daily reminders, streak alerts, new content
- **Scheduling**: Local notifications + server-triggered
- **Decision**: Critical for retention, implement after core features work

### Landing Page Plan (Phase 5)
- **Platform**: Flutter Web (share code with mobile app)
- **SEO**: Static site generation for better indexing
- **Content**: Feature showcase, testimonials, pricing, download links
- **Decision**: Marketing site separate from app, optimized for conversions

---

## Core Architecture Decisions

### 1. State Management Strategy
```
UI Layer → Riverpod Providers → Services → Firebase
```
- Providers handle ALL business logic (Phase 1)
- Services are thin wrappers around Firebase (Phase 1)
- UI remains purely presentational (Phase 1)
- No direct Firebase calls from widgets (Phase 1)

### 2. Audio Architecture
- **just_audio**: Industry standard for Flutter audio (Phase 3)
- **Background**: Native implementation for iOS/Android (Phase 3)
- **Streaming**: Direct from Firebase Storage URLs (Phase 3)
- **Caching**: Hive for metadata, local files for offline (Phase 3)

### 3. Authentication Flow
```
Guest Mode → Optional Sign Up → Full Features
```
- Reduce friction with guest mode (Phase 1)
- Progressive enhancement (can upgrade anytime) (Phase 1)
- Single sign-on with Google/Apple (Phase 1)
- Email/password as fallback (Phase 1)

### 4. Data Architecture
- **Firestore**: Document database for flexibility (Phase 1)
- **Denormalization**: Duplicate data for read performance (Phase 2)
- **Offline**: Firestore offline persistence + Hive for metadata (Phase 3 only)
- **Security**: Row-level with Firebase Rules (Phase 2)

---

## Data Flow Examples

### Playing a Meditation (Phase 3)
1. User taps meditation card
2. `MeditationProvider` fetches from `MeditationService`
3. `MeditationService` queries Firestore (cached if offline)
4. `AudioPlayerProvider` receives meditation data
5. `AudioService` streams from Firebase Storage (or local cache)
6. `ProgressProvider` tracks session
7. UI updates via `ref.watch()`

### Authentication (Phase 1)
1. User chooses auth method (guest/email/Google)
2. `AuthProvider` calls `AuthService`
3. `AuthService` uses FirebaseAuth
4. Success: Provider updates state
5. All providers listening to auth rebuild
6. Router redirects to home

### Offline Sync Flow (Phase 3)
1. User goes offline mid-session
2. Audio continues from local cache
3. Progress writes queue in Hive
4. User completes meditation offline
5. App detects online status
6. Queued writes sync to Firestore
7. Streak calculation updates

### Notification Trigger Flow (Phase 4)
1. User sets daily reminder time
2. Local notification scheduled
3. Streak break detected (server-side)
4. FCM sends push notification
5. User taps notification
6. Deep link opens specific meditation

---

## Performance Strategy

### Initial Load (Phase 1)
- Lazy load everything except core
- Show skeleton screens immediately
- Preload next likely screen
- Cache images aggressively

#### Perceived vs Actual Performance (2025-11-10)
- Prioritized perceived performance: gate Splash CTAs until data-ready + intro complete, with a 4s “Skip” fallback to skeletons.
- Removed offscreen Home warmup overlay (duplicate tree build) to reduce startup cost.
- Implemented shimmer skeletons for Home sections to avoid spinners.
- Virtualized Trending belt and throttled auto-scroll to cut frame work.
- Downscaled/cached card images to reduce memory and decode time.
- Added debug frame timing logs; profile mode + DevTools remain the source of truth.

### Audio Performance (Phase 3)
- Preload next in playlist
- Keep player instance alive
- Buffer 30 seconds ahead
- Fallback bitrates for slow connections

### Firebase Optimization (Phase 2)
- Composite indexes for common queries
- Pagination for large lists (20 items)
- Local cache for offline mode
- Batch writes when possible

### Offline Performance (Phase 3)
- Instant playback from cache
- Background sync when online
- Smart cache eviction (LRU, size limits)
- Prefetch trending meditations

---

## Security Model

### Client Security (Phase 1)
- No sensitive logic on client
- All validation server-side
- API keys in environment variables
- Obfuscate production builds

### Firebase Rules (Phase 2)
```javascript
// Users can only read/write their own data
match /userProgress/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// Premium content requires subscription
match /meditations/{meditationId} {
  allow read: if !resource.data.isPremium ||
                 get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isPremium;
}
```

---

## Scaling Considerations (Phase 5)

### MVP (0-1K users)
- Single Firebase project
- Basic Firestore structure
- No optimization needed

### Growth (1K-10K users)
- Add Firestore indexes
- Implement caching layer
- CDN for audio files

### Scale (10K+ users)
- Separate read/write databases
- Cloud Functions for heavy ops
- CDN strategy: Firebase Storage (default) → Cloudflare R2 (if costs spike) → Dedicated audio CDN (if performance issues)

---

## Testing Strategy (Phase 5)

### Unit Tests
- All providers must have tests
- Service layer mocked
- 80% coverage target

### Integration Tests
- Critical user flows
- Auth, playback, progress
- Run on CI/CD

### E2E Tests
- Happy path only initially
- Add more as we scale
- Use Firebase emulator

---

## Deployment Pipeline (Phase 5)

### Development (Current - Phase 0-2)
- Local Firebase emulator ONLY
- Hot reload for fast iteration
- Debug builds to device
- NO cloud deployment yet

### Staging (Phase 3)
- First cloud deployment here
- Separate Firebase project
- TestFlight / Play Console Beta
- Real device testing

### Production (Phase 4+)
- GitHub Actions CI/CD
- Automatic version bumping
- Gradual rollout strategy

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-01-18 | Use Riverpod over Provider | Better performance and DevX |
| 2025-01-18 | Firebase over custom backend | Faster time to market |
| 2025-01-18 | Guest mode first | Reduce user friction |
| 2025-01-18 | No localStorage/Hive in Phase 1 | Avoid sync complexity, add Hive Phase 3 for offline |
| 2025-01-18 | Clean Architecture | Testable, scalable for solo dev |
| 2025-10-23 | Defer provider mutations from build | Riverpod v3 compatibility; stability during routing |
| 2025-10-29 | Zen splash animations with centralized config | Calmer onboarding, cohesive motion system, all timings in `SplashAnimationConfig` for maintainability |
| 2025-01-18 | Admin panel before core features | Content must exist before app works |
| 2025-01-18 | Offline storage limit | 500MB free, unlimited premium |
| 2025-01-18 | FCM notifications Phase 4 | After monetization ready |
| 2025-01-18 | Flutter Web landing page Phase 5 | Marketing site for SEO |

---

## Code Cleanup Backlog (2025-11-16)

### Orphaned Widgets
- **CompactMeditationCard** (`lib/presentation/widgets/compact_medication_card.dart`): Not used anywhere in the app. Home and Discover use `MeditationCard(compact: true)` instead. Consider removing in future cleanup to reduce bundle size and maintenance surface.

---

## Open Questions

1. **Admin Panel**: Flutter Web or React? (See Phase 2 tasks)
   - Leaning towards: Flutter Web to share code, but React if we need rich editor

2. **Analytics**: Firebase Analytics enough or add Mixpanel?
   - Start with Firebase, add Mixpanel if needed (Phase 4)

3. **Subscription**: RevenueCat or native?
   - RevenueCat for faster implementation (Phase 4)

4. **Landing Page**: Separate domain or subdomain?
   - meditationvk.com for marketing, app.meditationvk.com for web app

---

## Risk Mitigation

| Risk | Impact | Mitigation | Phase |
|------|--------|------------|-------|
| Firebase costs spike | High | Set budget alerts, optimize queries | Phase 2 |
| Audio streaming issues | High | Multiple bitrates, download option | Phase 3 |
| Platform rejection | Medium | Follow guidelines strictly | Phase 5 |
| Riverpod learning curve | Low | Team training, good docs | Phase 1 |
| Offline sync conflicts | Medium | Last-write-wins, user notification | Phase 3 |
| Notification fatigue | Low | User controls, smart frequency | Phase 4 |

---

## Success Metrics

### Technical KPIs
- Crash-free rate > 99.5%
- App launch < 2 seconds (Phase 1)
- Audio start < 1 second (Phase 3)
- Firebase costs < $100/month initially (Phase 2)
- Offline playback instant (Phase 3)

### User KPIs
- Guest → Account conversion > 30% (Phase 4)
- Daily active users > 40% (Phase 4)
- Session completion > 70% (Phase 3)
- 7-day retention > 50% (Phase 4)
- Push notification CTR > 15% (Phase 4)