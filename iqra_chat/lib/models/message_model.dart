enum MessageType { text, image, voice, video }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isSeen;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.createdAt,
    this.isSeen = false,
    this.metadata,
  });

  // Create from Map (from Firestore)
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: _getMessageTypeFromString(map['type'] ?? 'text'),
      mediaUrl: map['mediaUrl'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isSeen: map['isSeen'] ?? false,
      metadata: map['metadata'],
    );
  }

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'createdAt': createdAt,
      'isSeen': isSeen,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    String? mediaUrl,
    DateTime? createdAt,
    bool? isSeen,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      isSeen: isSeen ?? this.isSeen,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to convert string to MessageType
  static MessageType _getMessageTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  // Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  // Check if message has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  @override
  String toString() {
    return 'MessageModel(id: $id, chatId: $chatId, senderId: $senderId, text: $text, type: $type, isSeen: $isSeen)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 