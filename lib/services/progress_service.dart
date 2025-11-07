import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class SessionRecord {
  SessionRecord({
    required this.id,
    required this.meditationId,
    this.meditationTitle,
    required this.startedAtUtc,
    required this.completedAtUtc,
    required this.durationSec,
    required this.completed,
  });

  final String id;
  final String meditationId;
  final String? meditationTitle;
  final DateTime startedAtUtc;
  final DateTime completedAtUtc;
  final int durationSec;
  final bool completed;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'meditationId': meditationId,
        if (meditationTitle != null && meditationTitle!.isNotEmpty) 'meditationTitle': meditationTitle,
        'startedAt': Timestamp.fromDate(startedAtUtc),
        'completedAt': Timestamp.fromDate(completedAtUtc),
        'duration': durationSec,
        'completed': completed,
      };

  factory SessionRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? <String, dynamic>{};
    return SessionRecord(
      id: d.id,
      meditationId: (data['meditationId'] ?? '') as String,
      meditationTitle: data['meditationTitle'] as String?,
      startedAtUtc: (data['startedAt'] as Timestamp).toDate().toUtc(),
      completedAtUtc: (data['completedAt'] as Timestamp).toDate().toUtc(),
      durationSec: (data['duration'] ?? 0) as int,
      completed: (data['completed'] ?? false) as bool,
    );
  }
}

