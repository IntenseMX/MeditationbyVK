import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

class AppUserModel {
  static Map<String, dynamic> toFirestore(AppUser user) => {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'authProvider': user.authProvider,
        'isAnonymous': user.isAnonymous,
        'isPremium': user.isPremium,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'updatedAt': user.updatedAt != null
            ? Timestamp.fromDate(user.updatedAt!)
            : FieldValue.serverTimestamp(),
      };

  static AppUser fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      authProvider: (data['authProvider'] as String?) ?? 'unknown',
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      isPremium: (data['isPremium'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

