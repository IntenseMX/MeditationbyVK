# TASK.md

Last Updated: 2025-11-05

## Completed Fixes (2025-10-25)

### Android Audio Playback Fix
- Changed MainActivity to extend `AudioServiceActivity` instead of `FlutterActivity`
- Added AudioService declaration to AndroidManifest.xml with `foregroundServiceType="mediaPlayback"`

## Phase 3 – Section A Completion (2025-10-27)
## Phase 3 – Section B Progress (2025-10-28)
- Home/Discover wired to Firestore: trending, recent, recommended, categories (live streams)
- Pagination helpers added in `MeditationService.fetchPublishedPage`
- Composite indexes added: (status, playCount desc), (status, publishedAt desc/asc)
- Discover screen replaced `DummyData` with `categoriesStreamProvider`
- Progress/Profile placeholders made null-safe for guest mode (local-only)

Next
- Guest profile provider (local storage) for name/stats placeholders
- Hook session writes to increment `playCount` and drive trending
- Router guards finalized with splash CTA and guest/auth flows
- Audio session configured via audio_session (music category) and Android audio attributes set.
- Interruption handling: pauses on calls/interruptions, ducks and restores volume, pauses on becoming noisy (headphones unplug).
- Background playback validated: iOS Info.plist `UIBackgroundModes: audio` present; Android foreground service and permissions present.
- Resume position persisted on pause/stop/complete.
- Provider exposes stop() for deterministic writes.

Follow-ups
- Consider optional auto-resume policy after transient interruptions.
 
## Phase 3 – Section D (2025-11-05)
- Discover → Category tap navigates to `/category/:id` (non-admin route)
- Added `CategoryMeditationsScreen` with header name and filtered list
- Category pagination: `fetchPublishedByCategory()` + `categoryPaginationProvider(categoryId)`
- Reused `MeditationCard` for rendering with Load More button
- Search functionality: TextField in Discover filters meditations by title (inline results)
- Added composite indexes: (status ASC, createdAt DESC) + (status ASC, categoryId ASC, publishedAt DESC)