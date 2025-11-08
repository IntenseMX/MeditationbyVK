# TAROT V2: AI-POWERED READINGS

**Status**: Future Feature (After Tarot V1 + Phase 5)
**Created**: 2025-11-05
**Estimated Timeline**: ~1 week implementation

---

## Overview

Upgrade tarot feature with AI-powered interpretations and credit-based economy. Users ask questions, draw cards, and receive personalized mystical interpretations from a custom LLM.

### Why This is Genius 🔥

**Engagement Loop**:
```
Meditate daily → Earn credits → Ask tarot question → Draw cards → AI interpretation → Want more → Meditate OR buy credits
```

**Differentiation**: NO meditation app has AI tarot readings. This is unique.

**Monetization**: Credit purchases = direct revenue stream

**Stickiness**: Personalized AI responses feel magical, users come back

---

## Credit System

### Credit Economy

**Earning Credits**:
- ✅ Complete meditation (10 minutes) = 1 credit
- ✅ Daily streak milestone (7 days) = 5 credits
- ✅ Weekly goal achieved = 3 credits
- ✅ Monthly goal achieved = 10 credits
- ✅ First-time user bonus = 5 free credits

**Spending Credits**:
- 1 credit = Draw 1 card + AI interpretation
- OR: 3 credits = Full 3-card spread with combined interpretation
- OR: 5 credits = Celtic Cross (10 cards, detailed interpretation)

**Purchasing Credits**:
- Small Pack: $2.99 = 10 credits
- Medium Pack: $4.99 = 20 credits (+bonus 2)
- Large Pack: $9.99 = 50 credits (+bonus 10)
- Monthly Subscription: $7.99 = 100 credits/month

### Database Changes

**Add to `users` collection**:
```
users/{userId}
├── credits: number           // Current credit balance
├── totalCreditsEarned: number
├── totalCreditsSpent: number
└── creditHistory: [          // Optional: track transactions
    {
      amount: number
      type: "earned" | "spent" | "purchased"
      source: "meditation" | "streak" | "purchase" | "reading"
      timestamp: timestamp
    }
  ]
```

**New collection: `creditTransactions`**
```
creditTransactions/{transactionId}
├── userId: string
├── amount: number            // Positive = earned, Negative = spent
├── type: "earned" | "spent" | "purchased"
├── source: string            // "meditation", "reading", "store"
├── metadata: object          // Extra context (meditationId, cardIds, etc.)
└── createdAt: timestamp
```

---

## ⚠️ CRITICAL: Anti-Cheat Required Before Launch

**Known Exploit**: Users can seek to 90% of meditation, get full credit without listening.

**Current System**: Awards credits based on position reached, not actual playback time.

**Must Fix Before V2 Launch**:
1. Track actual playback seconds (not position)
2. Detect suspicious seeking behavior (>1 min jumps)
3. Require 80% of track actually played (not just reached)
4. Server-side validation of play patterns

**Implementation**: ~50 lines in `audio_service.dart`, add `PlaybackValidator` class.

**DO NOT LAUNCH CREDITS WITHOUT THIS FIX** - Users will farm infinite credits by seeking.

*Note: Possible simple solution - leverage existing minute marker system (only increments during actual playback, not seeking). Award credits based on marker count rather than position. E.g., require 8+ minute markers written for 10-min track = ~1 line conditional.*

---

## Question-Based Reading Flow

### User Journey

1. **Enter Question**:
   ```
   ┌─────────────────────────┐
   │  Ask the Cards          │
   │                         │
   │  [Text Input]           │
   │  "What should I focus   │
   │   on this week?"        │
   │                         │
   │  Credits: 12            │
   │  Cost: 1 credit/card    │
   │                         │
   │  [Draw 1 Card]  (1 💎)  │
   │  [Draw 3 Cards] (3 💎)  │
   └─────────────────────────┘
   ```

2. **Draw Card(s)**:
   - Deduct credits
   - Shuffle animation
   - Reveal card(s) with flip animation

3. **AI Interpretation**:
   - Show loading spinner: "Reading the cards..."
   - Call LLM API with: question + card data
   - Display mystical interpretation
   - Show "Draw Another Card" option

