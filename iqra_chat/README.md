# Iqra Chat App

A modern Flutter chat application with Firebase backend, featuring real-time messaging, media sharing, and push notifications.

## 🚀 Features

### Core Features
- **Real-time Messaging**: Instant message delivery using Firestore
- **User Authentication**: Secure login/signup with Firebase Auth
- **Media Sharing**: Send images and files
- **User Profiles**: Complete user profile management
- **Push Notifications**: Client-side notification system

### Notification System
- **Client-Side Only**: No Cloud Functions required initially
- **Local Notifications**: Works when app is in foreground
- **User Settings**: Customizable notification preferences
- **Test Functionality**: Built-in notification testing

## 🏗️ Architecture

### Current Implementation: Client-Side Notifications
The app currently uses a **client-side only notification approach** to avoid the need for Firebase Cloud Functions and the Blaze (pay-as-you-go) plan.

#### Why Client-Side Only?
1. **No Blaze Plan Required**: Works with free Firebase Spark plan
2. **Immediate Deployment**: No Cloud Functions setup needed
3. **Simpler Architecture**: Easier to understand and maintain
4. **Cost Effective**: No additional Firebase costs

#### How It Works
- Notifications are triggered when users send messages
- Local notifications appear when the app is in foreground
- FCM tokens are stored in Firestore for future use
- User notification settings are respected

#### Limitations
- Notifications only work when sender's app is open
- No background push notifications
- Limited to local notification display

### Future Enhancement: Cloud Functions
When ready for production, the app can be upgraded to use Firebase Cloud Functions for:
- Background push notifications
- Reliable delivery when app is closed
- Better scalability and security

## 📱 Screenshots

[Add screenshots here]

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Firebase project
- Android Studio / VS Code

### 1. Clone the Repository
```bash
git clone <repository-url>
cd iqra_chat
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project
2. Enable Authentication, Firestore, and Storage
3. Download `google-services.json` and place it in `android/app/`
4. Configure Firebase in your project

### 4. Run the App
```bash
flutter run
```

## 🔧 Configuration

### Firebase Configuration
The app uses the following Firebase services:
- **Authentication**: User login/signup
- **Firestore**: Real-time messaging and user data
- **Storage**: Media file uploads
- **Cloud Messaging**: FCM token management

### Notification Settings
Users can customize their notification preferences:
- Enable/disable notifications
- Sound settings
- Vibration settings
- Badge count settings

## 📁 Project Structure

```
lib/
├── constants/
│   └── app_constants.dart
├── models/
│   ├── chat_model.dart
│   ├── message_model.dart
│   └── user_model.dart
├── screens/
│   ├── chat_list_screen.dart
│   ├── chat_screen.dart
│   ├── login_screen.dart
│   ├── notification_settings_screen.dart
│   ├── profile_screen.dart
│   ├── profile_setup_screen.dart
│   ├── signup_screen.dart
│   └── user_selection_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── media_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
├── widgets/
│   ├── media_message_bubble.dart
│   └── message_bubble.dart
└── main.dart
```

## 🔄 Development Phases

### Phase 1: ✅ Basic Setup
- Project structure
- Firebase integration
- Basic UI components

### Phase 2: ✅ Authentication
- Login/Signup screens
- User profile management
- Firebase Auth integration

### Phase 3: ✅ Chat Functionality
- Real-time messaging
- Chat list and chat screen
- Message bubbles and UI

### Phase 4: ✅ Media Sharing
- Image picker integration
- File upload to Firebase Storage
- Media message display

### Phase 5: ✅ Push Notifications (Client-Side)
- **Current Implementation**: Client-side notifications
- Local notification system
- User notification settings
- FCM token management

### Phase 6: 🔄 Future - Cloud Functions
- Background push notifications
- Server-side notification processing
- Enhanced reliability

## 🧪 Testing

### Notification Testing
1. Open the app
2. Go to Profile → Notification Settings
3. Tap "Send Test Notification"
4. Verify notification appears

### Chat Testing
1. Create two user accounts
2. Start a chat between users
3. Send messages and verify delivery
4. Test image sharing

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📝 License

[Add your license here]

## 🤝 Contributing

[Add contribution guidelines here]

## 📞 Support

[Add support information here]

---

**Note**: This app uses a client-side notification approach to avoid Firebase Cloud Functions costs. For production use with background notifications, consider upgrading to the Blaze plan and implementing Cloud Functions.
