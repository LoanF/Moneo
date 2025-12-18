import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      photoURL: json['photoURL'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'updatedAt': Timestamp.now(),
      'fcmToken': fcmToken,
    };
  }

  AppUser? copyWith({
    String? displayName,
    String? photoURL,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}