4. **Progressive Drawing** (Key Feature):
   ```
   User draws Card 1 → AI interprets Card 1
   User draws Card 2 → AI RE-interprets Cards 1+2 together
   User draws Card 3 → AI RE-interprets all 3 cards in context
   ```

   **Example**:
   - Question: "Should I change jobs?"
   - Card 1: The Fool (new beginnings) → AI: "The cards suggest a leap of faith..."
   - User draws Card 2: Five of Pentacles (hardship)
   - AI: "However, The Fool paired with Five of Pentacles warns of financial uncertainty..."

---

## AI Integration Architecture

### LLM Provider Options

**Option 1: OpenAI GPT-4o-mini** (Recommended)
- Cost: $0.15 per 1M input tokens, $0.60 per 1M output tokens
- Response quality: Excellent
- Speed: ~2 seconds
- **Estimate**: ~500 tokens per reading = $0.0003/reading (insanely cheap)

**Option 2: Anthropic Claude 3.5 Haiku**
- Cost: $0.80 per 1M input tokens, $4 per 1M output tokens
- Response quality: Excellent, less hallucination
- Speed: ~1 second (faster)
- **Estimate**: ~$0.002/reading

**Option 3: Google Gemini Flash**
- Cost: Free tier available (15 requests/minute)
- Response quality: Good
- Speed: ~2 seconds
- **Estimate**: Free for low volume

**Recommendation**: Start with OpenAI GPT-4o-mini (dirt cheap + great quality)

### System Prompt Design

**Base System Prompt** (stored in app config):
```
You are a mystical tarot reader with deep knowledge of card meanings and symbolism.
Your interpretations are:
- Vague but meaningful
- Never too direct or prescriptive
- Reflective and thought-provoking
- 2-3 paragraphs maximum
- Use poetic, mystical language
- Always reference the specific cards drawn

Given a user's question and the drawn tarot cards, provide a reading that:
1. Acknowledges the question
2. Interprets each card in context
3. Weaves cards together into a cohesive message
4. Ends with gentle guidance, never commands

Tone: Wise, compassionate, mysterious
Length: 100-150 words per card drawn
```

### API Request Structure

**Single Card Reading**:
```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "[System prompt above]"
    },
    {
      "role": "user",
      "content": "Question: Should I change jobs?\n\nCards Drawn:\n1. The Fool (Upright)\n- Description: New beginnings, innocence, spontaneity\n- Upright Meaning: A leap of faith, starting fresh, unlimited potential\n\nProvide a mystical interpretation."
    }
  ],
  "temperature": 0.8,
  "max_tokens": 300
}
```

**Multi-Card Reading** (Progressive):
```json
{
  "role": "user",
  "content": "Question: Should I change jobs?\n\nCards Drawn:\n1. The Fool (Upright) - New beginnings, innocence\n2. Five of Pentacles (Reversed) - Recovery from hardship\n3. The Star (Upright) - Hope, renewal, inspiration\n\nInterpret all three cards together in relation to the question."
}
```

### Response Format

**AI Returns**:
```
The Fool appears before you, urging a bold step into the unknown. This card whispers of untapped potential and the courage to begin anew. Yet the Five of Pentacles, though reversed, reminds you that recovery from past struggles is still underway—financial stability may not yet be assured.

The Star crowns your reading with hope, suggesting that while change calls to you, patience and faith will illuminate the right path. The universe is aligning in your favor, but timing is everything. Trust the journey, even if the destination remains unclear.

Reflect deeply on what truly calls to your soul.
```

---

## Technical Implementation

### Services Layer

**New File**: `lib/services/ai_reading_service.dart`

```dart
class AIReadingService {
  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Generate interpretation for single card
  Future<String> interpretSingleCard({
    required String question,
    required TarotCard card,
    required bool isReversed,
  });

  // Generate interpretation for multiple cards
  Future<String> interpretMultipleCards({
    required String question,
    required List<DrawnCard> cards,
  });

  // Build prompt with system + user message
  String _buildPrompt(String question, List<DrawnCard> cards);

  // Call OpenAI API
  Future<String> _callLLM(String prompt);

  // Parse and validate response
  String _parseResponse(Map<String, dynamic> response);
}

class DrawnCard {
  final TarotCard card;
  final bool isReversed;
}
```

