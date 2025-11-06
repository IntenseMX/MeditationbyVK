import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/progress_service.dart';

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
  // 60 days gives us enough for weekly/monthly aggregations
  return svc.streamRecentSessions(daysBack: 60).map((sessions) {
    final now = DateTime.now().toUtc();
    final todayKey = DateTime.utc(now.year, now.month, now.day);

    // Goal minutes (fallback to 10 if not configured)
    const int goalMinutes = 10;

    // Daily totals (sum seconds, then round up to minutes)
    int todaySeconds = 0;
    for (final s in sessions) {
      final day = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
      if (day == todayKey) {
        todaySeconds += s.durationSec;
      }
    }
    final int todayMinutes = (todaySeconds + 59) ~/ 60;
    final int dailyPercentage = ((todayMinutes / goalMinutes) * 100).clamp(0, 100).toInt();

    // Weekly (last 7 days, oldest -> newest)
    final List<int> weeklyData = List<int>.filled(7, 0);
    for (int i = 6; i >= 0; i--) {
      final day = todayKey.subtract(Duration(days: 6 - i));
      final key = DateTime.utc(day.year, day.month, day.day);
      int seconds = 0;
      for (final s in sessions) {
        final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
        if (d == key) seconds += s.durationSec;
      }
      weeklyData[i] = (seconds + 59) ~/ 60;
    }
    final int weeklyCurrentMinutes = weeklyData.fold<int>(0, (a, b) => a + b);

    // Monthly (last 30 days)
    int monthlySeconds = 0;
    final monthStart = todayKey.subtract(const Duration(days: 29));
    for (final s in sessions) {
      final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
      if (!d.isBefore(monthStart) && !d.isAfter(todayKey)) {
        monthlySeconds += s.durationSec;
      }
    }
    final int monthlyMinutes = (monthlySeconds + 59) ~/ 60;

    // Streaks
    final streaks = svc.calculateStreak(sessions);

    // Build today's sessions list with denormalized titles
    final List<Map<String, dynamic>> todaySessions = sessions.where((s) {
      final d = DateTime.utc(s.completedAtUtc.year, s.completedAtUtc.month, s.completedAtUtc.day);
      return d == todayKey;
    }).map((s) => <String, dynamic>{
      'name': (s.meditationTitle == null || s.meditationTitle!.isEmpty) ? 'Meditation Session' : s.meditationTitle,
      'duration': (s.durationSec + 59) ~/ 60,
    }).toList();

    return <String, dynamic>{
      'daily': <String, dynamic>{
        'percentage': dailyPercentage,
        'minutesCompleted': todayMinutes,
        'goalMinutes': goalMinutes,
        'sessions': todaySessions,
      },
      'weekly': <String, dynamic>{
        'data': weeklyData,
        'streak': streaks.current,
        'currentMinutes': weeklyCurrentMinutes,
      },
      'monthly': <String, dynamic>{
        'streak': streaks.longest,
        'currentMinutes': monthlyMinutes,
      },
    };
  });
});


