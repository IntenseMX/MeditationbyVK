# Firebase Architecture - Meditation by VK

Last Updated: 2025-11-16

## Overview

Firebase provides the complete backend infrastructure for Meditation by VK, handling authentication, data storage, file storage, and analytics.

## Development Mode (2025-10-22)

### Emulator Setup
Emulator-first workflow during Phase 1.5:
- Env flag: `EnvConfig.useEmulator = true` (set via `--dart-define=USE_EMULATOR=true`)
- Ports: Auth 9099, Firestore 8080, Storage 9199, UI 4000
- Initialization handled in `main.dart` after `Firebase.initializeApp()` using `useAuthEmulator`, `useFirestoreEmulator`, and `useStorageEmulator`
- Web config set in `lib/firebase_options.dart` (measurementId included; Analytics disabled in dev)

### Storage Bucket Configuration
**IMPORTANT**: Use modern `.firebasestorage.app` bucket (not legacy `.appspot.com`):
```dart
// lib/firebase_options.dart
storageBucket: 'meditation-by-vk-89927.firebasestorage.app',  // ✅ Modern
// NOT: 'meditation-by-vk-89927.appspot.com'                   // ❌ Legacy
```

### CORS Configuration (2025-10-22)
Localhost uploads require CORS setup on Firebase Storage bucket:

**One-time setup via Google Cloud SDK:**
```bash
# Install gcloud CLI, then:
gcloud auth login
gcloud config set project meditation-by-vk-89927

# Create cors.json:
[
  {
    "origin": ["http://localhost:*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600
  }
]

# Apply:
gsutil cors set cors.json gs://meditation-by-vk-89927.firebasestorage.app
```

### Admin Access (2025-10-22)
Admin functionality requires custom claims set in Firebase Console:

1. Firebase Console → Authentication → Users → Select user
2. Edit "Custom claims" → Set: `{"admin": true}`
3. User must sign out and re-authenticate for claims to take effect
4. Verified in `auth_provider.dart:47`: `token.claims?["admin"] == true`

**Note**: Admin claims cannot be checked in browser console (Flutter/Dart environment, not JavaScript).

## Services Used

### 1. Firebase Authentication
- **Email/Password**: Traditional authentication
- **Google Sign-In**: One-tap authentication
- **Anonymous Auth**: Guest mode support
- **Apple Sign-In**: iOS users (future)

### 2. Cloud Firestore
- **Database**: NoSQL document database
- **Real-time**: Live updates across devices
- **Offline**: Automatic offline support
- **Security**: Row-level security rules

### 3. Cloud Storage
- **Audio Files**: Meditation audio storage
- **Cover Images**: Meditation artwork
- **CDN**: Global content delivery
- **Security**: Signed URLs for premium content

### 4. Firebase Analytics
- **User Behavior**: Track engagement
- **Conversion**: Guest to paid tracking
- **Custom Events**: Meditation completion, etc.
- **Audiences**: User segmentation

## Database Structure

```
firestore-root/
├── users/{userId}
│   ├── email: string
│   ├── displayName: string
│   ├── photoUrl: string?
│   ├── isGuest: boolean
│   ├── isPremium: boolean
│   ├── subscriptionExpiry: timestamp?
│   ├── createdAt: timestamp
│   ├── lastActive: timestamp
│   ├── achievements: map<string, timestamp>   // e.g. "streak_5": timestamp
│   ├── preferences: {
│   │   ├── theme: 'light' | 'dark' | 'system'
│   │   ├── autoplay: boolean
│   │   ├── notifications: boolean
│   │   └── downloadQuality: 'high' | 'medium' | 'low'
│   │   }
│   ├── stats: {
│   │   ├── totalSessions: number
│   │   ├── totalMinutes: number
│   │   ├── currentStreak: number
│   │   ├── longestStreak: number
│   │   ├── weeklyGoal: number
│   │   └── lastSessionDate: timestamp
│   │   }
│   └── favorites/{meditationId}
│       └── addedAt: timestamp
│
├── meditations/{meditationId}
│   ├── title: string
│   ├── description: string
│   ├── instructor: string?
│   ├── duration: number (seconds)
│   ├── audioUrl: string (Cloud Storage URL)
│   ├── coverImageUrl: string
│   ├── thumbnailUrl: string
│   ├── categories: string[]
│   ├── tags: string[]
│   ├── difficulty: 'beginner' | 'intermediate' | 'advanced'
│   ├── isPremium: boolean
│   ├── isDownloadable: boolean
│   ├── language: string
│   ├── createdAt: timestamp
│   ├── publishedAt: timestamp
│   ├── stats: {
│   │   ├── playCount: number
│   │   ├── completionCount: number
│   │   ├── averageRating: number
│   │   └── ratingCount: number
│   │   }
│   └── relatedMeditations: string[]
│
├── categories/{categoryId}
│   ├── name: string
│   ├── description: string
│   ├── icon: string
│   ├── color: string
│   ├── order: number
│   ├── imageUrl: string
│   └── meditationCount: number
│
├── userProgress/{userId}/sessions/{sessionId}
│   ├── meditationId: string
│   ├── meditationTitle: string? (denormalized at write, used for Today's Sessions list)
│   ├── startedAt: timestamp (UTC, captured on first playing transition; persists across app restarts)
│   ├── completedAt: timestamp (UTC, serverTimestamp on upsert; set on all upserts, authoritative at finalize)
│   ├── duration: number (absolute seconds listened; updated progressively every minute with base + position)
│   ├── completed: boolean (set true once at finalization if total ≥ 90% of single track)
│   └── sessionId format: "{uid}_{meditationId}_{startedAtMsUtc}" (deterministic)
│
├── playlists/{playlistId}
│   ├── name: string
│   ├── description: string
│   ├── ownerId: string
│   ├── isPublic: boolean
│   ├── coverImageUrl: string
│   ├── meditations: string[]
│   ├── followerCount: number
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
└── featuredContent/
    ├── daily/{date}
    │   └── meditationId: string
    ├── trending/
    │   └── meditations: string[]
    └── collections/{collectionId}
        ├── name: string
        ├── meditations: string[]
        └── order: number
```

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isPremium() {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isPremium == true;
    }

    // Users can read/write their own data
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);

      match /favorites/{meditationId} {
        allow read, write: if isOwner(userId);
      }
    }

    // Meditations - public read (published), admin can read all; writes via admin panel
    match /meditations/{meditationId} {
      allow read: if resource.data.status == 'published' || (isAuthenticated() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.admin == true);
      allow write: if false; // Admin SDK or secured admin panel only
    }

    // Categories - public read
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if false; // Admin SDK only
    }

    // User progress - private
    match /userProgress/{userId}/sessions/{sessionId} {
      allow read, write: if isOwner(userId);
    }
    // Note: Sessions subcollection requires composite index: completed ASC, completedAt DESC (deployed as COLLECTION_GROUP)

    // Featured content - public read
    match /featuredContent/{document=**} {
      allow read: if true;
      allow write: if false; // Admin SDK only
    }
  }
}
```

## Storage Structure

```
storage-root/
├── meditations/
│   ├── audio/
│   │   ├── {meditationId}.mp3  (high quality)
│   │   ├── {meditationId}_medium.mp3
│   │   └── {meditationId}_low.mp3
│   ├── covers/
│   │   ├── {meditationId}_full.jpg
│   │   └── {meditationId}_thumb.jpg
│   └── downloads/  (premium only)
│       └── {meditationId}_offline.mp3
│
├── users/
│   └── {userId}/
│       └── profile.jpg
│
└── app/
    ├── categories/
    │   └── {categoryId}.svg
    └── defaults/
        ├── meditation_cover.jpg
        └── user_avatar.jpg
