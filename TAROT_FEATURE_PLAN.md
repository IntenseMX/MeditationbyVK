# TAROT FEATURE PLAN

**Status**: Future Feature (Post Phase 5)
**Created**: 2025-11-05
**Estimated Timeline**: ~2 days implementation

---

## Overview

Add tarot card reading feature as a separate page in the app. Users can draw random cards from a deck with shuffle animation and view card meanings.

### User Flow
1. User navigates to Tarot page
2. Sees visual deck of cards (stacked)
3. Clicks deck OR selects specific card from spread
4. Shuffle animation plays
5. Random card revealed with flip animation
6. Modal displays card image + meaning (upright/reversed)

### Why This Feature?
- **Differentiation**: Most meditation apps don't have tarot
- **Engagement**: Daily card reading increases retention
- **Synergy**: Fits wellness/mindfulness niche perfectly
- **Technical**: Reuses existing upload/storage/streaming architecture

---

## Database Structure

### New Collection: `tarotCards`

```
tarotCards/{cardId}
├── name: string              // "The Fool", "Ace of Cups"
├── description: string       // General card meaning
├── upright: string          // Meaning when card upright
├── reversed: string         // Meaning when card reversed
├── imageUrl: string         // Firebase Storage URL
├── suit: string             // "major" | "cups" | "wands" | "swords" | "pentacles"
├── order: number            // 0-77 for full 78-card deck
├── status: string           // "published" | "draft"
├── createdAt: timestamp
└── updatedAt: timestamp
```

### User Collection Addition (Optional)

```
users/{userId}
└── lastCardDrawn: {
    cardId: string
    drawnAt: timestamp
    isReversed: boolean
}
```

**Purpose**: Track last card drawn for "daily card" feature (one draw per day)

---

## Admin Panel Changes

### New Page: Tarot Card Editor

**Location**: Similar to Meditation Editor in admin section

**Features**:
- ✅ Upload card image (Firebase Storage)
- ✅ Text fields: name, description, upright meaning, reversed meaning
- ✅ Dropdown: suit selection (Major Arcana, Cups, Wands, Swords, Pentacles)
- ✅ Order number (for deck sorting)
- ✅ Status: Published/Draft
- ✅ Preview card before publishing
- ✅ List view of all cards with search/filter

**Reuses**:
- `StorageService.uploadImage()` (already built)
- `ImagePickerButton` widget (already built)
- CRUD pattern from `MeditationEditor`
- Firestore batch operations

### Firestore Security Rules

```javascript
match /tarotCards/{cardId} {
  // Anyone can read published cards
  allow read: if resource.data.status == 'published';

  // Only admins can write
  allow write: if isAdmin();
}
```

---

## User-Facing UI

### New Screen: `tarot_screen.dart`

**Layout**:
```
┌─────────────────────────┐
│   Daily Tarot Reading   │
│                         │
│     [Card Deck]         │ ← Stack of cards visual
│                         │
│  "Tap to draw a card"   │
│                         │
│  [Your last reading]    │ ← Shows previous card
└─────────────────────────┘
```

### Card Deck Component

**Visuals**:
- Stacked cards (3D perspective)
- Slight rotation/offset for depth
- Glow/shadow effects
- Tap/click interaction

**States**:
1. **Idle**: Deck waiting for interaction
2. **Shuffling**: Animated shuffle effect (Lottie or CSS)
3. **Drawing**: Single card slides out
4. **Revealing**: Card flip animation (front → back)

### Card Reveal Modal

**Content**:
- Full card image
- Card name (large heading)
- Orientation indicator: "Upright" or "Reversed"
- Meaning text (scrollable)
- "Draw Another" button
- "Save to History" button (optional)

**Animation**: Fade in with scale effect

---

## Technical Implementation

### Services Layer

**New File**: `lib/services/tarot_service.dart`

```dart
class TarotService {
  // Fetch all published cards
  Stream<List<TarotCard>> streamPublishedCards()

  // Get random card
  Future<TarotCard> drawRandomCard()

  // Determine if card is reversed (50% chance)
  bool isReversed()

  // Save user's last drawn card
  Future<void> saveLastDrawing(String userId, TarotCard card, bool reversed)

  // Get user's last drawn card
  Future<LastDrawing?> getLastDrawing(String userId)
}
```

### Providers Layer

**New File**: `lib/providers/tarot_provider.dart`

```dart
// Stream all tarot cards
final tarotCardsProvider = StreamProvider<List<TarotCard>>((ref) {
  return ref.watch(tarotServiceProvider).streamPublishedCards();
});

// Current drawn card state
final drawnCardProvider = StateProvider<DrawnCardState?>((ref) => null);

// Last drawing for current user
final lastDrawingProvider = FutureProvider<LastDrawing?>((ref) {
  final userId = ref.watch(authProvider).value?.uid;
  if (userId == null) return Future.value(null);
  return ref.watch(tarotServiceProvider).getLastDrawing(userId);
});
```

### Models Layer

**New File**: `lib/models/tarot_card.dart`

```dart
class TarotCard {
  final String id;
  final String name;
  final String description;
  final String upright;
  final String reversed;
  final String imageUrl;
  final String suit;
  final int order;

  // fromJson, toJson, copyWith
}

class DrawnCardState {
  final TarotCard card;
  final bool isReversed;
  final DateTime drawnAt;
}
```

### Animations

