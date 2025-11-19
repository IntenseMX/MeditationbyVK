import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/progress_service.dart';
import './auth_provider.dart';

// Streams the user's daily goal from Firestore and updates live
final userDailyGoalProvider = StreamProvider<int>((ref) {
  final auth = ref.watch(authProvider);
  final uid = auth.user?.uid;
  if (uid == null) {
    return Stream<int>.value(10);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
        final g = (snap.data()?['dailyGoldGoal'] as int?) ?? 10;
        return g <= 0 ? 10 : g;
      })
      .distinct();
});

final progressServiceProvider = Provider<ProgressService>((ref) {
  final svc = ProgressService();
  // Start auto-sync on provider creation; ignore returned Future intentionally
  svc.start();
  ref.onDispose(() => svc.dispose());
  return svc;
});

// Emits a map compatible with current ProgressScreen expectations
// {
//   'daily': {'percentage': int, 'minutesCompleted': int, 'goalMinutes': int, 'sessions': List<Map>},
//   'weekly': {'data': List<int>(7), 'streak': int, 'currentMinutes': int},
//   'monthly': {'streak': int, 'currentMinutes': int}
// }
final progressDtoProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final svc = ref.watch(progressServiceProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.user?.uid;
  final userDocStream = uid == null
      ? Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
      : FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  final sessionsStream = svc.streamRecentSessions(daysBack: 60);

  // Combine sessions stream with goal stream to emit updates on either change
  return Stream<Map<String, dynamic>>.multi((controller) {
    List<SessionRecord> latestSessions = const <SessionRecord>[];
    var latestGoal = 10;
    Map<String, dynamic> latestAchievements = const <String, dynamic>{};

    Future<void> emit() async {
      // Use local day boundaries for all user-facing progress calculations
      final nowLocal = DateTime.now();
      final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

      // Daily totals (sum seconds, then round up to minutes)
      int todaySeconds = 0;
      for (final s in latestSessions) {
        final local = s.completedAtUtc.toLocal();
        final sessionDay = DateTime(local.year, local.month, local.day);
        if (sessionDay == todayLocal) {
          todaySeconds += (s.durationSec as num).toInt();
        }
      }
      final int todayMinutes = (todaySeconds + 59) ~/ 60;
      final int safeGoal = latestGoal <= 0 ? 10 : latestGoal;
      final int dailyPercentage = ((todayMinutes / safeGoal) * 100).clamp(0, 100).toInt();

      // Weekly (current calendar week, Sunday -> Saturday), using UTC day boundaries
      final List<int> weeklyData = List<int>.filled(7, 0);
      final int daysSinceSunday = todayLocal.weekday % 7; // Monday=1..Sunday=7 -> 0 for Sunday
      final DateTime weekStart = todayLocal.subtract(Duration(days: daysSinceSunday));
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final key = DateTime(day.year, day.month, day.day);
        int seconds = 0;
        for (final s in latestSessions) {
          final local = s.completedAtUtc.toLocal();
          final d = DateTime(local.year, local.month, local.day);
          if (d == key) seconds += (s.durationSec as num).toInt();
        }
        weeklyData[i] = (seconds + 59) ~/ 60;
      }
      final int weeklyCurrentMinutes = weeklyData.fold<int>(0, (a, b) => a + b);

      // Monthly (last 30 days)
      int monthlySeconds = 0;
      final monthStart = todayLocal.subtract(const Duration(days: 29));
      for (final s in latestSessions) {
        final local = s.completedAtUtc.toLocal();
        final d = DateTime(local.year, local.month, local.day);
        if (!d.isBefore(monthStart) && !d.isAfter(todayLocal)) {
          monthlySeconds += (s.durationSec as num).toInt();
        }
      }
      final int monthlyMinutes = (monthlySeconds + 59) ~/ 60;
      // Per-day data for monthly chart (30 bars, oldest -> newest)
      final List<int> monthlyData = List<int>.filled(30, 0);
      for (int i = 0; i < 30; i++) {
        final day = monthStart.add(Duration(days: i));
        final key = DateTime(day.year, day.month, day.day);
        int seconds = 0;
        for (final s in latestSessions) {
          final local = s.completedAtUtc.toLocal();
          final d = DateTime(local.year, local.month, local.day);
          if (d == key) seconds += (s.durationSec as num).toInt();
        }
        monthlyData[i] = (seconds + 59) ~/ 60;
      }

      // Streaks
      final streaks = svc.calculateStreak(latestSessions);

      // Award achievements (idempotent: only writes when missing)
      if (uid != null) {
        final Map<String, dynamic> toAward = <String, dynamic>{};

        // Helper to add if unlocked now but missing
        void maybeAdd(String key, bool condition) {
          if (condition && !latestAchievements.containsKey(key)) {
            toAward['achievements.$key'] = FieldValue.serverTimestamp();
          }
        }

        // Compute aggregates for conditions
        final int completedSessionsCount = latestSessions.where((s) => s.completed).length;
        final int totalSeconds = latestSessions.fold<int>(0, (sum, s) => sum + ((s.durationSec as num).toInt()));
        final int totalMinutes = (totalSeconds + 59) ~/ 60;
        final int currentStreak = streaks.current;

        // Streak achievements
        maybeAdd('streak_5', currentStreak >= 5);
        maybeAdd('streak_10', currentStreak >= 10);
        maybeAdd('streak_30', currentStreak >= 30);

        // Session count achievements
        maybeAdd('sessions_5', completedSessionsCount >= 5);
        maybeAdd('sessions_25', completedSessionsCount >= 25);
        maybeAdd('sessions_50', completedSessionsCount >= 50);

        // Minutes achievements
        maybeAdd('minutes_50', totalMinutes >= 50);
        maybeAdd('minutes_100', totalMinutes >= 100);
        maybeAdd('minutes_300', totalMinutes >= 300);

        if (toAward.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update(toAward);
        }
      }

      // Build today's sessions list with denormalized titles
      final todaysSessions = latestSessions.where((s) {
        final local = s.completedAtUtc.toLocal();
        final d = DateTime(local.year, local.month, local.day);
        return d == todayLocal;
      }).toList();

      final List<Map<String, dynamic>> todaySessions = todaysSessions.map((s) => <String, dynamic>{
        'name': (s.meditationTitle == null || s.meditationTitle!.isEmpty) ? 'Meditation Session' : s.meditationTitle,
        'duration': (s.durationSec + 59) ~/ 60,
        'imageUrl': s.meditationImageUrl,
      }).toList(growable: false);

      if (!controller.isClosed) {
        controller.add(<String, dynamic>{
          'daily': <String, dynamic>{
            'percentage': dailyPercentage,
            'minutesCompleted': todayMinutes,
            'goalMinutes': safeGoal,
            'sessions': todaySessions,
          },
          'weekly': <String, dynamic>{
            'data': weeklyData,
            'streak': streaks.current,
            'currentMinutes': weeklyCurrentMinutes,
          },
          'monthly': <String, dynamic>{
            'data': monthlyData,
            'streak': streaks.longest,
            'currentMinutes': monthlyMinutes,
          },
          'achievements': latestAchievements.keys.toList(growable: false),
        });
      }
    }

    final sub1 = sessionsStream.listen((sessions) {
      latestSessions = sessions;
      // ignore: discarded_futures
      emit();
    });
    final sub2 = userDocStream.listen((snap) {
      if (snap == null) {
        latestGoal = 10;
        latestAchievements = const <String, dynamic>{};
      } else {
        final data = snap.data();
        final g = (data?['dailyGoldGoal'] as int?) ?? 10;
        latestGoal = g <= 0 ? 10 : g;
        latestAchievements = (data?['achievements'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      }
      // ignore: discarded_futures
      emit();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
  });
});


