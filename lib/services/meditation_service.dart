import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeditationListItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String? categoryId;
  final String status; // draft | published
  final int? durationSec;
  final Timestamp? createdAt;
  final String? difficulty; // beginner | intermediate | advanced
  final bool? isPremium;

  MeditationListItem({
    required this.id,
    required this.title,
    required this.status,
    this.imageUrl,
    this.categoryId,
    this.durationSec,
    this.createdAt,
    this.difficulty,
    this.isPremium,
  });

  factory MeditationListItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? <String, dynamic>{};
    return MeditationListItem(
      id: d.id,
      title: (data['title'] ?? '') as String,
      imageUrl: data['imageUrl'] as String?,
      categoryId: data['categoryId'] as String?,
      status: (data['status'] ?? 'draft') as String,
      durationSec: data['durationSec'] as int?,
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
      difficulty: data['difficulty'] as String?,
      isPremium: data['isPremium'] as bool?,
    );
  }
}

class MeditationService {
  MeditationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Generate a new document ID without writing any data
  String newId() {
    return _firestore.collection('meditations').doc().id;
  }

  Future<String> createMeditation(Map<String, dynamic> data) async {
    final now = Timestamp.now();
    final doc = _firestore.collection('meditations').doc();
    final payload = {
      'title': data['title'] ?? '',
      'description': data['description'] ?? '',
      'tags': List<String>.from(data['tags'] ?? <String>[]),
      'categoryId': data['categoryId'],
      'difficulty': data['difficulty'] ?? 'beginner',
      'isPremium': data['isPremium'] ?? false,
      'status': data['status'] ?? 'draft',
      'imageUrl': data['imageUrl'],
      'audioUrl': data['audioUrl'],
      'durationSec': data['durationSec'],
      'version': 1,
      'createdAt': now,
      'updatedAt': now,
      'publishedAt': null,
    };
    await doc.set(payload);
    await _logAudit(action: 'create', target: {'collection': 'meditations', 'id': doc.id});
    return doc.id;
  }

  Future<void> updateMeditation(String id, Map<String, dynamic> data) async {
    final now = Timestamp.now();
    final ref = _firestore.collection('meditations').doc(id);
    // Read current version to increment
    final snap = await ref.get();
    final currentVersion = (snap.data()?['version'] as int?) ?? 1;
    final payload = <String, dynamic>{
      if (data.containsKey('title')) 'title': data['title'],
      if (data.containsKey('description')) 'description': data['description'],
      if (data.containsKey('tags')) 'tags': List<String>.from(data['tags'] ?? <String>[]),
      if (data.containsKey('categoryId')) 'categoryId': data['categoryId'],
      if (data.containsKey('difficulty')) 'difficulty': data['difficulty'],
      if (data.containsKey('isPremium')) 'isPremium': data['isPremium'],
      if (data.containsKey('status')) 'status': data['status'],
      if (data.containsKey('imageUrl')) 'imageUrl': data['imageUrl'],
      if (data.containsKey('audioUrl')) 'audioUrl': data['audioUrl'],
      if (data.containsKey('durationSec')) 'durationSec': data['durationSec'],
      'version': currentVersion + 1,
      'updatedAt': now,
    };
    await ref.update(payload);
    await _logAudit(action: 'update', target: {'collection': 'meditations', 'id': id});
  }

  Future<void> createMeditationWithId(String id, Map<String, dynamic> data) async {
    final now = Timestamp.now();
    final ref = _firestore.collection('meditations').doc(id);
    final payload = {
      'title': data['title'] ?? '',
      'description': data['description'] ?? '',
      'tags': List<String>.from(data['tags'] ?? <String>[]),
      'categoryId': data['categoryId'],
      'difficulty': data['difficulty'] ?? 'beginner',
      'isPremium': data['isPremium'] ?? false,
      'status': data['status'] ?? 'draft',
      'imageUrl': data['imageUrl'],
      'audioUrl': data['audioUrl'],
      'durationSec': data['durationSec'],
      'version': 1,
      'createdAt': now,
      'updatedAt': now,
      'publishedAt': null,
    };
    await ref.set(payload);
    await _logAudit(action: 'create', target: {'collection': 'meditations', 'id': id});
  }

  Future<void> publishMeditation(String id) async {
    final now = Timestamp.now();
    final ref = _firestore.collection('meditations').doc(id);
    final snap = await ref.get();
    final currentVersion = (snap.data()?['version'] as int?) ?? 1;
    await ref.update({
      'status': 'published',
      'publishedAt': now,
      'updatedAt': now,
      'version': currentVersion + 1,
    });
    await _logAudit(action: 'publish', target: {'collection': 'meditations', 'id': id});
  }

  Future<void> deleteMeditation(String id) async {
    await _firestore.collection('meditations').doc(id).delete();
    await _logAudit(action: 'delete', target: {'collection': 'meditations', 'id': id});
  }

  Future<Map<String, dynamic>?> getMeditation(String id) async {
    final snap = await _firestore.collection('meditations').doc(id).get();
    return snap.data();
  }

  Future<void> _logAudit({required String action, required Map<String, dynamic> target}) async {
    final uid = _auth.currentUser?.uid ?? 'unknown';
    await _firestore.collection('adminAudit').add({
      'actorUid': uid,
      'action': action,
      'target': target,
      'ts': Timestamp.now(),
    });
  }

  // Real-time list stream (index-safe): server filters only on status; others client-side
  Stream<List<MeditationListItem>> streamMeditations({String? status}) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('meditations')
        .orderBy('createdAt', descending: true);

    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }

    return q.snapshots().map(
          (snap) => snap.docs.map(MeditationListItem.fromDoc).toList(),
        );
  }

  // Bulk operations using WriteBatch and atomic version increments
  Future<void> bulkPublish(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = Timestamp.now();
    final batch = _firestore.batch();
    for (final id in ids) {
      final ref = _firestore.collection('meditations').doc(id);
      batch.update(ref, {
        'status': 'published',
        'publishedAt': now,
        'updatedAt': now,
        'version': FieldValue.increment(1),
      });
    }
    await batch.commit();
    await _logAudit(action: 'bulk_publish', target: {'collection': 'meditations', 'ids': ids});
  }

  Future<void> bulkUnpublish(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = Timestamp.now();
    final batch = _firestore.batch();
    for (final id in ids) {
      final ref = _firestore.collection('meditations').doc(id);
      batch.update(ref, {
        'status': 'draft',
        'publishedAt': null,
        'updatedAt': now,
        'version': FieldValue.increment(1),
      });
    }
    await batch.commit();
    await _logAudit(action: 'bulk_unpublish', target: {'collection': 'meditations', 'ids': ids});
  }

  Future<void> bulkDelete(List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      final ref = _firestore.collection('meditations').doc(id);
      batch.delete(ref);
    }
    await batch.commit();
    await _logAudit(action: 'bulk_delete', target: {'collection': 'meditations', 'ids': ids});
  }
}


