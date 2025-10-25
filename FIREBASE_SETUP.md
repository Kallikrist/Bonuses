# Firebase Setup Guide for Bonuses App

## 🔥 Setting up Firebase for your Bonuses Flutter App

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `bonuses-app` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Choose your Analytics account or create a new one
6. Click "Create project"

### Step 2: Add Flutter App to Firebase Project

1. In your Firebase project dashboard, click "Add app"
2. Choose the Flutter icon
3. Register your app:
   - **iOS Bundle ID**: `com.example.bonuses` (or your actual bundle ID)
   - **Android Package Name**: `com.example.bonuses` (or your actual package name)
   - **App Nickname**: `Bonuses App`

### Step 3: Download Configuration Files

#### For iOS (macOS):
1. Download `GoogleService-Info.plist`
2. Place it in `ios/Runner/` directory
3. Add to Xcode project (drag and drop into Xcode)

#### For Android:
1. Download `google-services.json`
2. Place it in `android/app/` directory

#### For Web:
1. Copy the Firebase config object
2. Update `lib/firebase_options.dart` with your actual values

### Step 4: Update Firebase Options

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
// Example for web
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyC...', // Your actual API key
  appId: '1:123456789:web:abcdef', // Your actual app ID
  messagingSenderId: '123456789', // Your actual sender ID
  projectId: 'bonuses-app', // Your actual project ID
  authDomain: 'bonuses-app.firebaseapp.com',
  storageBucket: 'bonuses-app.appspot.com',
);
```

### Step 5: Enable Firebase Services

#### Authentication:
1. Go to Authentication > Sign-in method
2. Enable "Email/Password" provider
3. Optionally enable "Google" sign-in

#### Firestore Database:
1. Go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)

#### Storage:
1. Go to Storage
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select a location

### Step 6: Set up Firestore Security Rules

Go to Firestore Database > Rules and add these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Company data - users can read their company's data
    match /companies/{companyId} {
      allow read, write: if request.auth != null && 
        resource.data.employeeIds != null && 
        request.auth.uid in resource.data.employeeIds;
    }
    
    // Targets - users can read/write targets for their company
    match /targets/{targetId} {
      allow read, write: if request.auth != null && 
        resource.data.companyId != null &&
        exists(/databases/$(database)/documents/companies/$(resource.data.companyId)) &&
        request.auth.uid in get(/databases/$(database)/documents/companies/$(resource.data.companyId)).data.employeeIds;
    }
    
    // Bonuses - similar to targets
    match /bonuses/{bonusId} {
      allow read, write: if request.auth != null && 
        resource.data.companyId != null &&
        exists(/databases/$(database)/documents/companies/$(resource.data.companyId)) &&
        request.auth.uid in get(/databases/$(database)/documents/companies/$(resource.data.companyId)).data.employeeIds;
    }
    
    // Subscriptions - only admins can read/write
    match /subscriptions/{subscriptionId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superAdmin'];
    }
    
    // Notifications - users can read their own notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Step 7: Test Firebase Connection

Run your Flutter app and check the console for:
```
Firebase initialized successfully
```

### Step 8: Migrate Demo Data (Optional)

Once Firebase is set up, you can migrate your existing demo data:

1. The app will continue to work with local storage
2. Firebase will be available for new data
3. You can implement data migration later

### Step 9: Production Considerations

Before going to production:

1. **Update Security Rules**: Make them more restrictive
2. **Enable Authentication**: Set up proper user management
3. **Configure Storage**: Set up file upload limits
4. **Set up Monitoring**: Enable Firebase Performance and Crashlytics
5. **Backup Strategy**: Set up automated backups

### Step 10: Environment Configuration

For different environments (dev, staging, prod):

1. Create separate Firebase projects
2. Use different configuration files
3. Update `firebase_options.dart` accordingly

## 🚀 Benefits of Firebase Integration

- **Real-time Updates**: Live data synchronization
- **Offline Support**: Works without internet
- **Authentication**: Secure user management
- **File Storage**: Upload images and documents
- **Push Notifications**: Engage users
- **Analytics**: Track app usage
- **Scalability**: Handles growth automatically

## 📱 Next Steps

1. Set up Firebase project
2. Update configuration files
3. Test the connection
4. Start using Firebase services
5. Migrate existing data gradually

Your Bonuses app will now have a real database with live updates, authentication, and all the features needed for a production app! 🎉
