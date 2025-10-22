import 'package:cloud_firestore/cloud_firestore.dart';

class AuditEntry {
  final String id;
  final String actorUid;
  final String action;
  final Map<String, dynamic> target;
  final Timestamp? ts;

  AuditEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.target,
    required this.ts,
  });
}

class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<int> getMeditationsCount() async {
    final snap = await _firestore.collection('meditations').get();
    return snap.size;
  }

  Future<int> getCategoriesCount() async {
    final snap = await _firestore.collection('categories').get();
    return snap.size;
  }

  Future<int> getPublishedMeditationsCount() async {
    final snap = await _firestore
        .collection('meditations')
        .where('status', isEqualTo: 'published')
        .get();
    return snap.size;
  }

  Stream<List<AuditEntry>> recentAdminActivity({int limit = 10}) {
    return _firestore
        .collection('adminAudit')
        .orderBy('ts', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs
            .map((d) => AuditEntry(
                  id: d.id,
                  actorUid: (d.data()['actorUid'] ?? '') as String,
                  action: (d.data()['action'] ?? '') as String,
                  target: (d.data()['target'] ?? <String, dynamic>{})
                      as Map<String, dynamic>,
                  ts: d.data()['ts'] is Timestamp ? d.data()['ts'] as Timestamp : null,
                ))
            .toList());
  }
}