**Shuffle Animation**:
- Option 1: Lottie JSON file (find free tarot shuffle animation)
- Option 2: Custom Flutter animation (cards moving/rotating)
- Duration: ~1.5 seconds

**Card Flip Animation**:
- `AnimatedSwitcher` or `TweenAnimationBuilder`
- 3D rotation effect (RotationY)
- Duration: ~0.8 seconds

**Reveal Modal**:
- Fade in with scale: `ScaleTransition` + `FadeTransition`
- Duration: ~0.5 seconds

---

## Navigation Integration

### Add to Bottom Nav Bar (Optional)

```
Home | Discover | Tarot | Progress | Profile
```

OR

### Add as Section on Home Screen

```
- Continue Listening
- Trending Now
- Daily Tarot ← New section
- Recommended
```

**Recommendation**: Start with home screen section, upgrade to full nav tab if popular

---

## Data Requirements

### Tarot Deck Composition

**Full 78-card deck**:
- 22 Major Arcana (The Fool through The World)
- 56 Minor Arcana:
  - 14 Cups (Ace through King)
  - 14 Wands (Ace through King)
  - 14 Swords (Ace through King)
  - 14 Pentacles (Ace through King)

### Content Needs

**Per Card**:
- High-quality image (512x1024px recommended, portrait orientation)
- Card name
- General description (~100 words)
- Upright meaning (~150 words)
- Reversed meaning (~150 words)

**Total Content**: ~78 images + ~78 × 400 words = substantial content creation

**Suggestion**: Start with Major Arcana only (22 cards) for MVP, expand later

---

## Implementation Phases

### Phase 1: Backend & Admin (~4 hours)
- [x] Database schema
- [ ] Firestore security rules
- [ ] `TarotService` implementation
- [ ] Admin editor page (clone MeditationEditor)
- [ ] Upload first test card

### Phase 2: User UI (~4 hours)
- [ ] `TarotScreen` widget
- [ ] Card deck visual component
- [ ] Random selection logic
- [ ] Basic reveal (no animations yet)

### Phase 3: Animations & Polish (~4 hours)
- [ ] Shuffle animation
- [ ] Card flip animation
- [ ] Reveal modal styling
- [ ] Loading states
- [ ] Error handling

### Phase 4: Enhancement (~2 hours)
- [ ] Save last drawing to user profile
- [ ] "One card per day" restriction (optional)
- [ ] Card history page (optional)
- [ ] Share card feature (optional)

**Total**: ~14 hours = ~2 days at current pace

---

## Edge Cases & Considerations

### Card Reversal Logic
- **Reversed**: 180° rotation, different meaning
- **Implementation**: Random boolean on draw (50% chance)
- **Visual**: Show card upside down in reveal

### Daily Limit (Optional)
- Users can only draw one card per 24 hours
- Store `lastDrawnAt` timestamp
- Show countdown timer until next draw
- **Purpose**: Increase daily return rate

### Offline Support
- Cache card images (same as meditation covers)
- Store deck data locally
- Allow drawing cards offline
- Sync last drawing when online

### Premium Feature?
- Free: Major Arcana only (22 cards)
- Premium: Full deck (78 cards) + card history
- **Alternative**: Keep entirely free as engagement hook

---

## Design Notes

### Visual Style
- Match meditation app aesthetic (calm, minimal)
- Card back design: Mystical but not cheesy
- Color scheme: Deep purples, golds, cosmic theme
- Typography: Elegant serif for card names

### Card Imagery
- **Source**: Public domain tarot (Rider-Waite or similar)
- **OR**: Commission custom illustrations matching app style
- **License**: Ensure commercial use allowed

### Accessibility
- Screen reader support for card meanings
- High contrast mode for card visuals
- Font size adjustments for text

---

## Future Enhancements (Post-Launch)

1. **Multi-card Spreads**: Celtic Cross, Three-Card, etc.
2. **Journaling**: Let users write reflections on readings
3. **Card of the Day**: Push notification with daily card
4. **Guided Interpretations**: Audio explanations of cards
5. **Community**: Share readings (anonymously)
6. **Learning Mode**: Study deck, quiz on meanings

---

## Success Metrics

**Engagement KPIs**:
- Daily card draw rate (target: 40% of DAU)
- Time spent on tarot page (target: 2+ minutes)
- Return rate (target: 60% draw again next day)

**Technical KPIs**:
- Card image load time < 1 second
- Animation smoothness 60 FPS
- Zero crashes on card draw

---

## Notes

- **Architecture**: Reuses 90% of existing meditation upload/display system
- **Complexity**: Low - mostly UI/animation work
- **Value**: High differentiation vs competitors
- **Timeline**: Can ship in parallel with Phase 4/5 if desired

**DO NOT implement until Phase 5 complete.** Focus on core meditation features first.

---

## Related Files (Future Implementation)

```
lib/
├── models/
│   └── tarot_card.dart          # NEW
├── services/
│   └── tarot_service.dart       # NEW
├── providers/
│   └── tarot_provider.dart      # NEW
└── presentation/
    └── screens/
        ├── tarot_screen.dart    # NEW
        └── admin/
            └── tarot_editor_screen.dart  # NEW
```

**Firestore**:
```
firestore.rules              # Add tarotCards rules
```

**Assets** (future):
```
assets/
├── animations/
│   └── card_shuffle.json    # Lottie animation
└── images/
    └── card_back.png        # Default card back design
```