**New File**: `lib/services/credit_service.dart`

```dart
class CreditService {
  // Get user's current credit balance
  Future<int> getCreditBalance(String userId);

  // Add credits (earned or purchased)
  Future<void> addCredits(String userId, int amount, String source);

  // Deduct credits (for readings)
  Future<bool> deductCredits(String userId, int amount, String source);

  // Check if user has enough credits
  Future<bool> hasEnoughCredits(String userId, int required);

  // Get credit history
  Stream<List<CreditTransaction>> streamCreditHistory(String userId);

  // Award credits for meditation completion
  Future<void> awardMeditationCredits(String userId, int durationMinutes);

  // Award credits for streak milestones
  Future<void> awardStreakCredits(String userId, int streakDays);
}
```

### Providers Layer

**New File**: `lib/providers/credit_provider.dart`

```dart
// User's current credit balance
final creditBalanceProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(authProvider).value?.uid;
  if (userId == null) return Stream.value(0);
  return ref.watch(creditServiceProvider).streamCreditBalance(userId);
});

// Credit history
final creditHistoryProvider = StreamProvider<List<CreditTransaction>>((ref) {
  final userId = ref.watch(authProvider).value?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(creditServiceProvider).streamCreditHistory(userId);
});
```

**Update**: `lib/providers/tarot_provider.dart`

```dart
// Current reading state
final currentReadingProvider = StateProvider<ReadingState?>((ref) => null);

class ReadingState {
  final String question;
  final List<DrawnCard> cardsDrawn;
  final String? interpretation; // AI-generated
  final bool isLoading;
}

// Draw card with AI interpretation
final drawCardWithAIProvider = FutureProvider.family<String, DrawCardRequest>(
  (ref, request) async {
    // 1. Deduct credits
    final success = await ref.read(creditServiceProvider)
      .deductCredits(request.userId, 1, 'tarot_reading');

    if (!success) throw Exception('Insufficient credits');

    // 2. Draw random card
    final card = await ref.read(tarotServiceProvider).drawRandomCard();
    final isReversed = ref.read(tarotServiceProvider).isReversed();

    // 3. Get AI interpretation
    final interpretation = await ref.read(aiReadingServiceProvider)
      .interpretSingleCard(
        question: request.question,
        card: card,
        isReversed: isReversed,
      );

    // 4. Update reading state
    ref.read(currentReadingProvider.notifier).state = ReadingState(
      question: request.question,
      cardsDrawn: [DrawnCard(card, isReversed)],
      interpretation: interpretation,
      isLoading: false,
    );

    return interpretation;
  },
);
```

### Models Layer

**Update**: `lib/models/tarot_card.dart`

```dart
class DrawnCard {
  final TarotCard card;
  final bool isReversed;
  final DateTime drawnAt;
}

class ReadingSession {
  final String id;
  final String userId;
  final String question;
  final List<DrawnCard> cards;
  final String interpretation;
  final int creditsSpent;
  final DateTime createdAt;

  // Save to Firestore for history
}
```

**New File**: `lib/models/credit_transaction.dart`

```dart
class CreditTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type; // "earned", "spent", "purchased"
  final String source; // "meditation", "reading", "store"
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  factory CreditTransaction.fromDoc(DocumentSnapshot doc);
  Map<String, dynamic> toMap();
}
```

---

## UI/UX Implementation

### 1. Question Input Screen

**New File**: `lib/presentation/screens/tarot_question_screen.dart`

```
┌─────────────────────────────┐
│  ← Back                     │
│                             │
│  Ask the Cards              │
│                             │
│  ┌─────────────────────┐   │
│  │ What should I focus │   │
│  │ on this week?       │   │
│  │                     │   │
│  └─────────────────────┘   │
│                             │
│  💎 Credits: 12             │
│                             │
│  ┌─────────────────────┐   │
│  │ Draw 1 Card (1 💎)  │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ Draw 3 Cards (3 💎) │   │
│  └─────────────────────┘   │
│                             │
│  [Need more credits?]       │
└─────────────────────────────┘
```

### 2. Reading Screen with Progressive Drawing

