class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final bool hasCompletedSetup;
  final bool emailVerified;
  final List<Map<String, dynamic>> paymentMethods;
  final Map<String, bool> notificationPrefs;

  static const Map<String, bool> _defaultNotificationPrefs = {
    'paymentApplied': true,
    'lowBalance': true,
    'monthlyRecap': true,
    'activityReminder': true,
  };

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.hasCompletedSetup = false,
    this.emailVerified = false,
    this.paymentMethods = const [],
    Map<String, bool>? notificationPrefs,
  }) : notificationPrefs = notificationPrefs ?? _defaultNotificationPrefs;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    Map<String, bool>? notificationPrefs;
    final raw = json['notificationPrefs'];
    if (raw is Map) {
      notificationPrefs = raw.map((k, v) => MapEntry(k.toString(), v == true));
    }
    return AppUser(
      uid: json['uid'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      fcmToken: json['fcmToken'],
      hasCompletedSetup: json['hasCompletedSetup'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      paymentMethods: List<Map<String, dynamic>>.from(json['payment_methods'] ?? json['paymentMethods'] ?? []),
      notificationPrefs: notificationPrefs,
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
      emailVerified: userDb.emailVerified,
      paymentMethods: userDb.paymentMethods ?? [],
    );
  }

  AppUser copyWith({
    String? username,
    String? photoUrl,
    String? fcmToken,
    bool? hasCompletedSetup,
    bool? emailVerified,
    List<Map<String, dynamic>>? paymentMethods,
    Map<String, bool>? notificationPrefs,
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
      emailVerified: emailVerified ?? this.emailVerified,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }
}
