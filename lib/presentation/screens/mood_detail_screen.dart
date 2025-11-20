import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/moods.dart';
import '../../domain/mood.dart';
import '../../providers/category_map_provider.dart';
import '../../providers/meditations_list_provider.dart';
import '../../services/meditation_service.dart';
import '../widgets/meditation_card.dart';
import '../widgets/meditation_compact_card.dart';
import '../../core/theme.dart';

class MoodDetailScreen extends ConsumerStatefulWidget {
  const MoodDetailScreen({super.key, required this.moodId});
  final String moodId;

  @override
  ConsumerState<MoodDetailScreen> createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends ConsumerState<MoodDetailScreen> {
  static const double _sectionSpacing = 24.0;
  static const double _pagePadding = 20.0;

  bool _favorite = false; // Local MVP-only state for favorite

  @override
  Widget build(BuildContext context) {
    final Mood mood = MoodConfig.findById(widget.moodId) ?? MoodConfig.moods.first;
    final categoryMap = ref.watch(categoryMapProvider);
    final svc = ref.watch(meditationServiceProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(mood.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Decorative mood card
                Center(child: _DecorativeHeaderCard(mood: mood)),
                const SizedBox(height: _sectionSpacing),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: _favorite ? 'Unfavorite' : 'Favorite',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _favorite = !_favorite);
                            debugPrint('[MOOD_DETAIL] Favorite toggled id=${mood.id} value=$_favorite');
                          },
                          icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
                        ),
                        IconButton(
                          tooltip: 'Share',
                          onPressed: () {
                            final text = '${mood.name} — ${mood.tagline}\n${mood.description}';
                            Share.share(text);
                            debugPrint('[MOOD_DETAIL] Share clicked id=${mood.id}');
                          },
                          icon: const Icon(Icons.share),
                        ),
                      ],
                    ),
                    // Placeholder third action (download reserved for future)
                    IconButton(
                      tooltip: 'More',
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Tagline & Description
                Text(
                  mood.tagline,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mood.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: _sectionSpacing),
                // Category chips (mapped to category names where possible)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: mood.categoryIds.map((id) {
                    final String label = categoryMap[id] ?? _prettyCategory(id);
                    return Chip(label: Text(label));
                  }).toList(),
                ),

                const SizedBox(height: _sectionSpacing),
                // Related meditations header
                Text(
                  'Recommended for this mood',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Related meditations list (horizontal strip of compact cards, tag-based)
                StreamBuilder<List<MeditationListItem>>(
                  stream: svc.streamByTags(mood.tags, limit: 10),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final items = snapshot.data ?? const <MeditationListItem>[];
                    if (items.isEmpty) {
                      return Text(
                        'No related meditations yet.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      );
                    }
                    return SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final m = items[index];
                          return Padding(
                            padding: EdgeInsets.only(right: index < items.length - 1 ? 12 : 0),
                            child: MeditationCompactCard(
                              meditation: m,
                              onTap: () => context.push('/meditation-detail/${m.id}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: _sectionSpacing),

                // ===== PLACEHOLDER START: Hardcoded comments for UI preview ONLY =====
                // Remove this entire container when implementing real comments.
                // Replace with provider-backed list per MEDITATION_SCREEN_REDESIGN.md.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16), // existing style
                    border: Border.all(color: cs.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Placeholder list (hardcoded)
                      ...const <Map<String, String>>[
                        {
                          'name': 'Aurora',
                          'time': '2d ago',
                          'text': 'Fell asleep so peacefully. The breathing part really settled my mind.'
                        },
                        {
                          'name': 'Noah',
                          'time': '4d ago',
                          'text': 'Listened on a lunch break—felt grounded for the rest of the day.'
                        },
                        {
                          'name': 'Mila',
                          'time': '1w ago',
                          'text': 'Gentle voice and pacing. Helped me release a lot of tension.'
                        },
                        {
                          'name': 'Lucas',
                          'time': '2w ago',
                          'text': 'Used it before a big meeting. Anxiety dialed way down. Thank you!'
                        },
                        {
                          'name': 'Zara',
                          'time': '3w ago',
                          'text': 'Great visualization. I keep coming back to this one.'
                        },
                      ].map((c) {
                        final name = c['name']!;
                        final time = c['time']!;
                        final text = c['text']!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: cs.primary.withOpacity(0.1),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  text,
                                  style: TextStyle(color: cs.onSurface),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // ===== PLACEHOLDER END =====

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveCategoryName(String? categoryId, Map<String, String> idToName) {
    if (categoryId == null || categoryId.trim().isEmpty) return 'General';
    final byName = idToName[categoryId];
    if (byName != null && byName.trim().isNotEmpty) return byName;
    return _prettyCategory(categoryId);
  }

  String _prettyCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) return 'General';
    final s = categoryId.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }

  int _minutesFromSeconds(int? sec) {
    if (sec == null || sec <= 0) return 1;
    return ((sec + 59) ~/ 60);
  }
}

class _DecorativeHeaderCard extends StatelessWidget {
  const _DecorativeHeaderCard({required this.mood});
  final Mood mood;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textOnGradient = Theme.of(context).extension<AppColors>()?.textOnGradient ?? Colors.white;
    final List<Color> gradient = _colorsForMood(context, mood);

    return SizedBox(
      width: MoodConfig.headerCardWidth,
      height: MoodConfig.headerCardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mood.icon, size: 56, color: textOnGradient),
              const SizedBox(height: 8),
              Text(
                mood.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textOnGradient,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _colorsForMood(BuildContext context, Mood mood) {
    final cs = Theme.of(context).colorScheme;
    switch (mood.id) {
      case 'calm':
        return <Color>[cs.primary, cs.tertiary];
      case 'focus':
        return <Color>[cs.secondary, cs.primary];
      case 'sleep':
        return <Color>[cs.tertiary, cs.surface];
      default:
        return <Color>[cs.primary, cs.tertiary];
    }
  }
}


