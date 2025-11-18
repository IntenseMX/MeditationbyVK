import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../widgets/meditation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/meditations_list_provider.dart';
import '../../services/meditation_service.dart';
import '../../providers/category_provider.dart';
import '../../providers/category_map_provider.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showLogo = false;
  // Header stat box layout constants
  static const double _statBoxGap = 8.0;
  static const double _statBoxCompactWidth = 48.0;
  static const double _statBoxWideWidth = 88.0;
  static const double _burgerToStatsGap = 4.0;
  static const double _burgerMinSize = 40.0;
  static const double _burgerIconSize = 22.0;

  @override
  void initState() {
    super.initState();
    // Delay logo reveal to allow overlay animation to complete
    Future.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) {
        setState(() => _showLogo = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingMeditationsProvider);
    final recentAsync = ref.watch(recentlyAddedMeditationsProvider);
    final recommendedAsync = ref.watch(recommendedMeditationsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    // Memoized lookup from categoryId -> category name
    final categoryIdToName = ref.watch(categoryMapProvider);

    // Auth and progress
    final auth = ref.watch(authProvider);
    final progressAsync = ref.watch(progressDtoProvider);

    // Personalized greeting
    final displayName = auth.user?.displayName?.trim();
    final firstName = (displayName != null && displayName.isNotEmpty) ? displayName.split(' ').first : null;
    final greeting = 'Good ${_getTimeOfDay()}${firstName != null ? ', $firstName' : ''}!';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top icon row padding to match Discover (12, 8, 12, 4)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        // Burger icon at far left
                        IconButton(
                          icon: const Icon(Icons.menu),
                          color: Theme.of(context).colorScheme.onSurface,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: _burgerMinSize, minHeight: _burgerMinSize),
                          iconSize: _burgerIconSize,
                          onPressed: () {
                            final scaffold = Scaffold.maybeOf(context);
                            if (scaffold != null && scaffold.hasDrawer) {
                              scaffold.openDrawer();
                            } else {
                              debugPrint('[HOME] Menu tapped (no drawer available)');
                            }
                          },
                        ),
                        const SizedBox(width: _burgerToStatsGap),
                        // Centered stat boxes in available space
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return progressAsync.when(
                                loading: () => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _StatPill.skeleton(context),
                                    const SizedBox(width: 8),
                                    _StatPill.skeleton(context),
                                  ],
                                ),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (progress) {
                                  final weekly = (progress['weekly'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
                                  final int weeklyMinutes = (weekly['currentMinutes'] as int?) ?? 0;
                                  final int streak = (weekly['streak'] as int?) ?? 0;

                                  final String timeText = '$weeklyMinutes min this week';
                                  final String fullStreakText = '${streak}-day streak';
                                  final String compactStreakText = '$streak days';

                                  // Measure text widths with the same typography as pills
                                  final TextStyle measureStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
                                  double measureTextWidth(String s) {
                                    final painter = TextPainter(
                                      text: TextSpan(text: s, style: measureStyle),
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout();
                                    return painter.width;
                                  }

                                  // Pill width = horizontal padding (12*2) + icon(16) + spacer(8) + text width
                                  double pillWidth(String label) => 24 + 16 + 8 + measureTextWidth(label);
                                  const double gapBetweenPills = 8.0;

                                  final double neededFull = pillWidth(timeText) + gapBetweenPills + pillWidth(fullStreakText);
                                  final bool canShowFull = constraints.maxWidth >= neededFull;
                                  final String streakText = canShowFull ? fullStreakText : compactStreakText;

                                  debugPrint('[HOME_HEADER] Measured: width=${constraints.maxWidth}, need=$neededFull, full=$canShowFull, time="$timeText", streak="$streakText"');

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _StatPill(icon: Icons.timer, text: timeText),
                                      const SizedBox(width: gapBetweenPills),
                                      _StatPill(icon: Icons.local_fire_department, text: streakText),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        // Right: UP logo (unchanged)
                        Builder(
                          builder: (context) {
                            final appColors = Theme.of(context).extension<AppColors>();
                            return RepaintBoundary(
                              child: AnimatedOpacity(
                                opacity: _showLogo ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeIn,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: appColors?.pop ?? AppTheme.deepCrimson,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'UP',
                                      style: TextStyle(
                                        color: appColors?.onPop ?? AppTheme.warmSandBeige,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Greeting area retains standard 20px side padding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Recently Added belt (horizontal cards)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: recentAsync.when(
                  loading: () {
                    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
                    final highlight = Theme.of(context).colorScheme.surface.withOpacity(0.6);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Shimmer.fromColors(
                        baseColor: base,
                        highlightColor: highlight,
                        child: Row(
                          children: List.generate(4, (i) {
                            return Container(
                              width: 200,
                              height: 140,
                              margin: EdgeInsets.only(right: i == 3 ? 0 : 16),
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
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
                        final minutes = _minutesFromSeconds(m.durationSec);
                        final category = _resolveCategoryName(m.categoryId, categoryIdToName);
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          child: MeditationCard(
                            id: m.id,
                            title: m.title,
                            duration: minutes,
                            imageUrl: m.imageUrl ?? '',
                            gradientColors: gradient,
                            isPremium: m.isPremium ?? false,
                            onTap: () => context.push('/meditation-detail/${m.id}'),
                            compact: true,
                            category: category,
                            enableHero: false,
                          ),
                        );
                      },
                    );
                  },
                ),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
                height: 160,
                child: trendingAsync.when(
                  loading: () {
                    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
                    final highlight = Theme.of(context).colorScheme.surface.withOpacity(0.6);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Shimmer.fromColors(
                        baseColor: base,
                        highlightColor: highlight,
                        child: Row(
                          children: List.generate(4, (i) {
                            return Container(
                              width: 200,
                              height: 140,
                              margin: EdgeInsets.only(right: i == 3 ? 0 : 16),
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                  error: (e, _) => const Center(child: Text('Failed to load')),
                  data: (items) => TrendingBelt(items: items, categoryNames: categoryIdToName),
                ),
              ),
            ),

            // Section: Recommended For You
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Recommended For You',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Horizontal scroll for recommended
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: recommendedAsync.when(
                  loading: () {
                    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
                    final highlight = Theme.of(context).colorScheme.surface.withOpacity(0.6);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Shimmer.fromColors(
                        baseColor: base,
                        highlightColor: highlight,
                        child: Row(
                          children: List.generate(4, (i) {
                            return Container(
                              width: 200,
                              height: 140,
                              margin: EdgeInsets.only(right: i == 3 ? 0 : 16),
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
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
                        final minutes = _minutesFromSeconds(m.durationSec);
                        final category = _resolveCategoryName(m.categoryId, categoryIdToName);
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          child: MeditationCard(
                            id: m.id,
                            title: m.title,
                            duration: minutes,
                            imageUrl: m.imageUrl ?? '',
                            gradientColors: gradient,
                            isPremium: m.isPremium ?? false,
                            onTap: () => context.push('/meditation-detail/${m.id}'),
                            compact: true,
                            category: category,
                            enableHero: false,
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

class _CompactStatBox extends StatelessWidget {
  const _CompactStatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.showLabel,
    this.width,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool showLabel;
  final double? width;

  static const double _height = 40.0;
  static const double _radius = 16.0;
  static const double _iconSize = 14.0;

  const _CompactStatBox.skeleton({this.width, this.showLabel = false})
      : icon = Icons.circle,
        value = '',
        label = '';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final bool isSkeleton = value.isEmpty;
    final double resolvedWidth = width ?? _HomeScreenState._statBoxCompactWidth;

    return Container(
      width: resolvedWidth,
      height: _height,
      decoration: BoxDecoration(
        color: c.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top row: icon only
            Icon(icon, size: _iconSize, color: isSkeleton ? c.onSurface.withOpacity(0.25) : c.primary),
            const SizedBox(height: 2),
            // Bottom row: value + optional description
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isSkeleton
                    ? '—'
                    : (showLabel ? '$value $label' : value),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSkeleton ? c.onSurface.withOpacity(0.35) : c.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  static Widget skeleton(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 14, color: c.onSurface.withOpacity(0.25)),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: c.onSurface.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
class TrendingBelt extends StatefulWidget {
  const TrendingBelt({super.key, required this.items, required this.categoryNames});
  final List<MeditationListItem> items;
  final Map<String, String> categoryNames;

  @override
  State<TrendingBelt> createState() => _TrendingBeltState();
}

class _TrendingBeltState extends State<TrendingBelt> with SingleTickerProviderStateMixin {
  static const double _itemWidth = 200;
  static const double _spacing = 16;
  static const double _pixelsPerSecond = 20; // gentle auto-scroll speed
  static const int _virtualRepeatCount = 100; // large enough for illusion
  static const Duration _tick = Duration(milliseconds: 32); // ~31.25 FPS
  static const double _minStepPixels = 0.5; // avoid sub-pixel thrash

  late final ScrollController _controller;
  Timer? _scrollTimer;
  bool _userInteracting = false;
  double _accumulated = 0.0;

  List<MeditationListItem> get _source => widget.items;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _scrollTimer = Timer.periodic(_tick, _onTick);
  }

  void _onTick(Timer t) {
    if (!mounted || _userInteracting || !_controller.hasClients) return;
    final double seconds = _tick.inMilliseconds / 1000.0;
    final double delta = _pixelsPerSecond * seconds;
    _accumulated += delta;
    if (_accumulated < _minStepPixels) return;
    final double step = _accumulated.floorToDouble();
    _accumulated -= step;
    final maxExtent = _controller.position.maxScrollExtent;
    final newOffset = _controller.offset + step;
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
    _scrollTimer?.cancel();
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
        itemCount: _source.isEmpty ? 0 : _source.length * _virtualRepeatCount,
        itemBuilder: (context, index) {
          final meditation = _source[index % _source.length];
          final colors = Theme.of(context).colorScheme;
          final gradient = [colors.primary.value, colors.tertiary.value];
          final category = _resolveCategoryName(meditation.categoryId, widget.categoryNames);
          final minutes = _minutesFromSeconds(meditation.durationSec);
          return Container(
            width: _itemWidth,
            margin: const EdgeInsets.only(right: _spacing),
            child: MeditationCard(
              id: meditation.id,
              title: meditation.title,
              duration: minutes,
              imageUrl: meditation.imageUrl ?? '',
              gradientColors: gradient,
              isPremium: meditation.isPremium ?? false,
              onTap: () => context.push('/meditation-detail/${meditation.id}'),
              compact: true,
              category: category,
              enableHero: false,
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