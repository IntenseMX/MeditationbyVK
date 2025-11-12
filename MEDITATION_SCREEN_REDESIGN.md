# Meditation Detail Screen with Comments - Implementation Plan

**Created:** 2025-11-07
**Updated:** 2025-01-12
**Status:** Planning Phase - Ready to Implement
**New File:** `lib/presentation/screens/meditation_detail_screen.dart`

---

## ⚠️ Important: Player Screen Already Redesigned

**The player screen redesign is COMPLETE** as of 2025-01-12. This plan is for a **NEW screen** separate from the player.

**Player Screen Documentation:**
1. [`PLAYER_SCREEN_REDESIGN_PLAN.md`](./PLAYER_SCREEN_REDESIGN_PLAN.md) - Complete implementation plan and refinements
2. [`PLAYER_SCREEN_REDEPLOYMENT_SUMMARY.md`](./PLAYER_SCREEN_REDEPLOYMENT_SUMMARY.md) - Deployment details and feature set
3. [`PLAYER_SCREEN_COMPILATION_FIXES_SUMMARY.md`](./PLAYER_SCREEN_COMPILATION_FIXES_SUMMARY.md) - All fixes applied

**Current Player Features:**
- ✅ Glassmorphism floating card design
- ✅ Waveform progress slider
- ✅ Rewind/Forward 15s buttons
- ✅ Speed control (0.75x - 2x)
- ✅ Loop/Repeat toggle
- ✅ Sleep timer & Share buttons
- ✅ Haptic feedback on all controls

**This plan does NOT modify the player screen.** The player stays exactly as redesigned.

---

## Vision

Create a **community-driven meditation detail page** as an intermediary screen where users can:
- See meditation info in a compact layout
- Read and write comments
- Engage with other meditators asynchronously
- Tap "Play" to launch the redesigned player screen

**Navigation Flow:**
```
Home Screen
    ↓ [Tap Meditation Card]
Meditation Detail Screen (NEW - this plan)
    ↓ [Tap Play Button]
Player Screen (EXISTING - already redesigned)
```

---

## New Layout (Meditation Detail Screen)

```
┌─────────────────────────────┐
│ AppBar: Back | Title        │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ [Compact Card - Top]    │ │ ← Meditation Info Section
│ │ ┌─────┐  Title          │ │
│ │ │Image│  Description    │ │
│ │ │ 1:1 │  Duration: 5min │ │
│ │ └─────┘  Category       │ │
│ │                         │ │
│ │  ▶ Play  ───── 0:00     │ │ ← Inline player controls
│ └─────────────────────────┘ │
│                             │
│ ──────────────────────────  │ ← Divider
│                             │
│ 💬 Comments (24)            │ ← Comments Header
│                             │
│ ┌─────────────────────────┐ │
│ │ 👤 User123 ⭐⭐          │ │ ← Comment item
│ │ "This helped me sleep!" │ │
│ │ 2 days ago              │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 👤 MeditatorPro ⭐⭐⭐⭐  │ │
│ │ "Amazing visualization" │ │
│ │ 1 week ago              │ │
│ └─────────────────────────┘ │
│                             │
│ ... more comments ...       │
│                             │
│ [Add Comment Button] 💬     │ ← Floating button
└─────────────────────────────┘
```

---

## Design Changes

### 1. Compact Meditation Info Card (Top Section)

**Current:** Full-width hero image + separate info below
**New:** Horizontal card with thumbnail + inline info

**Layout:**
- **Image**: Square thumbnail (80x80 or 100x100) on left
- **Right side (column):**
  - Title (bold, 1-2 lines max with ellipsis)
  - Description (2-3 lines max, "Read more" if truncated)
  - Duration badge + Category chip (inline row)
- **Player Controls** (below card):
  - Play/Pause button (medium size, not huge)
  - Progress slider
  - Time stamps (current / total)

**Benefits:**
- ~70% less vertical space than current design
- Still shows all essential info
- More content visible above fold

---

### 2. Comments Section

**Components:**
- **Header:** "Comments (count)" with sort dropdown (newest/oldest/popular - Phase 2)
- **Comment List:** Scrollable list of comment cards
- **Add Comment:** Floating action button or bottom sheet

#### Comment Item Structure

