import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../models/message_model.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined notification permission');
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToDatabase(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          'general_channel',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(chatChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);
  }

  // Save FCM token to user's document in Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    if (_auth.currentUser != null) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_auth.currentUser!.uid)
          .update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'notificationSettings': {
              'enabled': true,
              'sound': true,
              'vibration': true,
              'badge': true,
            },
          });
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Show local notification
      _showLocalNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
        channelId: message.data['type'] == 'chat'
            ? 'chat_channel'
            : 'general_channel',
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');

    // Navigate to specific chat if chatId is provided
    if (message.data['chatId'] != null) {
      // You can implement navigation logic here
      // For now, we'll just print the chat ID
      print('Navigate to chat: ${message.data['chatId']}');
    }
  }

  // Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general_channel',
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_channel',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // CLIENT-SIDE ONLY: Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? fcmToken = userData['fcmToken'];
        Map<String, dynamic>? notificationSettings =
            userData['notificationSettings'];

        if (fcmToken != null) {
          // Check if notifications are enabled for this user
          if (notificationSettings != null &&
              notificationSettings['enabled'] == false) {
            print('Notifications disabled for user: $userId');
            return;
          }

          // For client-side implementation, we show local notification
          // In a real app, you might want to implement direct FCM sending
          print('Sending notification to user $userId');
          print('Title: $title, Body: $body, Data: $data');

          // Show local notification for the current user (for testing)
          if (_auth.currentUser != null && _auth.currentUser!.uid == userId) {
            _showLocalNotification(
              title: title,
              body: body,
              payload: data.toString(),
            );
          }
        } else {
          print('FCM token not found for user: $userId');
        }
      } else {
        print('User not found: $userId');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // CLIENT-SIDE ONLY: Send chat notification
  Future<void> sendChatNotification({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      // Get sender's user data
      DocumentSnapshot senderDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(senderId)
          .get();

      if (senderDoc.exists) {
        Map<String, dynamic> senderData =
            senderDoc.data() as Map<String, dynamic>;
        String senderName = senderData['displayName'] ?? 'Unknown User';

        // Prepare notification data
        String notificationTitle = senderName;
        String notificationBody = messageType == MessageType.image
            ? '📷 Sent you an image'
            : message;

        Map<String, dynamic> notificationData = {
          'type': 'chat',
          'chatId': chatId,
          'senderId': senderId,
          'messageType': messageType.toString(),
        };

        // Send notification using client-side method
        await sendNotificationToUser(
          userId: receiverId,
          title: notificationTitle,
          body: notificationBody,
          data: notificationData,
        );
      }
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  // Subscribe to topic (for group notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Get current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Delete FCM token (for logout)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();

    // Also remove from Firestore
    if (_auth.currentUser != null) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_auth.currentUser!.uid)
          .update({
            'fcmToken': null,
            'notificationSettings': {
              'enabled': false,
              'sound': false,
              'vibration': false,
              'badge': false,
            },
          });
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    required bool enabled,
    required bool sound,
    required bool vibration,
    required bool badge,
  }) async {
    if (_auth.currentUser != null) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_auth.currentUser!.uid)
          .update({
            'notificationSettings': {
              'enabled': enabled,
              'sound': sound,
              'vibration': vibration,
              'badge': badge,
            },
          });
    }
  }

  // Get notification settings
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    if (_auth.currentUser != null) {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['notificationSettings'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  // Test notification method
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Iqra Chat',
      payload: '{"type": "test"}',
    );
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');

  // Initialize Firebase if not already done
  await Firebase.initializeApp();

  // You can add additional background processing here
  // For example, updating local storage, syncing data, etc.
}
