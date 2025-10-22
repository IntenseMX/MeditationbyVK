import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}


