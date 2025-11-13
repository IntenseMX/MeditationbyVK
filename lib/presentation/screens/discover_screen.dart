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

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final appColors = Theme.of(context).extension<AppColors>();
    final query = ref.watch(meditationsQueryProvider);
    final bool isSearching = query.search.trim().isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discover',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What\'s your next step UP?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar with Filter
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 52,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
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
                            subtitle: '',
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
                padding: const EdgeInsets.all(20),
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
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: gradientText.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(name),
                          color: gradientText,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        name,
                        style: TextStyle(
                          color: gradientText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sessionCount sessions',
                        style: TextStyle(
                          color: gradientText.withOpacity(0.8),
                          fontSize: 14,
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
      case 'focus':
        return Icons.center_focus_strong;
      case 'sleep':
        return Icons.nightlight_round;
      case 'relaxation':
        return Icons.spa;
      case 'music':
        return Icons.music_note;
      case 'wisdom':
        return Icons.auto_awesome;
      case 'nature':
        return Icons.forest;
      case 'binural':
        return Icons.hearing;
      case 'jazz':
        return Icons.piano;
      default:
        return Icons.self_improvement;
    }
  }
}