```dart
{
  id: string,
  meditationId: string,
  userId: string,
  userName: string,         // Cached from profile
  userAvatar: string?,      // Optional profile pic URL
  comment: string,          // Max 500 chars
  createdAt: Timestamp,
  // Future:
  likes: int?,
  achievementStars: int?,   // 0-5 stars shown next to name
}
```

#### Firestore Schema

**New Collection:**
```
meditation_comments/{commentId}
  - meditationId: string (indexed)
  - userId: string (indexed)
  - userName: string
  - userAvatar: string?
  - comment: string
  - createdAt: timestamp
  - updatedAt: timestamp?
  - likes: number (default 0, for Phase 2)
```

**Security Rules:**
```javascript
match /meditation_comments/{commentId} {
  // Anyone can read
  allow read: if true;

  // Authenticated users can create
  allow create: if request.auth != null
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.comment.size() > 0
    && request.resource.data.comment.size() <= 500;

  // Users can edit/delete their own comments
  allow update, delete: if request.auth != null
    && resource.data.userId == request.auth.uid;
}
```

---

### 3. Comment Features (Phase 1)

**Must Have:**
- ✅ Display comments in reverse chronological order (newest first)
- ✅ Show username + comment text + timestamp ("2 days ago")
- ✅ "Add Comment" button → opens bottom sheet with text field
- ✅ Submit button (validates: not empty, max 500 chars)
- ✅ Loading states (shimmer placeholders while fetching)
- ✅ Empty state: "🎉 Be the FIRST to share your experience!"
- ✅ Error handling (failed to load, failed to submit)
- ✅ Character counter (e.g., "250 / 500 characters")

