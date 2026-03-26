class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final bool hasCompletedSetup;
  final List<Map<String, dynamic>> paymentMethods;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.hasCompletedSetup = false,
    this.paymentMethods = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      fcmToken: json['fcmToken'],
      hasCompletedSetup: json['hasCompletedSetup'] ?? false,
      paymentMethods: List<Map<String, dynamic>>.from(json['payment_methods'] ?? json['paymentMethods'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'hasCompletedSetup': hasCompletedSetup,
    };
  }

  factory AppUser.fromDb(dynamic userDb) {
    return AppUser(
      uid: userDb.id,
      username: userDb.username,
      email: userDb.email,
      photoUrl: userDb.photoUrl,
      createdAt: userDb.createdAt,
      updatedAt: userDb.updatedAt,
      fcmToken: userDb.fcmToken,
      hasCompletedSetup: userDb.hasCompletedSetup,
      paymentMethods: userDb.paymentMethods ?? [],
    );
  }

  AppUser copyWith({
    String? username,
    String? photoUrl,
    String? fcmToken,
    bool? hasCompletedSetup,
    List<Map<String, dynamic>>? paymentMethods,
  }) {
    return AppUser(
      uid: uid,
      username: username ?? this.username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}
