# 🔥 Firebase Development Setup Guide

## Quick Start for Development Testing

### Step 1: Create Firebase Project (5 minutes)

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Click "Create a project"**
3. **Project name**: `bonuses-dev` (or your preferred name)
4. **Enable Google Analytics**: ✅ Yes (recommended)
5. **Click "Create project"**

### Step 2: Add Flutter App to Firebase

1. **In your Firebase project dashboard**
2. **Click "Add app" → Flutter icon**
3. **Register your app**:
   - **iOS Bundle ID**: `com.example.bonuses`
   - **Android Package Name**: `com.example.bonuses`
   - **App Nickname**: `Bonuses Dev`

### Step 3: Download Configuration Files

#### For macOS (Development):
1. **Download `GoogleService-Info.plist`**
2. **Place in**: `macos/Runner/`
3. **Add to Xcode project** (drag and drop)

#### For Android (Future deployment):
1. **Download `google-services.json`**
2. **Place in**: `android/app/`

#### For Web (Future deployment):
1. **Copy Firebase config object**
2. **Update `lib/firebase_options.dart`**

### Step 4: Update Firebase Options

Replace the placeholder values in `lib/firebase_options.dart`:

```dart
// Example for macOS
static const FirebaseOptions macos = FirebaseOptions(
  apiKey: 'AIzaSyC...', // Your actual API key
  appId: '1:123456789:macos:abcdef', // Your actual app ID
  messagingSenderId: '123456789', // Your actual sender ID
  projectId: 'bonuses-dev', // Your actual project ID
  storageBucket: 'bonuses-dev.appspot.com',
  iosBundleId: 'com.example.bonuses',
);
```

### Step 5: Enable Firebase Services

#### Authentication:
1. **Go to Authentication → Sign-in method**
2. **Enable "Email/Password"**
3. **Click "Save"**

#### Firestore Database:
1. **Go to Firestore Database**
2. **Click "Create database"**
3. **Choose "Start in test mode"** (for development)
4. **Select location** (choose closest to you)

#### Storage:
1. **Go to Storage**
2. **Click "Get started"**
3. **Choose "Start in test mode"**
4. **Select location**

### Step 6: Test Firebase Connection

Run your app and check console for:
```
Firebase initialized successfully
```

### Step 7: Development Security Rules

For development, use these permissive rules in Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads and writes for development
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ IMPORTANT**: These rules are for development only! Never use in production.

### Step 8: Test Firebase Features

1. **Run the app**: `flutter run -d macos`
2. **Check console**: Should see "Firebase initialized successfully"
3. **Test authentication**: Try logging in
4. **Check Firestore**: Data should appear in Firebase Console

## 🚀 Development Workflow

### Daily Development:
1. **Use local storage** for quick testing
2. **Switch to Firebase** when testing real-time features
3. **Use Firebase Console** to monitor data

### Testing Real-time Features:
1. **Open Firebase Console** in browser
2. **Go to Firestore Database**
3. **Watch data update in real-time** as you use the app

### Debugging:
1. **Check Firebase Console** for errors
2. **Use Flutter DevTools** for app debugging
3. **Check browser console** for web-specific issues

## 📱 Next Steps

### For Production:
1. **Create production Firebase project**
2. **Set up proper security rules**
3. **Configure authentication providers**
4. **Set up monitoring and analytics**

### For Team Development:
1. **Share Firebase project** with team members
2. **Use Firebase Emulator Suite** for local development
3. **Set up CI/CD** with Firebase

## 🔧 Troubleshooting

### Common Issues:

1. **"Firebase not initialized"**
   - Check `firebase_options.dart` has correct values
   - Ensure configuration files are in correct locations

2. **"Permission denied"**
   - Check Firestore security rules
   - Ensure user is authenticated

3. **"Build failed"**
   - Check macOS deployment target is 10.15+
   - Clean and rebuild: `flutter clean && flutter pub get`

### Getting Help:
- **Firebase Documentation**: https://firebase.google.com/docs
- **FlutterFire Documentation**: https://firebase.flutter.dev/
- **Firebase Console**: https://console.firebase.google.com/

## 🎉 You're Ready!

Your Bonuses app now has:
- ✅ **Real-time database** (Firestore)
- ✅ **Authentication** (Firebase Auth)
- ✅ **File storage** (Firebase Storage)
- ✅ **Push notifications** (Firebase Messaging)
- ✅ **Offline support** (automatic)
- ✅ **Real-time updates** (live data sync)

Start building amazing features! 🚀