**Simplified Scope (Keeping it Simple):**
- ❌ NO likes/upvotes (Phase 1)
- ❌ NO replies/threading (keeping comments flat)
- ❌ NO editing comments (once posted, it's permanent)
- ❌ NO username updates (username frozen at time of comment)
- ❌ NO meditation authors (meditations don't have authors)

**Nice to Have (Phase 2 - If Needed):**
- 🔽 Sort options (newest/oldest)
- 🚫 Report/flag inappropriate comments + basic moderation
- 📊 Analytics (engagement metrics)

---

### 4. Achievement Stars System (Phase 2+)

**Concept:** Show 1-5 stars next to username based on:
- **1 ⭐:** 7-day meditation streak
- **2 ⭐⭐:** 30-day streak
- **3 ⭐⭐⭐:** 90-day streak
- **4 ⭐⭐⭐⭐:** 180-day streak
- **5 ⭐⭐⭐⭐⭐:** 365-day streak

**Implementation:**
- Add `achievementLevel` field to user profile
- Calculate from `currentStreak` in `users/{userId}` doc
- Cache in comment document when posted
- Re-calculate periodically or on profile update

---

## Technical Implementation

### New Providers

**1. Comments Provider**
```dart
// lib/providers/comments_provider.dart

@riverpod
Stream<List<MeditationComment>> meditationComments(
  MeditationCommentsRef ref,
  String meditationId,
) {
  return FirebaseFirestore.instance
    .collection('meditation_comments')
    .where('meditationId', isEqualTo: meditationId)
    .orderBy('createdAt', descending: true)
    .limit(50)
    .snapshots()
    .map((snap) => snap.docs.map((doc) => MeditationComment.fromFirestore(doc)).toList());
}

@riverpod
class CommentActions extends _$CommentActions {
  Future<void> addComment(String meditationId, String comment) async { ... }
  Future<void> deleteComment(String commentId) async { ... }
}
```

**2. Comment Model**
```dart
// lib/models/meditation_comment.dart

class MeditationComment {
  final String id;
  final String meditationId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String comment;
  final DateTime createdAt;
  final int likes;
  final int? achievementStars;

  factory MeditationComment.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }
}
```

### UI Components

**1. Compact Meditation Card Widget**
```dart
// lib/presentation/widgets/compact_meditation_card.dart

class CompactMeditationCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final int durationSec;
  final String? categoryId;

  // Horizontal layout: thumbnail + info column
}
```

**2. Comment List Widget**
```dart
// lib/presentation/widgets/comment_list.dart

class CommentList extends ConsumerWidget {
  final String meditationId;

  // Displays comments stream with loading/error/empty states
}
```

**3. Comment Item Widget**
```dart
// lib/presentation/widgets/comment_item.dart

class CommentItem extends StatelessWidget {
  final MeditationComment comment;

  // Shows avatar, username, stars, comment text, timestamp
}
```

**4. Add Comment Bottom Sheet**
```dart
// lib/presentation/widgets/add_comment_sheet.dart

class AddCommentSheet extends ConsumerStatefulWidget {
  final String meditationId;

  // Text field + submit button
  // Validates length, shows char count
}
```

---

## Migration Path

### Phase 1: Create Detail Screen (No Comments Yet)
1. Create new route `/meditation-detail/:id` in `app_router.dart`
2. Create `meditation_detail_screen.dart` (new file)
3. Create `CompactMeditationCard` widget
4. Wire up navigation: Home → Detail → Player
5. Add "Play" button that navigates to existing player screen
6. Test hero animation from Home → Detail → Player
7. Ensure existing Home → Player direct route still works (backwards compatibility)

**Files to Create:**
- `lib/presentation/screens/meditation_detail_screen.dart`
- `lib/presentation/widgets/compact_meditation_card.dart`

**Files to Modify:**
- `lib/presentation/app_router.dart` (add new route)
- `lib/presentation/screens/home_screen.dart` (change navigation target)

### Phase 2: Add Comments Infrastructure
1. Create Firestore collection + security rules
2. Create `MeditationComment` model
3. Create `comments_provider.dart` with read/write actions
4. Add `timeago` package for timestamp formatting
5. Test comment CRUD operations in isolation

**Files to Create:**
- `lib/models/meditation_comment.dart`
- `lib/providers/comments_provider.dart`
- `lib/services/comment_service.dart` (optional, if complex logic needed)

**Firestore Setup:**
- Add `meditation_comments` collection
- Add security rules
- Create composite index: `meditationId ASC, createdAt DESC`

### Phase 3: Add Comments UI
1. Create `CommentList` widget (display comments)
2. Create `CommentItem` widget (individual comment card)
3. Create `AddCommentSheet` bottom sheet widget
4. Integrate into `meditation_detail_screen.dart`
5. Add empty/loading/error states
6. Add character counter (500 max)
7. Test real-time updates

**Files to Create:**
- `lib/presentation/widgets/comment_list.dart`
- `lib/presentation/widgets/comment_item.dart`
- `lib/presentation/widgets/add_comment_sheet.dart`

### Phase 4: Polish & Launch
1. Add comment count badge in header
2. Implement delete own comment (if needed)
3. Add basic profanity filter or moderation
4. Test pagination (50 comments at a time)
5. Monitor performance and fix edge cases

### Phase 5: Achievement Stars (Future - Optional)
1. Add `achievementLevel` to user profile
2. Calculate from streak data
3. Cache in comment when posted
4. Display stars next to username in comments
5. Add legend/tooltip explaining star system

---

## Design Decisions

1. **Image Size:** 1:1 square thumbnail (80x80 or 100x100)
   - Space efficient, consistent across app

2. **Player Screen:** Separate from detail screen
   - Detail screen has compact info + comments
   - Player screen is the redesigned immersive experience (see player docs)

3. **Gradient Background:** Simple, minimal gradient
   - Don't distract from comments
   - Keep it calm and readable

4. **Guest Users:** NO - require sign-in to comment
   - Prevents spam
   - Encourages account creation
   - Easy to implement (already have auth)

5. **Real-time Comments:** YES - Firestore snapshot listener
   - Auto-update when new comments arrive
   - Modern, engaging experience

6. **Comment Ordering:** Newest first (no sort options in Phase 1)
   - Simple, predictable
   - Can add sorting later if needed

7. **Comment Features:** Keep it simple
   - No likes, no replies, no editing
   - Just read + write comments
   - Can expand later based on usage

---

## Success Metrics

**User Engagement:**
- % of users who view comments
- % of users who write comments
- Average comments per meditation
- Time spent on detail screen (vs old player screen)

**Community Health:**
- Comments per day
- Unique commenters per week
- Repeat commenters (users who comment 2+ times)

**Retention:**
- Do users with comments return more often?
- Does comment count correlate with meditation popularity?

---

## Dependencies

**New Packages (if needed):**
- `timeago: ^3.6.0` - Format timestamps ("2 days ago")
- `cached_network_image: ^3.3.0` - Already used? (for avatars)
- `flutter_markdown: ^0.6.18` - If allowing markdown in comments (Phase 2)

**Firestore Indexes:**
```
Collection: meditation_comments
Index: meditationId ASC, createdAt DESC
```

---

## Files to Create/Modify

### New Files
```
lib/models/meditation_comment.dart
lib/providers/comments_provider.dart
lib/services/comment_service.dart
lib/presentation/widgets/compact_meditation_card.dart
lib/presentation/widgets/comment_list.dart
lib/presentation/widgets/comment_item.dart
lib/presentation/widgets/add_comment_sheet.dart
```

### Modified Files
```
lib/presentation/screens/player_screen.dart (major refactor)
firestore.rules (add meditation_comments rules)
```

### New Tests (Phase 2)
```
test/services/comment_service_test.dart
test/providers/comments_provider_test.dart
```

---

## Timeline Estimate

**Phase 1 (Detail Screen Setup):** 2-3 hours
- Create meditation_detail_screen.dart: 1h
- Create CompactMeditationCard widget: 0.5h
- Wire up navigation (Home → Detail → Player): 0.5h
- Test hero animations and routing: 0.5h
- Polish layout and styling: 0.5h

**Phase 2 (Comments Infrastructure):** 2-3 hours
- Firestore schema + security rules: 0.5h
- Create MeditationComment model: 0.5h
- Create comments_provider.dart: 1h
- Add timeago package and test: 0.5h
- Test CRUD operations: 0.5h

**Phase 3 (Comments UI):** 4-5 hours
- CommentList widget: 1h
- CommentItem widget: 1h
- AddCommentSheet bottom sheet: 1h
- Empty/loading/error states: 1h
- Integration + real-time testing: 1h

**Phase 4 (Polish & Launch):** 2-3 hours
- Comment count badge: 0.5h
- Character counter validation: 0.5h
- Delete own comment: 0.5h
- Pagination (if needed): 0.5h
- Final testing + bug fixes: 1h

**Phase 5 (Achievement Stars - Optional):** 3-4 hours
- Add achievementLevel to profile: 1h
- Calculate from streak: 1h
- Display in comments: 0.5h
- Tooltip/legend: 0.5h
- Testing: 1h

**Total:** ~10-14 hours for Phases 1-4 (MVP)
**With Phase 5:** ~13-18 hours (full feature set)

---

## Notes

- This creates a **NEW screen** separate from the player (which is already complete)
- Shifts meditation discovery from **individual experience** → **community hub**
- Comments create passive social proof ("124 comments" indicates popularity)
- Achievement stars gamify consistency and create aspirational goals (Phase 5)
- Minimal backend complexity (just Firestore, no custom cloud functions)
- Scales well (comments paginated, indexed queries)
- Keeps player screen immersive and distraction-free

**Key Simplifications:**
- No likes/upvotes (reduces complexity, keeps focus on meditation)
- No replies/threading (flat comment structure)
- No editing (once posted, permanent - reduces abuse potential)
- No author system (meditations are from the app, not individuals)
- Username frozen at post time (no retroactive updates)

---

## Next Steps

### Ready to Implement ✅

**Prerequisites:**
- ✅ Player screen redesign complete (see referenced docs)
- ✅ Authentication system in place
- ✅ Firestore already configured
- ✅ User profiles exist with usernames

**Start Implementation:**
1. **Phase 1:** Create meditation detail screen with compact layout
2. **Phase 2:** Add Firestore comments infrastructure
3. **Phase 3:** Build comments UI
4. **Phase 4:** Polish and launch MVP
5. **Phase 5 (Optional):** Add achievement stars system

**Recommended Approach:**
- Ship Phase 1-2 together (detail screen with read-only comments)
- Ship Phase 3 separately (add comment functionality)
- Monitor engagement before deciding on Phase 4-5

---

## Related Documentation

- [`PLAYER_SCREEN_REDESIGN_PLAN.md`](./PLAYER_SCREEN_REDESIGN_PLAN.md) - Player screen implementation (COMPLETE)
- [`PLAYER_SCREEN_REDEPLOYMENT_SUMMARY.md`](./PLAYER_SCREEN_REDEPLOYMENT_SUMMARY.md) - Deployment details
- [`PLAYER_SCREEN_COMPILATION_FIXES_SUMMARY.md`](./PLAYER_SCREEN_COMPILATION_FIXES_SUMMARY.md) - Bug fixes applied

---

**Document Status:** ✅ Updated and Ready
**Last Updated:** 2025-01-12
**Status:** Planning Complete - Ready for Implementation
