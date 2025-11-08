# Phase 3: Core Features – The App Becomes Real
Last Updated: 2025-10-28

## Goal
Transform from CMS + UI into a fully working meditation app: play audio, track progress, discover content, and personalize home.

## Success Criteria
1. User can play any meditation with background audio.
2. Sessions saved; streaks correct across timezones.
3. Category filtering returns correct results.
4. Trending/Recently Added populated from real data.
5. Offline metadata + previously played audio stream.
6. Resume last position works.
7. Home shows Continue + category-based recommendations.

## Milestones
### A) Audio Player (just_audio)
- [ ] Stream Firebase Storage URL
- [ ] Play/Pause/Seek
- [ ] Background audio + lock screen controls
- [ ] Resume last position
- [ ] Handle interruptions (calls/other apps)

### B) Real Data Integration
- [ ] Replace dummy lists with Firestore
- [ ] Pagination (20)
- [ ] Categories from DB
- [ ] Real-time updates
- [ ] Composite indexes configured
// B Notes (2025-10-28): Auth gate + guest flow added
- [ ] Auth gate + guest flow (enable Anonymous Sign-In), splash CTA, router guard

### C) Progress Tracking
- [ ] Write session on completion → `users/{uid}/sessions`
- [ ] Streak calc (UTC-safe), longest streak
- [ ] Total listening time, count, today’s minutes
- [ ] Increment `meditations/{id}.playCount`

### D) Category Filtering & Trending
- [ ] Filter by category via `where('category' == selected)`
- [ ] Trending by `orderBy('playCount','desc').limit(10)`
- [ ] Recently added by `orderBy('publishedAt','desc').limit(20)`
- [ ] All meditations with pagination

### E) Home Page Dynamic Content
- [ ] Continue Listening (last `completed=false`)
- [ ] Trending (top 5)
- [ ] Recently Added (10)
- [ ] Recommended (top categories by session history)

### F) Basic Offline Support
- [ ] Enable Firestore persistence
- [ ] Metadata available offline
- [ ] just_audio temp caching OK
- [ ] Queue progress offline, sync on reconnect

## Implementation Order
Week 1:
1) Audio player foundation
2) Real data integration
3) Basic progress tracking

Week 2:
4) Category filtering
5) Home personalization
6) Offline support
7) Testing & polish

## Technical Notes
- Audio: `just_audio` via `AudioService` + `AudioPlayerProvider`
- Data: `MeditationService` Firestore streams with pagination
- Progress: `ProgressService` writes; UTC timestamps; 80% completion threshold
- Indexes: category+status+createdAt; status+difficulty+durationSec
- Caching: Firestore persistence; queued writes for sessions
// Auth & Security (2025-10-28)
- Auth states: `initial | guest | authenticated | error`; providers read `uid` only after auth ready
- Guest via Anonymous Sign-In; Splash uses CTA to initialize auth and opt-in networking
- Firestore/Storage reads require auth (anonymous or email)

## Edge Cases / Risks
- Timezone/DST on streaks (use UTC boundaries)
- Background/lock screen media session differences (iOS/Android)
- Pagination with filtered queries (requires correct indexes)
- Network drops during playback and write queueing

## Testing Checklist
- [ ] Play/pause/seek across screens and background
- [ ] Lock screen controls update correctly
- [ ] Resume works after app kill/reopen
- [ ] Streak boundaries (UTC midnight, DST shift)
- [ ] Pagination correctness (no duplicates/skips)
- [ ] Offline read of cached lists + queued writes
- [ ] Continue/Recommended update after completion
// Auth Flow (2025-10-28)
- [ ] Splash shows CTA; no auto-navigation; smooth fade-in
- [ ] “Continue as Guest” signs in anonymously and navigates to Home
- [ ] Return user: “Continue” navigates without re-auth
- [ ] Router guard blocks Home tabs until user state is ready; admin routes gated by admin claim

## Docs & Hygiene
- Update `TASK.md` checklist per milestone
- Update `CODE_FLOW.md` (playback + data flows)
- Update `APP_LOGIC.md` (providers/services one-liners)
- Add any new indexes to `firestore.indexes.json`


