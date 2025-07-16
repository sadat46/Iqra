// ## 🔧 **Step 2: Fix app_constants.dart**

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePicture;
  final String? bio;
  final String? phone;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final bool isProfileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicture,
    this.bio,
    this.phone,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    this.isProfileCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Map (from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePicture: map['profilePicture'],
      bio: map['bio'],
      phone: map['phone'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen']?.toDate(),
      fcmToken: map['fcmToken'],
      isProfileCompleted: map['isProfileCompleted'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'phone': phone,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'fcmToken': fcmToken,
      'isProfileCompleted': isProfileCompleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? profilePicture,
    String? bio,
    String? phone,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    bool? isProfileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, isOnline: $isOnline, isProfileCompleted: $isProfileCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
