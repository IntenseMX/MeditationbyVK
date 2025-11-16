import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../../providers/category_provider.dart';
import '../../services/category_service.dart';
import '../../core/theme.dart';
import '../../core/animation_constants.dart';
import 'category_meditations_screen.dart';
import '../../providers/meditations_list_provider.dart';
import '../widgets/meditation_card.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/category_map_provider.dart';

// Local UI state: whether the inline search bar is visible
class _SearchVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}
final discoverSearchVisibleProvider = NotifierProvider<_SearchVisibleNotifier, bool>(
  () => _SearchVisibleNotifier(),
);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final appColors = Theme.of(context).extension<AppColors>();
    final query = ref.watch(meditationsQueryProvider);
    final recommendedAsync = ref.watch(recommendedMeditationsProvider);
    final categoryIdToName = ref.watch(categoryMapProvider);
    final bool isSearching = query.search.trim().isNotEmpty;
    final bool isSearchVisible = ref.watch(discoverSearchVisibleProvider);
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: const [
              ListTile(leading: Icon(Icons.home_outlined), title: Text('Home')),
              ListTile(leading: Icon(Icons.person_outline), title: Text('Profile')),
              ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top icon row (menu + search)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: AnimationDurations.short3,
                        child: Icon(
                          isSearchVisible ? Icons.close : Icons.search,
                          key: ValueKey<bool>(isSearchVisible),
                        ),
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        ref.read(discoverSearchVisibleProvider.notifier).toggle();
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s your next step UP?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Animated search reveal
                    AnimatedSize(
                      duration: AnimationDurations.medium2,
                      curve: AnimationCurves.emphasized,
                      child: AnimatedSwitcher(
                        duration: AnimationDurations.medium2,
                        switchInCurve: AnimationCurves.emphasized,
                        switchOutCurve: AnimationCurves.emphasized,
                        child: isSearchVisible
                            ? _SearchBar(ref: ref, scheme: Theme.of(context).colorScheme)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories / Search Results Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isSearching ? 'Results' : 'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (isSearching)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: ref.watch(meditationsStreamProvider).when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  ),
                  error: (e, _) => const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(20), child: Text('Error loading results')),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(padding: EdgeInsets.all(20), child: Text('No results')),
                      );
                    }
                    final colors = Theme.of(context).colorScheme;
                    final gradient = [colors.primary.value, colors.tertiary.value];
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final m = items[index];
                          final minutes = ((m.durationSec ?? 0) + 59) ~/ 60;
                          return MeditationCard(
                            id: m.id,
                            title: m.title,
                            duration: minutes,
                            imageUrl: m.imageUrl ?? '',
                            gradientColors: gradient,
                            isPremium: m.isPremium ?? false,
                            onTap: () => context.push('/meditation-detail/${m.id}'),
                          );
                        },
                        childCount: items.length,
                      ),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CategoryGridConfig.gridPaddingH,
                  vertical: CategoryGridConfig.gridPaddingV,
                ),
                sliver: categoriesAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  ),
                  error: (e, _) => const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(20), child: Text('Failed to load categories')),
                  ),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(padding: EdgeInsets.all(20), child: Text('No categories yet')),
                      );
                    }
                    // Compute responsive column count based on available width and ensure title lane is wide enough
                    final width = MediaQuery.of(context).size.width;
                    final available = width - (CategoryGridConfig.gridPaddingH * 2);
                    // Try 3 columns first
                    int crossAxisCount = 3;
                    double tileWidth3 = (available - (CategoryGridConfig.gridSpacing * (crossAxisCount - 1))) / crossAxisCount;
                    double textLane3 = tileWidth3 - (CategoryGridConfig.cardPadding * 2);
                    if (textLane3 < CategoryGridConfig.minTitleTextWidthDp) {
                      crossAxisCount = 2;
                    }
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: CategoryGridConfig.gridSpacing,
                        mainAxisSpacing: CategoryGridConfig.gridSpacing,
                        childAspectRatio: CategoryGridConfig.childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          return _buildCategoryCard(context, category);
                        },
                        childCount: categories.length,
                      ),
                    );
                  },
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
                        final minutes = ((m.durationSec ?? 0) <= 0) ? 1 : ((m.durationSec! + 59) ~/ 60);
                        final category = categoryIdToName[m.categoryId] ?? '';
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

  Widget _buildCategoryCard(BuildContext context, CategoryItem category) {
    final appColors = Theme.of(context).extension<AppColors>();
    final gradientText = appColors?.textOnGradient ?? Theme.of(context).colorScheme.onInverseSurface;
    final String name = category.name;
    final List<int> gradientColors = [
      Theme.of(context).colorScheme.primary.value,
      Theme.of(context).colorScheme.tertiary.value,
    ];
    final int sessionCount = category.meditationCount;

    return OpenContainer(
      transitionDuration: AnimationDurations.medium4,
      transitionType: ContainerTransitionType.fade,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      openShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      closedColor: Colors.transparent,
      openColor: Theme.of(context).colorScheme.surface,
      openBuilder: (context, _) => CategoryMeditationsScreen(categoryId: category.id),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors.map((color) => Color(color)).toList(),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(gradientColors[0]).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(CategoryGridConfig.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: CategoryGridConfig.iconRegionHeight,
                        child: Center(
                          child: Container(
                            width: CategoryGridConfig.iconContainerSize,
                            height: CategoryGridConfig.iconContainerSize,
                            decoration: BoxDecoration(
                              color: gradientText.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(name),
                              color: gradientText,
                              size: CategoryGridConfig.iconSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: CategoryGridConfig.iconTitleGap),
                      SizedBox(
                        height: CategoryGridConfig.titleAreaHeight,
                        child: Center(
                          child: Text(
                            name,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: gradientText,
                              fontSize: CategoryGridConfig.titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sessionCount sessions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: gradientText.withOpacity(0.8),
                          fontSize: CategoryGridConfig.subtitleFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mornings':
        return Icons.wb_sunny;
      case 'manifest':
        return Icons.psychology;
      case 'sleep':
        return Icons.nightlight_round;
      case 'breathing':
        return Icons.air;
      case 'spa':
        return Icons.spa;
      case 'stress':
        return Icons.heart_broken;
      case 'anxiety':
        return Icons.cloud; // Cloud instead of band-aid - much more zen
      case 'music':
        return Icons.music_note;
      case 'for women':
        return Icons.woman;
      case 'for parents':
        return Icons.family_restroom;
      case 'challenge': // Singular, not plural
        return Icons.military_tech;
      case 'courses':
        return Icons.school;
      default:
        return Icons.self_improvement;
    }
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ref, required this.scheme});
  final WidgetRef ref;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 52,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outline.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      final current = ref.read(meditationsQueryProvider);
                      ref.read(meditationsQueryProvider.notifier).setQuery(
                        current.copyWith(search: value, status: 'published'),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.tune,
            color: scheme.onPrimary,
          ),
        ),
      ],
    );
  }
}