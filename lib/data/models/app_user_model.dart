import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? fcmToken;
  final bool hasCompletedSetup;
  final List<Map<String, dynamic>> paymentMethods;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.hasCompletedSetup = false,
    this.paymentMethods = const [],
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
      hasCompletedSetup: json['hasCompletedSetup'] ?? false,
      paymentMethods: List<Map<String, dynamic>>.from(json['paymentMethods'] ?? []),
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
      'hasCompletedSetup': hasCompletedSetup,
      'paymentMethods': paymentMethods,
    };
  }

  AppUser? copyWith({
    String? displayName,
    String? photoURL,
    String? fcmToken,
    bool? hasCompletedSetup,
    List<Map<String, dynamic>>? paymentMethods,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
      fcmToken: fcmToken ?? this.fcmToken,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}