**File**: `lib/presentation/screens/tarot_reading_screen.dart`

**Initial State** (question asked, no cards drawn):
```
┌─────────────────────────────┐
│  "Should I change jobs?"    │
│                             │
│  [Card Deck]                │
│  Tap to draw                │
│                             │
│  💎 Cost: 1 credit          │
└─────────────────────────────┘
```

**After Drawing Card 1**:
```
┌─────────────────────────────┐
│  "Should I change jobs?"    │
│                             │
│  ┌───────────┐             │
│  │           │             │
│  │ The Fool  │ (Upright)   │
│  │           │             │
│  └───────────┘             │
│                             │
│  "The Fool appears before   │
│   you, urging a bold step..." │
│                             │
│  ┌─────────────────────┐   │
│  │ Draw Another (1 💎) │   │
│  └─────────────────────┘   │
│                             │
│  [Save Reading]             │
└─────────────────────────────┘
```

**After Drawing Card 2** (re-interpretation):
```
┌─────────────────────────────┐
│  "Should I change jobs?"    │
│                             │
│  ┌────────┐  ┌────────┐    │
│  │ Fool   │  │ 5 of   │    │
│  │(Upright)│  │Pent.   │    │
│  └────────┘  └────────┘    │
│                             │
│  "The Fool paired with the  │
│   Five of Pentacles warns   │
│   of financial uncertainty..."│
│                             │
│  ┌─────────────────────┐   │
│  │ Draw Another (1 💎) │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### 3. Credit Purchase Screen

**New File**: `lib/presentation/screens/credit_store_screen.dart`

```
┌─────────────────────────────┐
│  Get More Credits           │
│                             │
│  Current Balance: 12 💎     │
│                             │
│  ┌─────────────────────┐   │
│  │ SMALL PACK          │   │
│  │ 10 Credits          │   │
│  │ $2.99               │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ MEDIUM PACK  ⭐     │   │
│  │ 20 + 2 Bonus        │   │
│  │ $4.99               │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ LARGE PACK  🔥      │   │
│  │ 50 + 10 Bonus       │   │
│  │ $9.99   BEST VALUE  │   │
│  └─────────────────────┘   │
│                             │
│  [Monthly Pass: $7.99/mo]  │
│  Unlimited readings         │
└─────────────────────────────┘
```

### 4. Credit Notifications

**Earn Credits Popup**:
```
┌─────────────────┐
│  ✨ Earned!     │
│                 │
│  +1 Credit 💎   │
│                 │
│  Completed 10   │
│  minute session │
└─────────────────┘
```

**Insufficient Credits**:
```
┌─────────────────────┐
│  Not Enough Credits │
│                     │
│  You need 1 💎      │
│  Balance: 0 💎      │
│                     │
│  [Get Credits]      │
│  [Cancel]           │
└─────────────────────┘
```

---

## Credit Earning Integration

### Hook into Progress Tracking

**Update**: `lib/services/progress_service.dart`

```dart
// After session completion
Future<void> upsertSession(...) async {
  // ... existing code ...

  if (completed && durationSec >= 600) { // 10+ minutes
    // Award 1 credit
    await ref.read(creditServiceProvider).addCredits(
      uid,
      1,
      'meditation_completed',
    );

    // Show notification
    _showCreditEarnedNotification(1);
  }
}
```

### Streak Milestone Credits

**Update**: `lib/providers/progress_provider.dart`

```dart
// When calculating streaks
final streaks = svc.calculateStreak(sessions);

// Check for milestone achievements
if (streaks.current == 7) {
  await ref.read(creditServiceProvider).awardStreakCredits(userId, 7);
  // Show: "🎉 7-day streak! +5 credits"
}
```

---

## Firestore Security Rules

**Add to**: `firestore.rules`

```javascript
// Credit transactions - users can only read their own
match /creditTransactions/{transactionId} {
  allow read: if request.auth != null &&
              resource.data.userId == request.auth.uid;
  allow write: if false; // Only server/admin can write
}

// Users collection - protect credit balance
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow update: if request.auth.uid == userId &&
                   // Cannot modify credits directly (server-side only)
                   !request.resource.data.diff(resource.data).affectedKeys().hasAny(['credits']);
}

