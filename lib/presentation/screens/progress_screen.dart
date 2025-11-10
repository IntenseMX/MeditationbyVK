import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/progress_provider.dart';
import '../../core/theme.dart';
import '../widgets/goal_settings_dialog.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  // Tab UI configuration (avoid magic numbers)
  static const double _tabHeight = 48;
  static const EdgeInsets _tabLabelPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
  static const EdgeInsets _tabIndicatorPadding = EdgeInsets.all(4);
  static const double _tabIndicatorRadius = 12;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dtoAsync = ref.watch(progressDtoProvider);
    final Map<String, dynamic> progressData = dtoAsync.when(
      data: (m) {
        return m;
      },
      loading: () {
        return {
          'daily': <String, dynamic>{
            'percentage': 0,
            'minutesCompleted': 0,
            'goalMinutes': 10,
            'sessions': <Map<String, dynamic>>[],
          },
          'weekly': <String, dynamic>{
            'data': <int>[0, 0, 0, 0, 0, 0, 0],
            'streak': 0,
            'currentMinutes': 0,
          },
          'monthly': <String, dynamic>{
            'streak': 0,
            'currentMinutes': 0,
          },
        };
      },
      error: (e, st) {
        return {
          'daily': <String, dynamic>{
            'percentage': 0,
            'minutesCompleted': 0,
            'goalMinutes': 10,
            'sessions': <Map<String, dynamic>>[],
          },
          'weekly': <String, dynamic>{
            'data': <int>[0, 0, 0, 0, 0, 0, 0],
            'streak': 0,
            'currentMinutes': 0,
          },
          'monthly': <String, dynamic>{
            'streak': 0,
            'currentMinutes': 0,
          },
        };
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your meditation journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(_tabIndicatorRadius),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: _tabIndicatorPadding,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelPadding: _tabLabelPadding,
                tabs: const [
                  Tab(
                    height: _tabHeight,
                    child: Text('Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Tab(
                    height: _tabHeight,
                    child: Text('Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Tab(
                    height: _tabHeight,
                    child: Text('Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDayView(progressData['daily'] as Map<String, dynamic>),
                  _buildWeekView(
                    progressData['weekly'] as Map<String, dynamic>,
                    (progressData['daily'] as Map<String, dynamic>)['goalMinutes'] as int,
                  ),
                  _buildMonthView(
                    progressData['monthly'] as Map<String, dynamic>,
                    (progressData['daily'] as Map<String, dynamic>)['goalMinutes'] as int,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView(Map<String, dynamic> dailyData) {
    final percentage = dailyData['percentage'] as int;
    final minutesCompleted = dailyData['minutesCompleted'] as int;
    final goalMinutes = dailyData['goalMinutes'] as int;
    final sessions = dailyData['sessions'] as List<Map<String, dynamic>>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Circular Progress
          Container(
            height: 200,
            width: 200,
            margin: const EdgeInsets.symmetric(vertical: 24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'of daily goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Minutes',
                  '$minutesCompleted',
                  Icons.timer,
                  Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Goal',
                  '$goalMinutes min',
                  Icons.flag,
                  Theme.of(context).colorScheme.primary,
                  onTap: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => GoalSettingsDialog(initialMinutes: goalMinutes),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Daily goal updated')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Sessions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$minutesCompleted min',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sessions.map((session) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Builder(builder: (context) {
                        final String? url = (session['imageUrl'] as String?);
                        if (url != null && url.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              url,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, __) => Icon(
                                Icons.music_note,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 20,
                              ),
                            ),
                          );
                        }
                        return Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          session['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${session['duration']} min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(Map<String, dynamic> weeklyData, int goalMinutes) {
    final data = weeklyData['data'] as List<int>;
    final streak = weeklyData['streak'] as int;
    final currentMinutes = weeklyData['currentMinutes'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Streak Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Builder(builder: (context) {
              final gradientText = Theme.of(context).extension<AppColors>()?.textOnGradient
                  ?? Theme.of(context).colorScheme.onInverseSurface;
              return Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: gradientText,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$streak days',
                    style: TextStyle(
                      color: gradientText,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Current streak',
                    style: TextStyle(
                      color: gradientText.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),

          // Weekly Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                      final value = data[index];
                      final int safeGoal = (goalMinutes <= 0) ? 10 : goalMinutes;
                      final double ratio = value <= 0 ? 0.0 : (value / safeGoal);
                      final bool reachedGoal = value >= safeGoal;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: 30,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double maxH = constraints.maxHeight;
                                  final double fillH = (maxH * ratio.clamp(0.0, 1.0));
                                  final double minVisible = 10.0;
                                  final Color baseColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
                                  final Color fillColor = Theme.of(context).colorScheme.primary;
                                  return Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        height: maxH,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: baseColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      if (fillH > 0)
                                        Container(
                                          height: fillH.clamp(minVisible, maxH),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: fillColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          Text(
                            days[index],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This week',
                  '$currentMinutes min',
                  Icons.calendar_today,
                  Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Average',
                  '${(currentMinutes / 7).round()} min/day',
                  Icons.insights,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(Map<String, dynamic> monthlyData, int goalMinutes) {
    final streak = monthlyData['streak'] as int;
    final currentMinutes = monthlyData['currentMinutes'] as int;
    final data = (monthlyData['data'] as List<dynamic>?)?.cast<int>() ?? const <int>[];
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final monthStartLocal = todayLocal.subtract(const Duration(days: 29));
    final List<DateTime> tickDates = <DateTime>[
      monthStartLocal,
      monthStartLocal.add(const Duration(days: 6)),
      monthStartLocal.add(const Duration(days: 13)),
      monthStartLocal.add(const Duration(days: 20)),
      monthStartLocal.add(const Duration(days: 27)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Monthly Chart (30 days)
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double availableWidth = constraints.maxWidth;
                      const int days = 30;
                      final double spacing = 4.0;
                      final double totalSpacing = spacing * (days - 1);
                      final double barWidth = ((availableWidth - totalSpacing) / days).clamp(4.0, 12.0);
                      final int safeGoal = goalMinutes <= 0 ? 10 : goalMinutes;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(days, (index) {
                          final int value = (index < data.length) ? data[index] : 0;
                          final double ratio = value <= 0 ? 0.0 : (value / safeGoal);

                          return Padding(
                            padding: EdgeInsets.only(right: index == days - 1 ? 0 : spacing),
                            child: SizedBox(
                              width: barWidth,
                              child: LayoutBuilder(
                                builder: (context, inner) {
                                  final double maxH = inner.maxHeight;
                                  final double fillH = (maxH * ratio.clamp(0.0, 1.0));
                                  final double minVisible = 8.0;
                                  final Color baseColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
                                  final Color fillColor = Theme.of(context).colorScheme.primary;
                                  return Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        height: maxH,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: baseColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      if (fillH > 0)
                                        Container(
                                          height: fillH.clamp(minVisible, maxH),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: fillColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: tickDates.map((d) {
                    final dayStr = d.day.toString().padLeft(2, '0');
                    return Text(
                      dayStr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Monthly Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.tertiary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$streak',
                      style: TextStyle(
                        color: AppTheme.warmSandBeige,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Day streak',
                      style: TextStyle(
                        color: AppTheme.warmSandBeige.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.warmSandBeige.withOpacity(0.3),
                ),
                Column(
                  children: [
                    Text(
                      '$currentMinutes',
                      style: TextStyle(
                        color: AppTheme.warmSandBeige,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total minutes',
                      style: TextStyle(
                        color: AppTheme.warmSandBeige.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Achievement Badges
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAchievementBadge('7 Days', Icons.looks_one, true),
                    _buildAchievementBadge('30 Days', Icons.looks_two, false),
                    _buildAchievementBadge('100 Days', Icons.looks_3, false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }

  Widget _buildAchievementBadge(String label, IconData icon, bool achieved) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: achieved
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: achieved
                ? Theme.of(context).colorScheme.onTertiary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: achieved
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}