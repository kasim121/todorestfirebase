# TaskFlow – Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"**
3. Name it `todo-flutter-app` (or any name you like)
4. Disable Google Analytics (optional) → Click **"Create Project"**

---

## Step 2: Add Android App to Firebase

1. In Firebase Console → Click **Android icon** (Add app)
2. **Android package name:** `com.example.todo`
3. **App nickname:** `TaskFlow`
4. **SHA-1:** (optional for now, needed for Google Sign-In)
   - Run: `cd android && ./gradlew signingReport` → copy Debug SHA-1
5. Click **Register App**
6. **Download `google-services.json`**
7. Place it at: `android/app/google-services.json`

---

## Step 3: Enable Firebase Authentication

1. Firebase Console → **Authentication** → **Get Started**
2. Click **Sign-in method** tab
3. Enable **Email/Password** → Save
4. Enable **Google** → Set project support email → Save

---

## Step 4: Create Firebase Realtime Database

1. Firebase Console → **Realtime Database** → **Create Database**
2. Choose your region (e.g., `us-central1`)
3. Start in **Test mode** (we'll secure it below)
4. Click **Create**

### Set Security Rules:
Go to **Rules** tab and paste:
```json
{
  "rules": {
    "tasks": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```
Click **Publish**.

5. Copy your **Database URL** — it looks like:
   `https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com`

---

## Step 5: Update firebase_options.dart

Run the FlutterFire CLI (recommended):
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

**OR** manually update `lib/firebase_options.dart`:
- Open **Firebase Console** → **Project Settings** (⚙️ icon)
- Click your Android app → copy values
- Replace all `YOUR_*` placeholders in `lib/firebase_options.dart`

---

## Step 6: Update Database URL in database_service.dart

Open `lib/services/database_service.dart` and replace:
```dart
static const String _baseUrl =
    'https://todo-flutter-app-default-rtdb.firebaseio.com';
```
with your actual database URL from Step 4.

---

## Step 7: Google Sign-In SHA-1 (for Google Sign-In to work)

```bash
cd android
./gradlew signingReport
```
Copy the **SHA-1** from the Debug section.  
In Firebase Console → Project Settings → Your Android App → **Add fingerprint** → Paste SHA-1 → Save.

Then re-download `google-services.json` and replace `android/app/google-services.json`.

---

## Step 8: Build the APK

```bash
# Debug APK
flutter build apk --debug

# Release APK (optimized, smaller)
flutter build apk --release --split-per-abi
```

APK output location:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## Project Structure

```
lib/
├── main.dart                   # App entry point + MultiProvider setup
├── firebase_options.dart       # Firebase configuration
├── models/
│   └── task_model.dart         # Task data model
├── providers/
│   ├── auth_provider.dart      # Auth state management (Provider)
│   └── task_provider.dart      # Task state management (Provider)
├── services/
│   ├── auth_service.dart       # Firebase Auth wrapper
│   └── database_service.dart  # REST API calls to Firebase RTDB
├── screens/
│   ├── welcome_screen.dart     # Onboarding / landing screen
│   ├── login_screen.dart       # Email/password + Google sign-in
│   ├── signup_screen.dart      # User registration
│   └── home_screen.dart        # Task list with tabs, search, stats
├── widgets/
│   ├── auth_wrapper.dart       # Decides Home vs Welcome based on auth state
│   ├── task_card.dart          # Task list item (swipe-to-delete, checkbox)
│   ├── add_edit_task_sheet.dart # Bottom sheet for add/edit task
│   └── stats_card.dart         # Summary stats widget
└── utils/
    └── app_theme.dart          # App-wide theme, colors, typography
```

## Features Implemented

- ✅ Firebase Email/Password Authentication
- ✅ Google Sign-In
- ✅ Password Reset via email
- ✅ Firebase Realtime Database via REST API (GET/PUT/PATCH/DELETE)
- ✅ Provider state management (AuthProvider + TaskProvider)
- ✅ View / Add / Edit / Delete tasks
- ✅ Mark tasks as complete (optimistic UI update)
- ✅ Priority levels (Low / Medium / High)
- ✅ Due dates with overdue detection
- ✅ Search tasks
- ✅ Filter tabs (All / Active / Completed)
- ✅ Stats summary (total, active, done)
- ✅ Swipe to delete with undo
- ✅ Pull-to-refresh
- ✅ Splash / loading screen
- ✅ User profile menu with sign out
- ✅ Responsive layout (adapts to screen size & keyboard)
- ✅ Clean, modern Material 3 UI
