class AppConstants {
  static const String appName = 'Iqra Chat';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  
  // Storage Paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String chatImagesPath = 'chat_images';
  
  // App Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxMessageLength = 1000;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultIconSize = 24.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