```

## Cloud Functions (Future)

```typescript
// Potential Cloud Functions to implement

// Triggered when user completes a session
export const onSessionComplete = functions.firestore
  .document('userProgress/{userId}/sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    // Update user stats
    // Calculate streaks
    // Check achievements
  });

// Daily cron to update featured content
export const updateDailyMeditation = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    // Select daily meditation
    // Update trending
  });

// Handle subscription changes
export const onSubscriptionChange = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    // Handle premium status changes
    // Update access permissions
  });
```

## Performance Optimization

### Indexes
Current indexes (Phase 3C - 2025-11-05):
- `meditations`: status ASC + playCount DESC (for Trending)
- `meditations`: status ASC + publishedAt DESC/ASC (for Recently Added/Recommended)
- `meditations`: status ASC + createdAt DESC (for Category filtering with creation order)
- `sessions` (COLLECTION_GROUP): completed ASC + completedAt DESC (for progress queries)

Future composite indexes if server-side filtering expands:
- `meditations`: status + categoryId + isPremium
- `meditations`: status + publishedAt (already exists)

### Caching Strategy
- Enable offline persistence in Firebase SDK
- Cache audio URLs for 24 hours
- Preload next meditation in queue
- Store user preferences locally

### Query Optimization
- Limit queries to 20 items
- Use pagination for large lists
- Denormalize frequently accessed data
- Avoid deep subcollection queries

## Migration Strategy

### From Guest to Authenticated
1. Create account with email/Google
2. Link anonymous account to new credentials
3. Preserve all progress and favorites
4. Update userId references

### Data Import (Admin)
1. Batch upload meditations via Admin SDK
2. Process audio files through Cloud Functions
3. Generate thumbnails automatically
4. Update search indexes

## Monitoring

### Key Metrics
- Firestore reads/writes per day
- Storage bandwidth usage
- Authentication success rate
- Average query latency

### Alerts
- Budget threshold reached (80%)
- Authentication failures spike
- Firestore errors increase
- Storage quota approaching

## Cost Management

### Free Tier Limits
- Authentication: 10K/month
- Firestore: 50K reads, 20K writes/day
- Storage: 5GB stored, 1GB/day download
- Functions: 125K invocations/month

### Cost Optimization
- Use Firebase local emulator for development
- Implement client-side caching
- Optimize image sizes
- Use CDN for static assets

## Backup Strategy

- Daily Firestore exports to Cloud Storage
- Weekly full backups
- Point-in-time recovery enabled
- Test restore process monthly

## Achievements (2025-11-10)

### Overview
- Achievements are stored on `users/{uid}.achievements` as a `map<string, timestamp>`.
- Keys represent unlocked milestones; values are the unlock time (serverTimestamp at write).

### Keys
- Streaks: `streak_5`, `streak_10`, `streak_30`
- Sessions: `sessions_5`, `sessions_25`, `sessions_50`
- Minutes: `minutes_50`, `minutes_100`, `minutes_300`

### Awarding
- Client-side in `progressDtoProvider` for simplicity and immediate UI feedback.
- Idempotent write: only sets keys that do not yet exist using `update({ 'achievements.key': serverTimestamp() })`.
- Reads are lightweight (single user doc snapshot already used for `dailyGoldGoal`).

### Security
- Covered by existing rule: users can write their own `users/{uid}` document.