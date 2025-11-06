import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/progress_provider.dart';
import '../../core/theme.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

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
        print('[Progress] DATA RECEIVED: $m');
        return m;
      },
      loading: () {
        print('[Progress] LOADING...');
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
        print('[Progress] ERROR: $e');
        print('[Progress] STACK: $st');
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
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                tabs: const [
                  Tab(
                    height: 48,
                    child: Text('Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Tab(
                    height: 48,
                    child: Text('Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Tab(
                    height: 48,
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
                  _buildWeekView(progressData['weekly'] as Map<String, dynamic>),
                  _buildMonthView(progressData['monthly'] as Map<String, dynamic>),
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
                const Text(
                  'Today\'s Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...sessions.map((session) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
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

  Widget _buildWeekView(Map<String, dynamic> weeklyData) {
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
                      final maxValue = data.reduce((a, b) => a > b ? a : b);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              width: 30,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: value > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              height: value > 0 ? (value / maxValue) * 100 : 10,
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

  Widget _buildMonthView(Map<String, dynamic> monthlyData) {
    final streak = monthlyData['streak'] as int;
    final currentMinutes = monthlyData['currentMinutes'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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