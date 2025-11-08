# Phase 1.5: Infrastructure

**Created:** 2025-10-18

---

## 🎯 Phase 1.5 Goal

**Transform static prototype into working foundation.**

**Deliverable:** Firebase connected, auth working, player screen exists, can test real data flow.

---

## 📋 Phase 1.5 Tasks (2-3 hours)

### **Task 1: Java Installation** (10 mins)
**Check if installed:**
```bash
java -version
```

**If not installed:**
- **macOS:** `brew install openjdk@11`
- **Windows:** Download from oracle.com/java/technologies/downloads
- **Linux:** `sudo apt install openjdk-11-jdk`

---

### **Task 2: Firebase Project Setup** (15 mins)
**Go to:** https://console.firebase.google.com/

1. Find/create project "meditation-by-vk"
2. Enable services:
   - ✅ Authentication (Email, Google, Anonymous)
   - ✅ Firestore Database (test mode)
   - ✅ Cloud Storage (test mode)
3. Add Web app → copy config values
4. Paste into `lib/firebase_options.dart`

---

### **Task 3: Firebase Emulator Init** (10 mins)
```bash
cd meditation_by_vk
firebase init emulators
```
Select:
- Authentication Emulator (port 9099)
- Firestore Emulator (port 8080)
- Storage Emulator (port 9199)

---

### **Task 4: Start Emulators** (2 mins)
```bash
firebase emulators:start
```
Verify at: http://localhost:4000

---

### **Task 5: Auth Service Layer** (30 mins)
**Create:**
- `lib/services/auth_service.dart` - Firebase Auth wrapper
- `lib/providers/auth_provider.dart` - Riverpod state
- Guest mode implementation (anonymous auth)
- Simple bypass flow (no login UI yet, just auto-guest)

---

### **Task 6: Player Screen** (45 mins)
**Create:**
- `lib/presentation/screens/player_screen.dart`
- Meditation header (image, title, description)
- Dummy play/pause button
- Progress slider (non-functional)
- Navigation from meditation card tap

---

### **Task 7: Firebase Connection Test** (15 mins)
**Add:**
- Test auth connection (create anonymous user)
- Test Firestore write (save dummy progress)
- Console logs to verify emulator connection
- Error handling

---

### **Task 8: Update Docs** (5 mins)
**Update TASK.md:**
```markdown
✅ Phase 1: UI Foundation (COMPLETE)
✅ Phase 1.5: Infrastructure (COMPLETE on 2025-10-19)
⏳ Phase 2: Content System (NEXT)
```

---

## 🚀 Execution Plan

**You do tasks 1-4 (environment setup), Claude does tasks 5-8 (coding).**

### **Your tasks first (30-40 mins):**
1. Install Java
2. Create/configure Firebase project
3. Initialize emulators
4. Start emulators

**Once you complete those, say "emulators running" and Claude will:**
1. Create auth service + provider
2. Build player screen
3. Wire up Firebase connection
4. Test everything
5. Update docs

---

## ✅ Phase 1.5 Success Criteria

**When complete, you'll be able to:**
1. ✅ Open app → auto-login as guest
2. ✅ Tap meditation card → see player screen
3. ✅ Firebase emulators showing auth user created
4. ✅ Console logs confirming Firebase connection
5. ✅ No errors in terminal

---

## 📊 Task Status

- [ ] Task 1: Java Installation
- [ ] Task 2: Firebase Project Setup
- [ ] Task 3: Firebase Emulator Init
- [ ] Task 4: Start Emulators
- [ ] Task 5: Auth Service Layer
- [ ] Task 6: Player Screen
- [ ] Task 7: Firebase Connection Test
- [ ] Task 8: Update Docs

---

## 🔗 Related Documentation

- **[TASK.md](./TASK.md)** - Overall project progress
- **[PLANNING.md](./PLANNING.md)** - Architecture decisions
- **[meditation_by_vk/FIREBASE_SETUP.md](./meditation_by_vk/FIREBASE_SETUP.md)** - Detailed emulator guide

---

**Ready to start? Complete tasks 1-4, then let Claude know to handle the rest. 🔥**
