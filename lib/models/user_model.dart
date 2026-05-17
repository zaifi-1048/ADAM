import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? provider; // 'email' | 'google'
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isPremium;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.provider = 'email',
    required this.createdAt,
    this.lastSeen,
    this.isPremium = false,
    this.preferences = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider ?? 'email',
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isPremium': isPremium,
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      provider: map['provider'] as String? ?? 'email',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      isPremium: map['isPremium'] as bool? ?? false,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    DateTime? lastSeen,
    bool? isPremium,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isPremium: isPremium ?? this.isPremium,
      preferences: preferences ?? this.preferences,
    );
  }
}
