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
  final Stream<int> goalStream = uid == null
      ? Stream<int>.value(10)
      : FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .map((snap) {
            final g = (snap.data()?['dailyGoldGoal'] as int?) ?? 10;
            return g <= 0 ? 10 : g;
          })
          .distinct();
  final sessionsStream = svc.streamRecentSessions(daysBack: 60);

  // Combine sessions stream with goal stream to emit updates on either change
  return Stream<Map<String, dynamic>>.multi((controller) {
    List<SessionRecord> latestSessions = const <SessionRecord>[];
    var latestGoal = 10;

    Future<void> emit() async {
      final now = DateTime.now().toUtc();
      final todayKey = DateTime.utc(now.year, now.month, now.day);

      // Daily totals (sum seconds, then round up to minutes)
      int todaySeconds = 0;
      for (final s in latestSessions) {
        final day = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
        if (day == todayKey) {
          todaySeconds += (s.durationSec as num).toInt();
        }
      }
      final int todayMinutes = (todaySeconds + 59) ~/ 60;
      final int safeGoal = latestGoal <= 0 ? 10 : latestGoal;
      final int dailyPercentage = ((todayMinutes / safeGoal) * 100).clamp(0, 100).toInt();

      // Weekly (last 7 days, oldest -> newest)
      final List<int> weeklyData = List<int>.filled(7, 0);
      for (int i = 6; i >= 0; i--) {
        final day = todayKey.subtract(Duration(days: 6 - i));
        final key = DateTime.utc(day.year, day.month, day.day);
        int seconds = 0;
        for (final s in latestSessions) {
          final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
          if (d == key) seconds += (s.durationSec as num).toInt();
        }
        weeklyData[i] = (seconds + 59) ~/ 60;
      }
      final int weeklyCurrentMinutes = weeklyData.fold<int>(0, (a, b) => a + b);

      // Monthly (last 30 days)
      int monthlySeconds = 0;
      final monthStart = todayKey.subtract(const Duration(days: 29));
      for (final s in latestSessions) {
        final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
        if (!d.isBefore(monthStart) && !d.isAfter(todayKey)) {
          monthlySeconds += (s.durationSec as num).toInt();
        }
      }
      final int monthlyMinutes = (monthlySeconds + 59) ~/ 60;
      // Per-day data for monthly chart (30 bars, oldest -> newest)
      final List<int> monthlyData = List<int>.filled(30, 0);
      for (int i = 0; i < 30; i++) {
        final day = monthStart.add(Duration(days: i));
        final key = DateTime.utc(day.year, day.month, day.day);
        int seconds = 0;
        for (final s in latestSessions) {
          final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
          if (d == key) seconds += (s.durationSec as num).toInt();
        }
        monthlyData[i] = (seconds + 59) ~/ 60;
      }

      // Streaks
      final streaks = svc.calculateStreak(latestSessions);

      // Build today's sessions list with denormalized titles
      final todaysSessions = latestSessions.where((s) {
        final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
        return d == todayKey;
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
        });
      }
    }

    final sub1 = sessionsStream.listen((sessions) {
      latestSessions = sessions;
      // ignore: discarded_futures
      emit();
    });
    final sub2 = goalStream.listen((goal) {
      latestGoal = goal;
      // ignore: discarded_futures
      emit();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
  });
});


