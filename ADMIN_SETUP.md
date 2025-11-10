# Admin Setup Guide

Last Updated: 2025-11-10

## Setting Admin Custom Claims via Node REPL

### Prerequisites
1. Service account key file downloaded from Firebase Console
2. File saved as `service-account.json` in `functions/` directory

### Download Service Account Key (One-Time Setup)
1. Go to Firebase Console → Project Settings
2. Navigate to **Service Accounts** tab
3. Click **Generate New Private Key**
4. Save the downloaded JSON file as `service-account.json` in the `functions/` folder

### Set Admin Claim

**Navigate to functions directory:**
```bash
cd "C:\Users\inten\Desktop\CURSOR WORLD\Meditation App\meditation_by_vk\functions"
```

**Start Node REPL:**
```bash
node
```

**Run these commands one by one:**
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');
admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
admin.auth().getUserByEmail('YOUR_EMAIL@gmail.com').then(user => admin.auth().setCustomUserClaims(user.uid, {admin: true})).then(() => {console.log('Admin claim set!'); process.exit();}).catch(err => console.error(err));
```

**Replace `YOUR_EMAIL@gmail.com` with the actual email address.**

**Exit Node REPL:**
```bash
.exit
```
Or press `Ctrl+C` twice.

### Apply Changes
After setting the admin claim, the user must:
1. **Sign out** of the app
2. **Sign back in** to refresh the JWT token
3. Admin privileges will now be active

### Troubleshooting

**Error: `Identifier 'admin' has already been declared`**
- Exit Node REPL (`.exit` or `Ctrl+C` twice)
- Start fresh `node` session

**Error: `Cannot find module './service-account.json'`**
- Download service account key from Firebase Console
- Save as `service-account.json` in `functions/` directory

**Error: `The default Firebase app does not exist`**
- Make sure you ran `admin.initializeApp()` before the `getUserByEmail()` command
- Restart Node REPL and run all commands in order

### Security Notes
- **NEVER commit `service-account.json` to version control**
- Add `service-account.json` to `.gitignore`
- Keep the service account key secure - it has full Firebase admin access

### Why Custom Claims?
Custom claims are stored in the Firebase Auth JWT token and can be checked in:
- Firestore security rules
- Storage security rules
- Client-side code (read-only)

This allows admin-only features to be enforced both client-side and server-side without additional Firestore reads.
