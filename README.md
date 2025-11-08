# 🧘‍♀️ Meditation by VK

Cross-platform meditation app built with **Flutter** and **Firebase**.
Our goal: deliver a calm, high-performance experience that helps users meditate, track progress, and grow mindfulness — without technical chaos under the hood.

---

## 🚀 Overview

**Meditation by VK** is a modular, mobile-first meditation platform for iOS and Android (with optional web access).
It combines clean architecture, beautiful design, and a no-code content management system for easy scaling.

---

## 🧩 Core Features

- Guided and ambient meditation audio
- Guest mode and full account login
- Progress tracking (sessions, streaks, stats)
- Offline playback and caching
- Push notifications and streak reminders
- Premium subscriptions (RevenueCat)
- Admin web panel for content upload
- Marketing landing page for SEO and downloads

---

## 🏗️ Architecture

**Tech Stack**
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage, FCM)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Audio:** just_audio
- **Caching:** Hive (metadata) + device storage
- **Subscriptions:** RevenueCat
- **CI/CD:** GitHub Actions

**Clean Architecture Layout**
```
lib/
┣ core/          # constants, theme, utils
┣ data/          # repositories, datasources
┣ domain/        # entities, use cases
┣ presentation/  # UI, screens, widgets, providers
```

---

## 📚 Documentation Hierarchy

### 🎯 Start Here (MANDATORY READING)
1. **[CODE_FLOW.md](./CODE_FLOW.md)** - Complete system architecture map (READ FIRST)
   - Application initialization flow
   - Data pipelines and state management
   - Navigation and routing patterns
   - All major system interactions

2. **[APP_LOGIC.md](./APP_LOGIC.md)** - One-liner reference for every module (READ SECOND)
   - Quick lookup for any system/service
   - Concise descriptions of functionality
   - Complete module inventory

### 📋 Planning & Progress
- **[TASK.md](./TASK.md)** - Current implementation status, phase breakdown, todos
- **[PLANNING.md](./PLANNING.md)** - Architecture decisions, tech choices, rationale
- **[PHASE_0_BOOTSTRAP.md](./PHASE_0_BOOTSTRAP.md)** - Initial Flutter setup guide (95% complete)

### 🔧 Development Guides
- **[CLAUDE.md](./CLAUDE.md)** - Development rules, coding standards, workflow
- **[docs/architecture/Firebase.md](./docs/architecture/Firebase.md)** - Backend architecture, security rules
- **[meditation_by_vk/FIREBASE_SETUP.md](./meditation_by_vk/FIREBASE_SETUP.md)** - Emulator configuration
- **[docs/architecture/Theming.md](./docs/architecture/Theming.md)** - Theming system guide (presets, tinting, how-to add themes)

**⚠️ IMPORTANT**: CODE_FLOW.md and APP_LOGIC.md are the authoritative sources for understanding the codebase. All other documentation supplements these two core files.

---

## ✨ Recent Update (2025-10-29)

- Splash screen upgraded for a calmer, premium feel:
  - Animated gradient background with parallax blobs and sparse particles (`ZenBackground`)
  - Breathing glow behind the logo (`BreathingGlow`)
  - Subtle shimmer on title, staggered CTA entrance
  - All timings centralized in `SplashAnimationConfig` (`core/animation_constants.dart`)

---

## 🔁 Phase Roadmap

| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| **1. Foundation** | Architecture, Firebase setup, auth, navigation | Working skeleton app with dummy data |
| **2. Content System** | Admin panel, CMS, upload pipeline | No-code content management |
| **3. Core Features** | Audio player, progress tracking, offline cache | Full meditation experience |
| **4. Monetization** | Subscriptions, notifications, premium gates | Revenue-ready app |
| **5. Polish & Web** | Web version, SEO landing page, QA | Production-ready release |

Full details in [`PLANNING.md`](./PLANNING.md) and [`TASK.md`](./TASK.md).

---

## 🧱 Phase 1: Foundation — Current Focus

**Goal:** App opens, authenticates (guest or login), navigates through pages, and shows dummy meditations.

**Initial Tasks**
1. Initialize Flutter project and repo setup
2. Implement Clean Architecture folder structure
3. Connect Firebase (Auth, Firestore, Storage)
4. Add dependencies and configure pubspec
5. Create unified theme system (`theme.dart`)
6. Build bottom navigation with 4 tabs
7. Add authentication flow (guest, email, Google)
8. Display dummy meditation data

---

## ⚙️ Infrastructure & Admin

- Admin panel (Phase 2) allows uploads, image/audio management, and metadata editing.
- Uses Firebase Storage + Firestore with real-time sync.
- Modular CMS ensures no-code content updates.

---

## 🔒 Security & Rules

- User data isolation via Firebase Security Rules.
- Premium content gated by subscription status.
- Environment variables secured via `.env` and CI/CD secrets.

---

## 🧠 Performance Targets

| Metric | Target | Phase |
|--------|--------|-------|
| App launch | < 2s | 1 |
| Audio start | < 1s | 3 |
| Offline playback | Instant | 3 |
| Firebase queries | < 500ms | 2 |
| Screen transitions | < 300ms | 5 |

---

## 🧪 Testing & Deployment

- Unit + integration tests for all providers and critical flows
- Firebase Emulator Suite for local testing
- Staging via TestFlight / Play Console
- CI/CD with GitHub Actions (auto-build, version bump, rollout)

---

## 💡 Future Enhancements

- AI-personalized meditation suggestions
- Apple Watch / WearOS integration
- Corporate meditation programs
- Social sessions and challenges
- Year-in-review recap
- Advanced analytics with Mixpanel or Amplitude

---

## 🧑‍💻 Team Roles

- **Lead Developer:** You
- **Infra & CI/CD:** Claude
- **Architecture & System Design:** ChatGPT
- **Shared Goal:** Ship a modular, stable meditation app with calm user experience and zero production drama.

---

## 📄 License

TBD — private project under development.

---

### ✨ Status
> 🧱 **Phase 1: Foundation — In Progress**
>
> Docs ready, repo initialization next.
