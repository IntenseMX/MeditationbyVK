// Dummy data for visual testing and development
// This will be replaced with Firebase data in production

class DummyData {
  static const List<Map<String, dynamic>> meditations = [
    {
      'id': '1',
      'title': 'Wondering mind',
      'subtitle': 'Guided meditation for focus',
      'duration': 12,
      'category': 'Focus',
      'difficulty': 'Beginner',
      'rating': 4.8,
      'isGuided': true,
      'isPremium': false,
      'gradientColors': [0xFF64B5F6, 0xFF42A5F5], // Blue gradient
      'imageUrl': 'https://picsum.photos/400/300?random=1',
    },
    {
      'id': '2',
      'title': 'Deep Sleep',
      'subtitle': 'Fall asleep in minutes',
      'duration': 15,
      'category': 'Sleep',
      'difficulty': 'Beginner',
      'rating': 4.9,
      'isGuided': true,
      'isPremium': true,
      'gradientColors': [0xFF7E57C2, 0xFF5E35B1], // Purple gradient
      'imageUrl': 'https://picsum.photos/400/300?random=2',
    },
    {
      'id': '3',
      'title': 'Morning Zen',
      'subtitle': 'Start your day mindfully',
      'duration': 10,
      'category': 'Morning',
      'difficulty': 'Beginner',
      'rating': 4.7,
      'isGuided': true,
      'isPremium': false,
      'gradientColors': [0xFFFFB74D, 0xFFFFA726], // Orange gradient
      'imageUrl': 'https://picsum.photos/400/300?random=3',
    },
    {
      'id': '4',
      'title': 'Stress Relief',
      'subtitle': 'Release tension and anxiety',
      'duration': 20,
      'category': 'Relaxation',
      'difficulty': 'Intermediate',
      'rating': 4.8,
      'isGuided': true,
      'isPremium': false,
      'gradientColors': [0xFF4DB6AC, 0xFF26A69A], // Teal gradient
      'imageUrl': 'https://picsum.photos/400/300?random=4',
    },
    {
      'id': '5',
      'title': 'Ocean Waves',
      'subtitle': 'Nature sounds for calm',
      'duration': 25,
      'category': 'Nature',
      'difficulty': 'Beginner',
      'rating': 4.6,
      'isGuided': false,
      'isPremium': true,
      'gradientColors': [0xFF4FC3F7, 0xFF29B6F6], // Light blue gradient
      'imageUrl': 'https://picsum.photos/400/300?random=5',
    },
    {
      'id': '6',
      'title': 'Focus Flow',
      'subtitle': 'Deep work concentration',
      'duration': 30,
      'category': 'Focus',
      'difficulty': 'Advanced',
      'rating': 4.9,
      'isGuided': true,
      'isPremium': true,
      'gradientColors': [0xFFAB47BC, 0xFF9C27B0], // Pink gradient
      'imageUrl': 'https://picsum.photos/400/300?random=6',
    },
  ];

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'focus',
      'name': 'Focus',
      'sessionCount': 26,
      'gradientColors': [0xFF64B5F6, 0xFF42A5F5],
      'icon': 'focus',
    },
    {
      'id': 'sleep',
      'name': 'Sleep',
      'sessionCount': 12,
      'gradientColors': [0xFF7E57C2, 0xFF5E35B1],
      'icon': 'sleep',
    },
    {
      'id': 'relaxation',
      'name': 'Relaxation',
      'sessionCount': 18,
      'gradientColors': [0xFF4DB6AC, 0xFF26A69A],
      'icon': 'relax',
    },
    {
      'id': 'music',
      'name': 'Music',
      'sessionCount': 65,
      'gradientColors': [0xFFFF7043, 0xFFFF5722],
      'icon': 'music',
    },
    {
      'id': 'wisdom',
      'name': 'Wisdom',
      'sessionCount': 11,
      'gradientColors': [0xFFAB47BC, 0xFF9C27B0],
      'icon': 'wisdom',
    },
    {
      'id': 'nature',
      'name': 'Nature',
      'sessionCount': 52,
      'gradientColors': [0xFF66BB6A, 0xFF4CAF50],
      'icon': 'nature',
    },
    {
      'id': 'binural',
      'name': 'Binural',
      'sessionCount': 18,
      'gradientColors': [0xFFFFB74D, 0xFFFFA726],
      'icon': 'binural',
    },
    {
      'id': 'jazz',
      'name': 'Jazz',
      'sessionCount': 19,
      'gradientColors': [0xFF5C6BC0, 0xFF3F51B5],
      'icon': 'jazz',
    },
  ];

  static final Map<String, dynamic> progressData = {
    'daily': {
      'percentage': 34,
      'minutesCompleted': 27,
      'goalMinutes': 10,
      'sessions': [
        {'name': "Lion's breath", 'duration': 27, 'isGuided': true},
        {'name': 'Gentle Rain', 'duration': 2, 'isGuided': false},
      ],
    },
    'weekly': {
      'currentMinutes': 9,
      'previousMinutes': 7,
      'currentPercentage': 4,
      'streak': 3,
      'data': [6, 0, 5, 4, 10, 12, 10], // Sun to Sat
    },
    'monthly': {
      'currentMinutes': 6,
      'previousMinutes': 12,
      'currentPercentage': 11,
      'streak': 10,
      'data': List.generate(30, (i) => i % 3 == 0 ? 0 : (i % 7) + 5),
    },
  };

  static const Map<String, dynamic> userProfile = {
    'name': 'Guest User',
    'email': 'guest@meditation.app',
    'isPremium': false,
    'weeklyGoal': 10, // minutes per day
    'currentStreak': 3,
    'longestStreak': 15,
    'totalSessions': 42,
    'totalMinutes': 580,
  };

  static const List<String> relaxingSounds = [
    'Ocean Sounds',
    'Birds Singing',
    'Binural Beats',
    'Gong Sounds',
    'Sounds of Rain',
    'White Noise',
    'Lo Fi Beats',
    'Fire Cracking',
  ];
}