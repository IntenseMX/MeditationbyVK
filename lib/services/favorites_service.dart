import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteItem {
  FavoriteItem({
    required this.userId,
    required this.meditationId,
    required this.createdAt,
  });

  final String userId;
  final String meditationId;
  final Timestamp createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'meditationId': meditationId,
        'createdAt': createdAt,
      };

  factory FavoriteItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? <String, dynamic>{};
    return FavoriteItem(
      userId: (data['userId'] ?? '') as String,
      meditationId: (data['meditationId'] ?? '') as String,
      createdAt: (data['createdAt'] is Timestamp) ? data['createdAt'] as Timestamp : Timestamp.now(),
    );
  }
}

class FavoritesService {
  FavoritesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Collection and field names (avoid magic strings)
  static const String _collection = 'favorites';
  static const String _fieldUserId = 'userId';
  static const String _fieldMeditationId = 'meditationId';
  static const String _fieldCreatedAt = 'createdAt';

  Future<void> init() async {}
  Future<void> start() async {}
  Future<void> dispose() async {}

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User not authenticated');
    }
    return uid;
    }

  String buildFavoriteId({required String uid, required String meditationId}) => '${uid}_$meditationId';

  Future<void> addFavorite(String meditationId) async {
    final uid = _requireUid();
    final id = buildFavoriteId(uid: uid, meditationId: meditationId);
    print('[FAVORITES_SERVICE] Adding favorite - docId: $id');
    final ref = _firestore.collection(_collection).doc(id);
    final now = Timestamp.now();
    await ref.set(<String, dynamic>{
      _fieldUserId: uid,
      _fieldMeditationId: meditationId,
      _fieldCreatedAt: now,
    }, SetOptions(merge: false));
    print('[FAVORITES_SERVICE] ✅ Favorite added to Firestore');
  }

  Future<void> removeFavorite(String meditationId) async {
    final uid = _requireUid();
    final id = buildFavoriteId(uid: uid, meditationId: meditationId);
    print('[FAVORITES_SERVICE] Removing favorite - docId: $id');
    final ref = _firestore.collection(_collection).doc(id);
    await ref.delete();
    print('[FAVORITES_SERVICE] ✅ Favorite removed from Firestore');
  }

  Future<bool> isFavorited(String meditationId) async {
    final uid = _requireUid();
    final id = buildFavoriteId(uid: uid, meditationId: meditationId);
    final snap = await _firestore.collection(_collection).doc(id).get();
    return snap.exists;
  }

  // Streams current user's favorites as a Set of meditationIds
  Stream<Set<String>> streamUserFavorites() {
    final uid = _requireUid();
    final q = _firestore
        .collection(_collection)
        .where(_fieldUserId, isEqualTo: uid)
        .orderBy(_fieldCreatedAt, descending: true);
    return q.snapshots().map((s) {
      return s.docs
          .map((d) => (d.data()[_fieldMeditationId] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }
}



