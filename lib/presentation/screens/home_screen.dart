import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../widgets/meditation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/meditations_list_provider.dart';
import '../../services/meditation_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingMeditationsProvider);
    final recentAsync = ref.watch(recentlyAddedMeditationsProvider);
    final recommendedAsync = ref.watch(recommendedMeditationsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_getTimeOfDay()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Let\'s meditate',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Builder(
                          builder: (context) {
                            final appColors = Theme.of(context).extension<AppColors>();
                            return CircleAvatar(
                              radius: 24,
                              backgroundColor: appColors?.pop ?? AppTheme.deepCrimson,
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: appColors?.onPop ?? AppTheme.warmSandBeige,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Section: Recently Added
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  'Recently Added',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softCharcoal,
                  ),
                ),
              ),
            ),

            // Recently Added list (vertical cards)
            SliverToBoxAdapter(
              child: recentAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )),
                error: (e, _) => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Couldn't load meditations. Pull to retry."),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No meditations available yet'),
                    );
                  }
                  final colors = Theme.of(context).colorScheme;
                  final gradient = [colors.primary.value, colors.tertiary.value];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: list.map((m) {
                        final minutes = _minutesFromSeconds(m.durationSec);
                        return MeditationCard(
                          title: m.title,
                          subtitle: '',
                          duration: minutes,
                          imageUrl: m.imageUrl ?? '',
                          gradientColors: gradient,
                          isPremium: m.isPremium ?? false,
                          onTap: () => context.push('/player/${m.id}'),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // Section: Trending Now (top belt)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Now',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softCharcoal,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: AppTheme.deepCrimson,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal auto-scroll belt for trending
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: trendingAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Failed to load')),
                  data: (items) => TrendingBelt(items: items),
                ),
              ),
            ),

            // Section: Recommended
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softCharcoal,
                  ),
                ),
              ),
            ),

            // Horizontal scroll for recommended
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: recommendedAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Failed to load')),
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    final colors = Theme.of(context).colorScheme;
                    final gradient = [colors.primary.value, colors.tertiary.value];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final m = items[index];
                        final label = _formatDuration(m.durationSec);
                        final category = _prettyCategory(m.categoryId);
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: (m.imageUrl != null && m.imageUrl!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(m.imageUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: gradient
                                  .map((c) => Color(c).withOpacity(m.imageUrl != null && m.imageUrl!.isNotEmpty ? 0.45 : 1.0))
                                  .toList(),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () => context.push('/player/${m.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      label,
                                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class TrendingBelt extends StatefulWidget {
  const TrendingBelt({super.key, required this.items});
  final List<MeditationListItem> items;

  @override
  State<TrendingBelt> createState() => _TrendingBeltState();
}

class _TrendingBeltState extends State<TrendingBelt> with SingleTickerProviderStateMixin {
  static const double _itemWidth = 200;
  static const double _spacing = 16;
  static const double _pixelsPerSecond = 20; // gentle auto-scroll speed

  late final ScrollController _controller;
  late final Ticker _ticker;
  bool _userInteracting = false;

  List<MeditationListItem> get _source => widget.items;

  // We duplicate items to simulate an infinite belt
  List<MeditationListItem> get _loopedItems => List.generate(
        _source.isEmpty ? 0 : _source.length * 100,
        (i) => _source[i % _source.length],
      );

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _userInteracting || !_controller.hasClients) return;
    final double delta = _pixelsPerSecond / 60.0; // approx per-frame step
    final maxExtent = _controller.position.maxScrollExtent;
    final newOffset = _controller.offset + delta;
    if (newOffset >= maxExtent - (_itemWidth + _spacing)) {
      // jump back some distance to keep the illusion
      final jumpBack = maxExtent / 2;
      _controller.jumpTo(_controller.offset - jumpBack);
    } else {
      _controller.jumpTo(newOffset);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_source.isEmpty) {
      return const SizedBox.shrink();
    }
    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        final interacting = n.direction != ScrollDirection.idle;
        if (interacting != _userInteracting) {
          setState(() => _userInteracting = interacting);
        }
        return false;
      },
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _loopedItems.length,
        itemBuilder: (context, index) {
          final meditation = _loopedItems[index];
          final colors = Theme.of(context).colorScheme;
          final gradient = [colors.primary, colors.tertiary];
          final category = _prettyCategory(meditation.categoryId);
          final durationLabel = _formatDuration(meditation.durationSec);
          return Container(
            width: _itemWidth,
            margin: const EdgeInsets.only(right: _spacing),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: (meditation.imageUrl != null && meditation.imageUrl!.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(meditation.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  gradient[0].withOpacity(meditation.imageUrl != null && meditation.imageUrl!.isNotEmpty ? 0.45 : 1.0),
                  gradient[1].withOpacity(meditation.imageUrl != null && meditation.imageUrl!.isNotEmpty ? 0.45 : 1.0),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

int _minutesFromSeconds(int? sec) {
  if (sec == null || sec <= 0) return 1;
  return ((sec + 59) ~/ 60);
}

String _formatDuration(int? sec) {
  if (sec == null || sec <= 0) return '1 min';
  if (sec < 300) {
    final m = sec ~/ 60;
    final s = sec % 60;
    final mm = m.toString();
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
  final minutes = (sec / 60).ceil();
  return '$minutes min';
}

String _prettyCategory(String? categoryId) {
  if (categoryId == null || categoryId.trim().isEmpty) return 'General';
  final s = categoryId.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
}