// Reading history
match /readings/{readingId} {
  allow read: if request.auth != null &&
              resource.data.userId == request.auth.uid;
  allow create: if request.auth != null &&
                request.resource.data.userId == request.auth.uid;
}
```

---

## API Key Management

### Environment Variables

**Add to**: `lib/config/env.dart`

```dart
class Env {
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  // Alternative: Store in Firebase Remote Config for dynamic updates
}
```

**Build Command**:
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-...
flutter build apk --dart-define=OPENAI_API_KEY=sk-...
```

**Security**: Never commit API key to repo. Use environment variables or Firebase Remote Config.

---

## Cost Analysis

### LLM Costs (OpenAI GPT-4o-mini)

**Per Reading**:
- Input: ~400 tokens (system prompt + question + card data)
- Output: ~150 tokens (interpretation)
- **Cost**: ~$0.0003 per reading

**At Scale**:
- 1,000 readings/day = $0.30/day = $9/month
- 10,000 readings/day = $3/day = $90/month
- 100,000 readings/day = $30/day = $900/month

**With Credit System**:
- User pays 1 credit ($0.30 if purchased) for reading costing $0.0003
- **Profit margin**: ~99.9% on credit purchases (insane)

### Alternative: Free Tier Start

**Use Gemini Flash** (15 free requests/min):
- 0 cost until hitting scale
- Switch to OpenAI when >20K readings/day

---

## Monetization Strategy

### Credit Pricing Psychology

**Make meditation credits FEEL valuable but attainable**:
- 10 min meditation = 1 credit (feels earned)
- 1 reading = 1 credit (feels fair)
- Store purchases = bonus credits (feels generous)

**Encourage Daily Engagement**:
```
Meditate 10 min → Earn 1 credit → Do 1 reading
Want more readings? Either:
  - Meditate more (engagement ↑)
  - Buy credits (revenue ↑)
```

**Monthly Subscription**:
- $7.99/month = Unlimited readings + premium meditations
- Target: Users doing >8 readings/month (break-even)
- Reality: Most do 2-3, you win

---

## Progressive Enhancement Roadmap

### V2.1: Basic AI Readings (MVP)
- [x] Single card drawing with AI interpretation
- [x] Credit earning from meditations
- [x] Credit purchase store
- [x] Question input

### V2.2: Multi-Card Spreads
- [ ] Progressive drawing (1 card, then 2, then 3)
- [ ] AI re-interprets all cards together
- [ ] Visual card layout (side-by-side)

### V2.3: Pre-Defined Spreads
- [ ] 3-Card Spread (Past, Present, Future)
- [ ] Celtic Cross (10 cards)
- [ ] Relationship Spread (2-person readings)

### V2.4: Reading History & Journaling
- [ ] Save all readings to Firestore
- [ ] View past readings
- [ ] Add personal notes/reflections
- [ ] Share readings (anonymously)

### V2.5: Subscription Perks
- [ ] Unlimited readings for subscribers
- [ ] Longer AI interpretations (premium)
- [ ] Voice readings (text-to-speech)
- [ ] Priority support

---

## Edge Cases & Considerations

### Rate Limiting
- **Problem**: User spams API, costs spike
- **Solution**: Max 10 readings per hour per user
- **Implementation**: Track timestamps in Firestore

### AI Hallucinations
- **Problem**: GPT invents card meanings
- **Solution**: Strict system prompt + validation
- **Implementation**: Pass EXACT card descriptions, constrain output

### Insufficient Credits
- **Problem**: User tries to draw without credits
- **Solution**: Show paywall before drawing
- **Implementation**: Check balance, show store if insufficient

### Offline Mode
- **Problem**: Can't call LLM offline
- **Solution**: Require internet for AI readings
- **Implementation**: Detect connectivity, show error

### Inappropriate Questions
- **Problem**: Users ask harmful/illegal questions
- **Solution**: Content moderation layer
- **Implementation**: OpenAI moderation API (free) before sending prompt

---

## Testing Strategy

