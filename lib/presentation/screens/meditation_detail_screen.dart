import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/category_map_provider.dart';
import '../widgets/compact_meditation_card.dart';

class MeditationDetailScreen extends ConsumerWidget {
  const MeditationDetailScreen({super.key, required this.meditationId});
  final String meditationId;

  static const double _sectionSpacing = 20.0;
  static const double _pagePadding = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final meditationAsync = ref.watch(meditationByIdProvider(meditationId));
    final categoryMap = ref.watch(categoryMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_pagePadding),
          child: meditationAsync.when(
            loading: () => _buildLoading(context),
            error: (e, _) => _buildError(context, e),
            data: (data) {
              if (data == null) {
                return _buildUnavailable(context);
              }
              final String id = meditationId;
              final String title = (data['title'] as String?)?.trim() ?? 'Untitled';
              final String description = (data['description'] as String?)?.trim() ?? '';
              final String imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
              final int? durationSec = data['durationSec'] is int ? data['durationSec'] as int : null;
              final String? categoryId = (data['categoryId'] as String?);
              final String? categoryName = categoryId == null ? null : (categoryMap[categoryId] ?? _prettyCategory(categoryId));
              final bool isPremium = (data['isPremium'] as bool?) ?? false;

              return ListView(
                children: [
                  CompactMeditationCard(
                    id: id,
                    title: title,
                    description: description,
                    imageUrl: imageUrl,
                    durationSec: durationSec,
                    categoryName: categoryName,
                    isPremium: isPremium,
                    onPlay: () => context.push('/player/$id'),
                  ),
                  const SizedBox(height: _sectionSpacing),
                  Divider(color: colors.outline.withOpacity(0.2)),
                  const SizedBox(height: _sectionSpacing),
                  Text('Comments', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outline.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: colors.onSurfaceVariant),
                        const SizedBox(width: 10),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: _sectionSpacing),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Text('Something went wrong. Please try again.', style: TextStyle(color: colors.onSurface)),
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Text('This meditation is unavailable.', style: TextStyle(color: colors.onSurface)),
      ),
    );
  }

  String _prettyCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) return 'General';
    final s = categoryId.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }
}


