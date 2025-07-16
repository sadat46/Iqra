# Firebase Cloud Messaging (FCM) Setup Guide

This guide explains how to set up and deploy Firebase Cloud Messaging for the Iqra Chat app.

## Overview

The FCM implementation includes:
- Push notifications for new messages
- Local notifications for foreground messages
- Notification settings management
- Cloud Functions for server-side notification handling
- Background message handling

## Prerequisites

1. Firebase project with Firestore and Functions enabled
2. Node.js 18+ installed
3. Firebase CLI installed: `npm install -g firebase-tools`

## Setup Steps

### 1. Firebase Project Configuration

Ensure your Firebase project has the following services enabled:
- Authentication
- Firestore Database
- Cloud Functions
- Cloud Messaging

### 2. Deploy Cloud Functions

```bash
# Navigate to the functions directory
cd functions

# Install dependencies
npm install

# Build the functions
npm run build

# Deploy functions
firebase deploy --only functions
```

### 3. Configure FCM in Firebase Console

1. Go to Firebase Console > Project Settings
2. Navigate to Cloud Messaging tab
3. Download the `google-services.json` file for Android
4. Place it in `android/app/` directory

### 4. Android Configuration

The app is already configured for FCM. Key files:
- `android/app/google-services.json` - FCM configuration
- `android/app/src/main/AndroidManifest.xml` - Notification permissions

### 5. iOS Configuration (if needed)

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to your iOS project
3. Configure notification capabilities in Xcode

## Features Implemented

### 1. Notification Service (`lib/services/notification_service.dart`)

- FCM token management
- Local notification handling
- Background message processing
- Notification settings management

### 2. Cloud Functions (`functions/src/index.ts`)

- `sendNotification` - Sends FCM notifications when notification documents are created
- `sendChatNotification` - Automatically sends notifications for new messages
- `cleanupOldNotifications` - Cleans up old notification records
- `updateFCMToken` - Handles FCM token updates

### 3. Notification Settings Screen (`lib/screens/notification_settings_screen.dart`)

- Enable/disable notifications
- Sound, vibration, and badge settings
- Test notification functionality

### 4. Chat Integration

- Automatic notifications when messages are sent
- Integration with chat service
- Support for text and image messages

## Usage

### Sending Notifications

```dart
// Send notification to specific user
await notificationService.sendNotificationToUser(
  userId: 'user_id',
  title: 'Notification Title',
  body: 'Notification body',
  data: {'type': 'chat', 'chatId': 'chat_id'},
);

// Send chat notification
await notificationService.sendChatNotification(
  chatId: 'chat_id',
  senderId: 'sender_id',
  receiverId: 'receiver_id',
  message: 'Hello!',
  messageType: MessageType.text,
);
```

### Managing Notification Settings

```dart
// Update notification settings
await notificationService.updateNotificationSettings(
  enabled: true,
  sound: true,
  vibration: true,
  badge: true,
);

// Get current settings
final settings = await notificationService.getNotificationSettings();
```

## Testing

### 1. Test Local Notifications

1. Open the app
2. Go to Profile > Notification Settings
3. Tap "Send Test Notification"
4. Verify notification appears

### 2. Test Push Notifications

1. Send a message to another user
2. Verify the other user receives a push notification
3. Check notification content and actions

### 3. Test Background Notifications

1. Close the app
2. Send a message from another device
3. Verify push notification is received

## Troubleshooting

### Common Issues

1. **Notifications not working**
   - Check FCM token is saved in Firestore
   - Verify notification permissions are granted
   - Check Cloud Functions are deployed

2. **Background notifications not working**
   - Ensure app is properly configured for background processing
   - Check Firebase configuration files

3. **Cloud Functions errors**
   - Check Firebase Console > Functions > Logs
   - Verify function deployment was successful

### Debug Steps

1. Check FCM token:
```dart
final token = await notificationService.getToken();
print('FCM Token: $token');
```

2. Check notification settings:
```dart
final settings = await notificationService.getNotificationSettings();
print('Settings: $settings');
```

3. Monitor Firestore for notification documents:
   - Check `notifications` collection
   - Verify documents are created and processed

## Security

- Firestore rules ensure users can only access their own notifications
- FCM tokens are stored securely in user documents
- Notification settings are user-specific

## Performance

- Notifications are processed asynchronously
- Old notifications are automatically cleaned up
- Efficient querying with proper Firestore indexes

## Next Steps

1. Add notification history screen
2. Implement notification actions (reply, mark as read)
3. Add group notification support
4. Implement notification scheduling
5. Add notification analytics

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review this documentation
3. Test with Firebase emulators
4. Check Flutter and Firebase documentation 