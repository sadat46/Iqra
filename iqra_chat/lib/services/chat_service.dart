import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../constants/app_constants.dart';
import '../services/media_service.dart';
import '../services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // MediaService instance for image handling
  final MediaService _mediaService = MediaService();
  // NotificationService instance for sending notifications
  final NotificationService _notificationService = NotificationService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get all chats for current user
  Stream<List<ChatModel>> getChats() {
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: currentUser!.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Create or get existing chat between two users
  Future<String> createOrGetChat(String otherUserId) async {
    if (currentUser == null) throw Exception('User not authenticated');

    // Check if chat already exists
    QuerySnapshot existingChats = await _firestore
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: currentUser!.uid)
        .get();

    for (var doc in existingChats.docs) {
      List<String> participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id; // Return existing chat ID
      }
    }

    // Create new chat
    DocumentReference chatRef = await _firestore
        .collection(AppConstants.chatsCollection)
        .add({
      'participants': [currentUser!.uid, otherUserId],
      'lastMessage': null,
      'lastMessageTime': null,
      'unreadCount': 0,
      'typingUsers': {},
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });

    return chatRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    // Create message
    MessageModel message = MessageModel(
      id: '', // Will be set by Firestore
      chatId: chatId,
      senderId: currentUser!.uid,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
      isSeen: false,
    );

    // Add message to Firestore
    await _firestore
        .collection(AppConstants.messagesCollection)
        .add(message.toMap());

    // Update chat with last message
    String lastMessageText = type == MessageType.image ? '📷 Image' : text;
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId).update({
      'lastMessage': lastMessageText,
      'lastMessageTime': DateTime.now(),
      'updatedAt': DateTime.now(),
    });

    // Send notification to other participants
    await _sendNotificationToChatParticipants(chatId, text, type);
  }

  // Send notification to chat participants
  Future<void> _sendNotificationToChatParticipants(
    String chatId,
    String message,
    MessageType type,
  ) async {
    try {
      // Get chat document
      DocumentSnapshot chatDoc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
        List<String> participants = List<String>.from(chatData['participants']);

        // Send notification to all participants except the sender
        for (String participantId in participants) {
          if (participantId != currentUser!.uid) {
            // Use client-side notification method
            await _notificationService.sendChatNotification(
              chatId: chatId,
              senderId: currentUser!.uid,
              receiverId: participantId,
              message: message,
              messageType: type,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending notification to chat participants: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String imageUrl,
    String? caption,
  }) async {
    await sendMessage(
      chatId: chatId,
      text: caption ?? '',
      type: MessageType.image,
      mediaUrl: imageUrl,
    );
  }

  // Mark messages as seen
  Future<void> markMessagesAsSeen(String chatId) async {
    if (currentUser == null) return;

    // Get all messages for this chat and filter in memory to avoid complex index
    QuerySnapshot messages = await _firestore
        .collection(AppConstants.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .get();

    // Filter and update unread messages
    List<Future<void>> updateFutures = [];
    for (var doc in messages.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['senderId'] != currentUser!.uid && data['isSeen'] == false) {
        updateFutures.add(doc.reference.update({'isSeen': true}));
      }
    }

    // Execute all updates
    if (updateFutures.isNotEmpty) {
      await Future.wait(updateFutures);
    }

    // Reset unread count
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId).update({
      'unreadCount': 0,
    });
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat
    QuerySnapshot messages = await _firestore
        .collection(AppConstants.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete the chat
    await _firestore.collection(AppConstants.chatsCollection).doc(chatId).delete();
  }

  // Get user data for chat participants
  Future<Map<String, dynamic>> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return {};
  }
} 