class ProgressService {
  ProgressService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  static const String _pendingKey = 'pending_sessions_v1';

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User not authenticated');
    }
    return uid;
  }

  String buildSessionId({required String uid, required String meditationId, required DateTime startedAtUtc}) {
    return '${uid}_${meditationId}_${startedAtUtc.millisecondsSinceEpoch}';
  }

  // Begin listening for connectivity changes and attempt an initial flush.
  Future<void> start() async {
    try {
      _connSub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
        if (results.any((r) => r != ConnectivityResult.none)) {
          await flushPending();
        }
      });
      // Try to flush once on start in case we were previously offline.
      await flushPending();
    } catch (e) {
      // Log to aid diagnostics; non-fatal
      // ignore: avoid_print
      // Use debugPrint for consistency with rest of app
      debugPrint('Failed to start connectivity listener: $e');
    }
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
  }

  Future<void> writeSession({
    required String meditationId,
    String? meditationTitle,
    required DateTime startedAtUtc,
    required DateTime completedAtUtc,
    required int durationSec,
    required bool completed,
  }) async {
    final uid = _requireUid();
    final sessionId = buildSessionId(uid: uid, meditationId: meditationId, startedAtUtc: startedAtUtc.toUtc());
    final session = SessionRecord(
      id: sessionId,
      meditationId: meditationId,
      meditationTitle: meditationTitle,
      startedAtUtc: startedAtUtc.toUtc(),
      completedAtUtc: completedAtUtc.toUtc(),
      durationSec: durationSec < 0 ? 0 : durationSec,
      completed: completed,
    );

    try {
      final batch = _firestore.batch();
      final sessionRef = _firestore.collection('userProgress').doc(uid).collection('sessions').doc(sessionId);
      batch.set(sessionRef, session.toMap(), SetOptions(merge: false));
      if (completed) {
        final medRef = _firestore.collection('meditations').doc(meditationId);
        batch.update(medRef, {'playCount': FieldValue.increment(1)});
      }
      await batch.commit();
    } catch (e) {
      await _enqueuePending(session);
      rethrow;
    }
  }

  // Merge-upsert for progressive updates (duration increments, completion flag)
  Future<void> upsertSession({
    required String meditationId,
    String? meditationTitle,
    required DateTime startedAtUtc,
    required int durationSec,
    required bool completed,
  }) async {
    final uid = _requireUid();
    final sessionId = buildSessionId(uid: uid, meditationId: meditationId, startedAtUtc: startedAtUtc.toUtc());
    final ref = _firestore.collection('userProgress').doc(uid).collection('sessions').doc(sessionId);

    final Map<String, dynamic> payload = <String, dynamic>{
      // Maintain invariants on first write; on merge these fields persist
      'meditationId': meditationId,
      if (meditationTitle != null && meditationTitle.isNotEmpty) 'meditationTitle': meditationTitle,
      'startedAt': Timestamp.fromDate(startedAtUtc.toUtc()),
      'completedAt': FieldValue.serverTimestamp(),
      'duration': durationSec < 0 ? 0 : durationSec,
      'completed': completed,
    };

    if (completed) {
      final batch = _firestore.batch();
      batch.set(ref, payload, SetOptions(merge: true));
      batch.update(_firestore.collection('meditations').doc(meditationId), {
        'playCount': FieldValue.increment(1),
      });
      await batch.commit();
    } else {
      await ref.set(payload, SetOptions(merge: true));
    }
  }

  // Firestore-only write for use from audio callbacks (no SharedPreferences, no plugin calls)
  Future<void> tryWriteSession({
    required String meditationId,
    String? meditationTitle,
    required DateTime startedAtUtc,
    required DateTime completedAtUtc,
    required int durationSec,
    required bool completed,
  }) async {
    try {
      final uid = _requireUid();
      final sessionId = buildSessionId(uid: uid, meditationId: meditationId, startedAtUtc: startedAtUtc.toUtc());
      final session = SessionRecord(
        id: sessionId,
        meditationId: meditationId,
        meditationTitle: meditationTitle,
        startedAtUtc: startedAtUtc.toUtc(),
        completedAtUtc: completedAtUtc.toUtc(),
        durationSec: durationSec < 0 ? 0 : durationSec,
        completed: completed,
      );

      final batch = _firestore.batch();
      final sessionRef = _firestore.collection('userProgress').doc(uid).collection('sessions').doc(sessionId);
      batch.set(sessionRef, session.toMap(), SetOptions(merge: false));
      if (completed) {
        final medRef = _firestore.collection('meditations').doc(meditationId);
        batch.update(medRef, {'playCount': FieldValue.increment(1)});
      }
      await batch.commit();
    } catch (_) {
      // Intentionally swallow errors here; Firestore SDK handles offline queueing.
      // Foreground flows can invoke flushPending() separately if needed.
    }
  }

  // Upsert the premium entitlement flag on the user's document.
  // Keeps source of truth in Firestore for cross-device access.
  Future<void> upsertUserPremium({required bool isPremium}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(
      {
        'isPremium': isPremium,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _enqueuePending(SessionRecord session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    final List<Map<String, dynamic>> list = raw == null ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
    list.add(<String, dynamic>{
      'id': session.id,
      'meditationId': session.meditationId,
      'meditationTitle': session.meditationTitle,
      'startedAt': session.startedAtUtc.millisecondsSinceEpoch,
      'completedAt': session.completedAtUtc.millisecondsSinceEpoch,
      'duration': session.durationSec,
      'completed': session.completed,
    });
    await prefs.setString(_pendingKey, jsonEncode(list));
  }

  Future<void> flushPending() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return;
    List<dynamic> items = jsonDecode(raw) as List<dynamic>;
    if (items.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final item in items.cast<Map<String, dynamic>>()) {
      try {
        final session = SessionRecord(
          id: (item['id'] ?? '') as String,
          meditationId: (item['meditationId'] ?? '') as String,
          meditationTitle: item['meditationTitle'] as String?,
          startedAtUtc: DateTime.fromMillisecondsSinceEpoch((item['startedAt'] ?? 0) as int, isUtc: true),
          completedAtUtc: DateTime.fromMillisecondsSinceEpoch((item['completedAt'] ?? 0) as int, isUtc: true),
          durationSec: (item['duration'] ?? 0) as int,
          completed: (item['completed'] ?? false) as bool,
        );
        final batch = _firestore.batch();
        final sessionRef = _firestore.collection('userProgress').doc(uid).collection('sessions').doc(session.id);
        batch.set(sessionRef, session.toMap(), SetOptions(merge: false));
        if (session.completed) {
          final medRef = _firestore.collection('meditations').doc(session.meditationId);
          batch.update(medRef, {'playCount': FieldValue.increment(1)});
        }
        await batch.commit();
      } catch (_) {
        remaining.add(item);
      }
    }
    if (remaining.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(remaining));
    }
  }

  // Streams all sessions since [daysBack] days ago (UTC) - includes incomplete sessions
  Stream<List<SessionRecord>> streamRecentSessions({int daysBack = 60}) {
    final uid = _requireUid();
    final from = DateTime.now().toUtc().subtract(Duration(days: daysBack));
    final q = _firestore
        .collection('userProgress')
        .doc(uid)
        .collection('sessions')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('completedAt', descending: true);
    return q.snapshots().map((s) => s.docs.map(SessionRecord.fromDoc).toList());
  }

  // Calculates current and longest streak (days) using UTC midnight boundaries
  // Only counts days with at least one COMPLETED session
  ({int current, int longest}) calculateStreak(List<SessionRecord> sessions) {
    final completedSessions = sessions.where((s) => s.completed).toList();
    if (completedSessions.isEmpty) return (current: 0, longest: 0);
    final days = <String>{};
    for (final s in completedSessions) {
      final d = _utcDayKey(s.completedAtUtc);
      days.add(d);
    }
    final sorted = days.toList()..sort();
    int longest = 0;
    int current = 0;
    String? prev;
    for (final day in sorted) {
      if (prev == null) {
        current = 1;
        longest = 1;
      } else {
        final nextOfPrev = _incrementDayKey(prev);
        if (day == nextOfPrev) {
          current += 1;
          if (current > longest) longest = current;
        } else {
          current = 1;
          if (current > longest) longest = current;
        }
      }
      prev = day;
    }

    // Adjust current streak relative to today
    final todayKey = _utcDayKey(DateTime.now().toUtc());
    if (prev == null) return (current: 0, longest: longest);
    if (prev == todayKey) {
      // ok
    } else if (prev == _incrementDayKey(_utcDayKey(DateTime.now().toUtc().subtract(const Duration(days: 1))))) {
      // prev == yesterday (already logically covered by sequence); keep current
    } else {
      current = 0;
    }
    return (current: current, longest: longest);
  }

  String _utcDayKey(DateTime dtUtc) {
    final d = DateTime.utc(dtUtc.year, dtUtc.month, dtUtc.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _incrementDayKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    final next = DateTime.utc(y, m, d).add(const Duration(days: 1));
    return _utcDayKey(next);
  }
}


