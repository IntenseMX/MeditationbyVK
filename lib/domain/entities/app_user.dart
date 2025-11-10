class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String authProvider;
  final bool isAnonymous;
  final bool isPremium;
  final int dailyGoldGoal;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, DateTime> achievements;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.authProvider,
    required this.isAnonymous,
    this.isPremium = false,
    this.dailyGoldGoal = 10,
    required this.createdAt,
    this.updatedAt,
    this.achievements = const <String, DateTime>{},
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? authProvider,
    bool? isAnonymous,
    bool? isPremium,
    int? dailyGoldGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, DateTime>? achievements,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      authProvider: authProvider ?? this.authProvider,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      dailyGoldGoal: dailyGoldGoal ?? this.dailyGoldGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'authProvider': authProvider,
        'isAnonymous': isAnonymous,
        'isPremium': isPremium,
        'dailyGoldGoal': dailyGoldGoal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'achievements': achievements.map((k, v) => MapEntry(k, v.toIso8601String())),
      };

  factory AppUser.fromJson(String uid, Map<String, dynamic> json) {
    return AppUser(
      uid: uid,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      authProvider: (json['authProvider'] as String?) ?? 'unknown',
      isAnonymous: (json['isAnonymous'] as bool?) ?? false,
      isPremium: (json['isPremium'] as bool?) ?? false,
      dailyGoldGoal: (json['dailyGoldGoal'] as int?) ?? 10,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: (json['updatedAt'] as String?) != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      achievements: ((json['achievements'] as Map?) ?? const <String, dynamic>{})
          .map<String, DateTime>((dynamic key, dynamic value) {
        final String k = key as String;
        final String? v = value as String?;
        if (v == null) {
          return MapEntry(k, DateTime.fromMillisecondsSinceEpoch(0));
        }
        return MapEntry(k, DateTime.parse(v));
      }),
    );
  }
}

