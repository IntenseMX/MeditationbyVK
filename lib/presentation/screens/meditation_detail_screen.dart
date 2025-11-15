import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/category_map_provider.dart';
import '../../services/meditation_service.dart';
import '../../providers/favorites_provider.dart';


class MeditationDetailScreen extends ConsumerStatefulWidget {
  const MeditationDetailScreen({super.key, required this.meditationId});
  final String meditationId;

  @override
  ConsumerState<MeditationDetailScreen> createState() => _MeditationDetailScreenState();
}

class _MeditationDetailScreenState extends ConsumerState<MeditationDetailScreen> {
  static const double _sectionSpacing = 32.0;
  static const double _pagePadding = 20.0;
  static const double _cardCornerRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meditationAsync = ref.watch(meditationByIdProvider(widget.meditationId));
    final categoryMap = ref.watch(categoryMapProvider);
    final isFavorited = ref.watch(isFavoritedProvider(widget.meditationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: meditationAsync.when(
          loading: () => _buildLoading(context),
          error: (e, _) => _buildError(context, e),
          data: (data) {
            if (data == null) {
              return _buildUnavailable(context);
            }

            final String id = widget.meditationId;
            final String title = (data['title'] as String?)?.trim() ?? 'Untitled';
            final String description = (data['description'] as String?)?.trim() ?? '';
            final String imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
            final int? durationSec = data['durationSec'] is int ? data['durationSec'] as int : null;
            final String? categoryId = (data['categoryId'] as String?);
            final String? categoryName = categoryId == null ? null : (categoryMap[categoryId] ?? _prettyCategory(categoryId));
            final bool isPremium = (data['isPremium'] as bool?) ?? false;
            final String? difficulty = (data['difficulty'] as String?);
            final List<String> tags = ((data['tags'] as List<dynamic>?) ?? []).map((t) => t.toString()).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Section
                  _buildHeroSection(
                    context: context,
                    imageUrl: imageUrl,
                    title: title,
                    isPremium: isPremium,
                    onPlay: () => context.push('/player/$id', extra: {'isPremium': isPremium}),
                  ),
                  
                  const SizedBox(height: _sectionSpacing),
                  
                  // 2. Action Buttons
                  _buildActionButtons(
                    context: context,
                    title: title,
                    description: description,
                    isFavorite: isFavorited,
                    onFavoriteToggle: () async {
                      HapticFeedback.lightImpact();
                      await ref.read(favoritesActionsProvider).toggle(widget.meditationId);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 3. Info Tags
                  _buildInfoTags(
                    context: context,
                    durationSec: durationSec,
                    categoryName: categoryName,
                    difficulty: difficulty,
                    tags: tags,
                  ),

                  const SizedBox(height: _sectionSpacing),

                  // 4. Description Section
                  _buildDescriptionSection(
                    context: context,
                    description: description,
                  ),

                  const SizedBox(height: _sectionSpacing),

                  // 5. Related Meditations
                  _buildRelatedMeditations(
                    context: context,
                    currentCategoryId: categoryId,
                    currentMeditationId: id,
                    currentTags: tags,
                  ),
                  
                  const SizedBox(height: _sectionSpacing),
                  
                  // 7. Comments Section (existing)
                  _buildCommentsSection(context),
                  
                  // Bottom Padding
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroSection({
    required BuildContext context,
    required String imageUrl,
    required String title,
    required bool isPremium,
    required VoidCallback onPlay,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        // Background Image
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(_cardCornerRadius * 2),
              bottomRight: Radius.circular(_cardCornerRadius * 2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(_cardCornerRadius * 2),
              bottomRight: Radius.circular(_cardCornerRadius * 2),
            ),
            child: imageUrl.isEmpty
                ? Container(
                    color: colors.surfaceVariant,
                    child: Icon(Icons.spa, size: 80, color: colors.onSurfaceVariant),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        
        // Gradient Overlay
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(_cardCornerRadius * 2),
              bottomRight: Radius.circular(_cardCornerRadius * 2),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colors.surface.withOpacity(0.8),
              ],
            ),
          ),
        ),
        
        // Premium Badge
        if (isPremium)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'PREMIUM',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Floating Play Button
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: colors.onPrimary,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required String title,
    required String description,
    required bool isFavorite,
    required VoidCallback onFavoriteToggle,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Favorite Button
          _ActionButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : colors.onSurfaceVariant,
            onPressed: onFavoriteToggle,
            tooltip: 'Favorite',
          ),
          const SizedBox(width: 32),
          
          // Share Button
          _ActionButton(
            icon: Icons.share,
            color: colors.onSurfaceVariant,
            onPressed: () {
              Share.share(
                '$title\n\n$description\n\nCheck out this meditation in the app!',
                subject: title,
              );
            },
            tooltip: 'Share',
          ),
          const SizedBox(width: 32),
          
          // Download Button (placeholder)
          _ActionButton(
            icon: Icons.download,
            color: colors.onSurfaceVariant,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon!')),
              );
            },
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection({
    required BuildContext context,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description.isEmpty ? 'No description available.' : description,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTags({
    required BuildContext context,
    required int? durationSec,
    required String? categoryName,
    required String? difficulty,
    required List<String> tags,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _InfoTag(
            icon: Icons.timer_outlined,
            label: _formatDuration(durationSec),
            color: colors.onSurfaceVariant,
          ),
          _InfoTag(
            icon: Icons.trending_up,
            label: _formatDifficulty(difficulty),
            color: colors.onSurfaceVariant,
          ),
          // Add tag pills
          ...tags.take(3).map((tag) => _InfoTag(
            icon: Icons.tag,
            label: tag,
            color: colors.onSurfaceVariant,
          )),
        ],
      ),
    );
  }

  Widget _buildRelatedMeditations({
    required BuildContext context,
    required String? currentCategoryId,
    required String currentMeditationId,
    required List<String> currentTags,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (currentCategoryId == null || currentCategoryId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
          child: Text(
            'Related Meditations',
            style: textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Consumer(
            builder: (context, ref, child) {
              final relatedAsync = ref.watch(
                relatedMeditationsProvider((currentCategoryId, currentMeditationId, currentTags)),
              );

              return relatedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
                data: (meditations) {
                  if (meditations.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
                    itemCount: meditations.length,
                    itemBuilder: (context, index) {
                      final meditation = meditations[index];
                      return Padding(
                        padding: EdgeInsets.only(right: index < meditations.length - 1 ? 12 : 0),
                        child: _RelatedMeditationCard(
                          meditation: meditation,
                          onTap: () => context.push('/meditation-detail/${meditation.id}'),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colors.outline.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(
            'Comments',
            style: textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(_cardCornerRadius),
              border: Border.all(color: colors.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Comments coming soon.\nShare your experience once this feature is live.',
                    style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(_pagePadding),
      child: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(_cardCornerRadius * 2),
            ),
          ),
          const SizedBox(height: _sectionSpacing),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(_cardCornerRadius),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_pagePadding),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(_cardCornerRadius),
            border: Border.all(color: colors.outline.withOpacity(0.2)),
          ),
          child: Text(
            'Something went wrong. Please try again.',
            style: TextStyle(color: colors.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_pagePadding),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(_cardCornerRadius),
            border: Border.all(color: colors.outline.withOpacity(0.2)),
          ),
          child: Text(
            'This meditation is unavailable.',
            style: TextStyle(color: colors.onSurface),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '5 min';
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }

  String _formatDifficulty(String? difficulty) {
    if (difficulty == null || difficulty.isEmpty) return 'All Levels';
    return difficulty.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _prettyCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) return 'General';
    final s = categoryId.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 28, color: color),
        onPressed: onPressed,
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedMeditationCard extends StatelessWidget {
  const _RelatedMeditationCard({
    required this.meditation,
    required this.onTap,
  });

  final dynamic meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String title = (meditation.title as String?)?.trim() ?? 'Untitled';
    final String imageUrl = (meditation.imageUrl as String?) ?? '';
    final int? durationSec = meditation.durationSec as int?;
    final bool isPremium = (meditation.isPremium as bool?) ?? false;

    String formatMinutes(int? seconds) {
      if (seconds == null || seconds <= 0) return '5 min';
      final minutes = (seconds / 60).ceil();
      return '$minutes min';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isEmpty
                  ? Container(
                      height: 80,
                      color: colors.surfaceVariant,
                      child: Icon(Icons.spa, size: 40, color: colors.onSurfaceVariant),
                    )
                  : Image.network(
                      imageUrl,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatMinutes(durationSec),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (isPremium)
                          const Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 16,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Provider for related meditations
final relatedMeditationsProvider = StreamProvider.family<List<MeditationListItem>, (String, String, List<String>)>(
  (ref, args) {
    final categoryId = args.$1;
    final excludeMeditationId = args.$2;
    final currentTags = args.$3;

    return FirebaseFirestore.instance
        .collection('meditations')
        .where('status', isEqualTo: 'published')
        .limit(20) // Fetch more to have options for scoring/shuffling
        .snapshots()
        .map((snapshot) {
          // Filter and score results
          final candidates = snapshot.docs
              .map((doc) {
                final meditation = MeditationListItem.fromDoc(doc);

                // Skip current meditation
                if (meditation.id == excludeMeditationId) return null;

                // Calculate relevance score
                int score = 0;

                // Same category = 10 points
                final meditationCategory = doc.data()['categoryId'] as String?;
                if (meditationCategory == categoryId) {
                  score += 10;
                }

                // Tag overlap = 5 points per matching tag
                final meditationTags = (doc.data()['tags'] as List<dynamic>?)
                    ?.map((t) => t.toString())
                    .toList() ?? [];
                for (final tag in currentTags) {
                  if (meditationTags.contains(tag)) {
                    score += 5;
                  }
                }

                return (meditation: meditation, score: score);
              })
              .where((item) => item != null && item.score > 0)
              .cast<({MeditationListItem meditation, int score})>()
              .toList();

          // Shuffle for variety
          candidates.shuffle();

          // Sort by score (highest first), keeping shuffle within score bands
          candidates.sort((a, b) => b.score.compareTo(a.score));

          // Return top 4
          return candidates
              .take(4)
              .map((item) => item.meditation)
              .toList();
        });
  },
);
