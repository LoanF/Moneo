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
      uid: json['uid'] ?? json['id'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photo_url'] ?? json['photoURL'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) :
      json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) :
      json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      fcmToken: json['fcm_token'] ?? json['fcmToken'],
      hasCompletedSetup: json['has_completed_setup'] ?? json['hasCompletedSetup'] ?? false,
      paymentMethods: List<Map<String, dynamic>>.from(json['payment_methods'] ?? json['paymentMethods'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'username': displayName,
      'email': email,
      'photo_url': photoURL,
      'fcm_token': fcmToken,
      'has_completed_setup': hasCompletedSetup,
      'payment_methods': paymentMethods,
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