### Manual Testing Checklist
- [ ] Earn credits from meditation completion
- [ ] Purchase credits from store
- [ ] Draw single card with AI interpretation
- [ ] Draw multiple cards (progressive)
- [ ] Insufficient credits flow
- [ ] Question character limits
- [ ] AI response quality (vague but meaningful)
- [ ] Credit deduction accuracy
- [ ] Reading history saves correctly

### API Testing
- [ ] OpenAI API key valid
- [ ] Prompt generates quality responses
- [ ] Error handling (API down, rate limit)
- [ ] Response parsing correct
- [ ] Token usage within budget

### Load Testing (Pre-Launch)
- [ ] 100 concurrent readings
- [ ] API rate limits respected
- [ ] Credit transactions atomic (no double-spend)
- [ ] Firestore writes don't spike costs

---

## Success Metrics

### Engagement KPIs
- Credits earned per user per week (target: 5+)
- Readings performed per user per week (target: 2+)
- Return rate after first reading (target: 60%+)

### Revenue KPIs
- Credit purchase conversion rate (target: 5%+)
- Average purchase value (target: $4.99)
- Monthly recurring revenue from subscriptions (target: $500+ by month 3)

### Technical KPIs
- AI response time < 3 seconds
- AI interpretation quality rating (user feedback: 4+/5)
- Credit transaction success rate (target: 99.9%+)
- LLM cost per reading < $0.001

---

## Implementation Timeline

**Week 1: Credit System Foundation**
- Day 1-2: Credit service, Firestore schema
- Day 3: Credit earning from meditations
- Day 4: Credit store UI
- Day 5: Purchase flow (in-app purchases)

**Week 2: AI Reading Core**
- Day 1: OpenAI integration
- Day 2: System prompt engineering
- Day 3: Question input UI
- Day 4: Single card reading flow
- Day 5: Testing + prompt refinement

**Week 3: Multi-Card & Polish**
- Day 1-2: Progressive drawing logic
- Day 3: Multi-card AI interpretation
- Day 4: Reading history
- Day 5: Bug fixes + optimization

**Total**: ~3 weeks for V2 complete

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| OpenAI costs spike | High | Set daily spending cap, monitor usage |
| AI generates bad readings | Medium | Strict prompt, user feedback loop |
| Users game credit system | Medium | Rate limits, server-side validation |
| In-app purchase issues | High | Thorough testing, RevenueCat handles receipts |
| API key leak | High | Environment variables, never commit to repo |

---

## Related Files (Future Implementation)

```
lib/
├── models/
│   ├── credit_transaction.dart      # NEW
│   └── reading_session.dart         # NEW
├── services/
│   ├── ai_reading_service.dart      # NEW
│   ├── credit_service.dart          # NEW
│   └── tarot_service.dart           # UPDATE (add credit checks)
├── providers/
│   ├── credit_provider.dart         # NEW
│   └── tarot_provider.dart          # UPDATE (integrate AI)
└── presentation/
    └── screens/
        ├── tarot_question_screen.dart    # NEW
        ├── tarot_reading_screen.dart     # UPDATE
        ├── credit_store_screen.dart      # NEW
        └── reading_history_screen.dart   # NEW
```

**Firestore Collections**:
```
users/{userId}
  - credits (new field)

creditTransactions/{transactionId}  (new)

readings/{readingId}                (new)
```

**Firebase Functions** (optional for server-side credit awards):
```
functions/
└── src/
    └── creditRewards.ts  # Award credits on meditation complete
```

---

## Notes

**DO NOT implement until Tarot V1 is complete and tested.**

This is a massive feature with:
- AI integration (new complexity)
- In-app purchases (revenue critical)
- Credit economy (potential exploits)

**Requires careful testing before launch.**

But the engagement + monetization potential is INSANE 🔥

---

## Final Thoughts

This feature transforms tarot from "fun gimmick" into **core engagement driver**:

1. Users meditate daily → Earn credits
2. Credits unlock AI readings → Personalized magic
3. Want more → Buy credits OR meditate more
4. AI responses → Feel personal → Users return

**Differentiation**: No competitor has this. Meditation + AI Tarot = unique.

**Monetization**: Credit purchases = direct revenue with 99%+ margin.

**Engineering**: Reuses existing systems + adds one API integration.

This could be the feature that makes the app go viral 😈⚔️
