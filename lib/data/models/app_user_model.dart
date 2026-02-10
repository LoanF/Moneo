class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
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
      uid: json['uid'] ?? json['id'],
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fcmToken': fcmToken,
      'hasCompletedSetup': hasCompletedSetup,
      'paymentMethods': paymentMethods,
    };
  }

  factory AppUser.fromDb(dynamic userDb) {
    return AppUser(
      uid: userDb.id,
      displayName: userDb.displayName,
      email: userDb.email,
      photoURL: userDb.photoUrl,
      createdAt: userDb.createdAt,
      updatedAt: userDb.updatedAt,
      fcmToken: userDb.fcmToken,
      hasCompletedSetup: userDb.hasCompletedSetup,
      paymentMethods: userDb.paymentMethods ?? [],
    );
  }

  AppUser copyWith({
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
      updatedAt: updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}