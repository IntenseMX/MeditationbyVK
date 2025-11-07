class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String authProvider;
  final bool isAnonymous;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.authProvider,
    required this.isAnonymous,
    this.isPremium = false,
    required this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? authProvider,
    bool? isAnonymous,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      authProvider: authProvider ?? this.authProvider,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'authProvider': authProvider,
        'isAnonymous': isAnonymous,
        'isPremium': isPremium,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: (json['updatedAt'] as String?) != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

