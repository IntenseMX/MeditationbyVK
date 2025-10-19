import 'package:flutter/material.dart';
import '../../data/datasources/dummy_data.dart';
import '../../core/theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
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
    final progressData = DummyData.progressData;

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
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
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
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.richTaupe.withOpacity(0.2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.deepCrimson,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppTheme.warmSandBeige,
                unselectedLabelColor: AppTheme.softCharcoal,
                tabs: const [
                  Tab(text: 'Day'),
                  Tab(text: 'Week'),
                  Tab(text: 'Month'),
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
                    backgroundColor: AppTheme.richTaupe.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepCrimson),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softCharcoal,
                      ),
                    ),
                    Text(
                      'of daily goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.richTaupe,
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
                  AppTheme.amberBrown,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Goal',
                  '$goalMinutes min',
                  Icons.flag,
                  AppTheme.deepCrimson,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Sessions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.richTaupe.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softCharcoal,
                  ),
                ),
                const SizedBox(height: 12),
                ...sessions.map((session) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        session['isGuided'] ? Icons.headset : Icons.music_note,
                        color: AppTheme.agedGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          session['name'] as String,
                          style: TextStyle(
                            color: AppTheme.softCharcoal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${session['duration']} min',
                        style: TextStyle(
                          color: AppTheme.richTaupe,
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
                colors: [AppTheme.deepCrimson, AppTheme.amberBrown],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.warmSandBeige,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  '$streak days',
                  style: TextStyle(
                    color: AppTheme.warmSandBeige,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Current streak',
                  style: TextStyle(
                    color: AppTheme.warmSandBeige.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Weekly Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.richTaupe.withOpacity(0.2),
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
                    color: AppTheme.softCharcoal,
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
                                color: value > 0 ? AppTheme.deepCrimson : AppTheme.richTaupe.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              height: value > 0 ? (value / maxValue) * 100 : 10,
                            ),
                          ),
                          Text(
                            days[index],
                            style: TextStyle(
                              color: AppTheme.richTaupe,
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
                  AppTheme.agedGold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Average',
                  '${(currentMinutes / 7).round()} min/day',
                  Icons.insights,
                  AppTheme.deepCrimson,
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
                colors: [AppTheme.agedGold, AppTheme.amberBrown],
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
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.richTaupe.withOpacity(0.2),
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
                    color: AppTheme.softCharcoal,
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
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.richTaupe.withOpacity(0.2),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softCharcoal,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.richTaupe,
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
            color: achieved ? AppTheme.agedGold : AppTheme.richTaupe.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: achieved ? AppTheme.warmSandBeige : AppTheme.richTaupe,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: achieved ? AppTheme.softCharcoal : AppTheme.richTaupe,
            fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}