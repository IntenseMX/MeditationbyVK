# Meditation Screen Redesign Plan

**Created:** 2025-11-07
**Status:** Planning Phase
**Current File:** `lib/presentation/screens/player_screen.dart`
**New Name:** `meditation_detail_screen.dart` (or keep `player_screen.dart`)

---

## Vision

Transform the meditation player from a **pure audio player** into a **community-driven meditation detail page** where users can:
- See all meditation info in a cleaner, more compact layout
- Read and write comments
- Engage with other meditators asynchronously
- (Future) See achievement badges next to usernames

---

## Current Layout (Player Screen)

```
┌─────────────────────────────┐
│ AppBar: Title               │
├─────────────────────────────┤
│ Gradient Background         │
│ Floating Bubbles            │
│                             │
│  [Hero Image - 16:9]        │
│                             │
│  Description Text           │
│  Category Chip              │
│                             │
│  ┌───────────┐              │
│  │ Breathing │              │
│  │  Circle   │              │
│  └───────────┘              │
│                             │
│     ▶ Play Button           │
│                             │
│  0:00 ────────────── 5:00   │
│       [Slider]              │
│                             │
└─────────────────────────────┘
```

**Problems:**
- Image takes up ~40% of screen
- No social/community features
- Static, one-way experience
- No user engagement beyond listening

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
- ✅ Empty state: "No comments yet. Be the first!"
- ✅ Error handling (failed to load, failed to submit)

**Nice to Have (Phase 2):**
- 👍 Like/upvote comments
- 🌟 Achievement stars next to usernames (based on meditation streak)
- 📌 Pin top comment (admin feature)
- 🔽 Sort options (newest/oldest/popular)
- 🚫 Report/flag inappropriate comments
- ✏️ Edit own comments (within 5 min window)

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

### Phase 1: Layout Redesign (No Comments)
1. Create `CompactMeditationCard` widget
2. Refactor `player_screen.dart` to use compact layout
3. Keep all existing player functionality (no breaking changes)
4. Test hero animation still works with smaller image
5. Adjust gradient background to work with new layout

### Phase 2: Add Comments (No Features)
1. Create Firestore collection + security rules
2. Create `MeditationComment` model
3. Create `comments_provider.dart` with read/write actions
4. Build comment list UI (read-only first)
5. Add "Add Comment" button + bottom sheet
6. Test comment submission and real-time updates
7. Add empty/loading/error states

### Phase 3: Comment Features
1. Add timestamp formatting ("2 days ago" with `timeago` package)
2. Add delete own comment functionality
3. Add character count validation (500 max)
4. Add comment count badge in header
5. Implement pagination if needed (50 comments at a time)

### Phase 4: Achievement Stars (Future)
1. Add `achievementLevel` to user profile
2. Calculate from streak data
3. Cache in comment when posted
4. Display stars next to username in comments
5. Add legend/tooltip explaining star system

---

## Open Questions

1. **Image Size:** Keep square thumbnail (1:1) or use 4:3 / 16:9?
   - **Recommendation:** 1:1 square for consistency and space efficiency

2. **Breathing Circle:** Remove entirely or show mini version?
   - **Recommendation:** Remove or make it a toggle-able overlay (tap image to show)

3. **Gradient Background:** Keep animated gradient or simplify?
   - **Recommendation:** Keep but reduce opacity/intensity (don't distract from comments)

4. **Guest Users:** Can they comment?
   - **Recommendation:** No - require sign-in to comment (prevents spam, encourages accounts)

5. **Real-time Comments:** Auto-update when new comments arrive?
   - **Recommendation:** Yes - use Firestore snapshot listener (already streaming)

6. **Comment Ordering:** Always newest first or add sort options?
   - **Recommendation:** Newest first in Phase 1, add sort in Phase 2

7. **Player Controls:** Keep inline or make sticky header?
   - **Recommendation:** Inline for Phase 1 (simpler), sticky header in Phase 2 if needed

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

**Phase 1 (Layout Redesign):** 3-4 hours
- Compact card widget: 1h
- Refactor player screen: 1.5h
- Test + adjust animations: 1h

**Phase 2 (Basic Comments):** 5-6 hours
- Firestore schema + rules: 0.5h
- Model + provider: 1h
- Comment list UI: 1.5h
- Add comment sheet: 1h
- Integration + testing: 2h

**Phase 3 (Comment Features):** 3-4 hours
- Timestamp formatting: 0.5h
- Delete/edit: 1h
- Validation + polish: 1.5h
- Edge cases + testing: 1h

**Phase 4 (Achievement Stars):** 4-5 hours
- Profile achievement logic: 2h
- Star display in comments: 1h
- Caching + updates: 1h
- Testing + edge cases: 1h

**Total:** ~15-19 hours (can be split across multiple sessions)

---

## Notes

- This redesign shifts the meditation experience from **solo player** → **community hub**
- Comments create passive social proof ("124 people found this helpful")
- Achievement stars gamify consistency and create aspirational goals
- Minimal backend complexity (just Firestore, no custom cloud functions needed)
- Scales well (comments paginated, indexed queries)

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Approve Firestore schema** and security rules
3. **Start Phase 1** (layout redesign without comments)
4. **Test on real device** to ensure compact layout feels good
5. **Proceed to Phase 2** once layout approved
