import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/meditations_list_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../services/meditation_service.dart';

// Compact control sizes for bulk action buttons
const double _bulkActionButtonMinSize = 36.0;

class MeditationsListScreen extends ConsumerWidget {
  const MeditationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(meditationsQueryProvider);
    final itemsAsync = ref.watch(meditationsStreamProvider);
    final selected = ref.watch(meditationsSelectionProvider);
    final actions = ref.read(meditationsActionsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Admin',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text('Meditations'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/meditations/new'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('New'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Filters(query: query),
            const SizedBox(height: 12),
            if (selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('${selected.length} selected', style: TextStyle(color: AppTheme.softCharcoal)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Unpublish selected?'),
                            content: const Text('These meditations will become drafts and no longer be publicly available.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unpublish')),
                            ],
                          ),
                        );
                        if (ok == true) await actions.bulkUnpublish();
                      },
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Unpublish'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: actions.bulkPublish,
                      icon: const Icon(Icons.public),
                      label: const Text('Publish'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: _bulkActionButtonMinSize,
                        minHeight: _bulkActionButtonMinSize,
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete selected?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) await actions.bulkDelete();
                      },
                    ),
                  ],
                ),
              ),
            if (selected.isNotEmpty) const SizedBox(height: 12),
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  final categoryMap = categoriesAsync.maybeWhen(
                    data: (list) => {for (final c in list) c.id: c.name},
                    orElse: () => const <String, String>{},
                  );
                  if (items.isEmpty) {
                    return Center(
                      child: Text('No meditations found', style: TextStyle(color: AppTheme.softCharcoal)),
                    );
                  }
                  return _MeditationsTable(
                    items: items,
                    selected: selected,
                    categoryMap: categoryMap,
                    onToggle: (id) => ref.read(meditationsSelectionProvider.notifier).toggle(id),
                    onTapRow: (id) => context.go('/meditations/$id'),
                    onToggleAll: (checked) {
                      if (checked) {
                        ref.read(meditationsSelectionProvider.notifier).setAll(items.map((e) => e.id));
                      } else {
                        ref.read(meditationsSelectionProvider.notifier).clear();
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.query});
  final MeditationsQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by title',
            ),
            onChanged: (v) {
              final cur = ref.read(meditationsQueryProvider);
              ref.read(meditationsQueryProvider.notifier).setQuery(cur.copyWith(search: v));
            },
          ),
        ),
        DropdownButton<String?>(
          value: query.status,
          hint: const Text('Status'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All')),
            DropdownMenuItem<String?>(value: 'draft', child: Text('Draft')),
            DropdownMenuItem<String?>(value: 'published', child: Text('Published')),
          ],
          onChanged: (v) {
            final cur = ref.read(meditationsQueryProvider);
            ref.read(meditationsQueryProvider.notifier).setQuery(cur.copyWith(status: v));
          },
        ),
        categoriesAsync.when(
          data: (cats) {
            final value = query.categoryId != null && cats.any((c) => c.id == query.categoryId)
                ? query.categoryId
                : null;
            return DropdownButton<String?>(
              value: value,
              hint: const Text('Category'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All')),
                ...cats.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) {
                final cur = ref.read(meditationsQueryProvider);
                ref.read(meditationsQueryProvider.notifier).setQuery(cur.copyWith(categoryId: v));
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        DropdownButton<String?>(
          value: query.difficulty,
          hint: const Text('Difficulty'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All')),
            DropdownMenuItem<String?>(value: 'beginner', child: Text('Beginner')),
            DropdownMenuItem<String?>(value: 'intermediate', child: Text('Intermediate')),
            DropdownMenuItem<String?>(value: 'advanced', child: Text('Advanced')),
          ],
          onChanged: (v) {
            final cur = ref.read(meditationsQueryProvider);
            ref.read(meditationsQueryProvider.notifier).setQuery(cur.copyWith(difficulty: v));
          },
        ),
        DropdownButton<bool?>(
          value: query.isPremium,
          hint: const Text('Premium'),
          items: const [
            DropdownMenuItem<bool?>(value: null, child: Text('All')),
            DropdownMenuItem<bool?>(value: true, child: Text('Premium')),
            DropdownMenuItem<bool?>(value: false, child: Text('Free')),
          ],
          onChanged: (v) {
            final cur = ref.read(meditationsQueryProvider);
            ref.read(meditationsQueryProvider.notifier).setQuery(cur.copyWith(isPremium: v));
          },
        ),
      ],
    );
  }
}

class _MeditationsTable extends StatelessWidget {
  const _MeditationsTable({
    required this.items,
    required this.selected,
    required this.categoryMap,
    required this.onToggle,
    required this.onToggleAll,
    required this.onTapRow,
  });
  final List<MeditationListItem> items;
  final Set<String> selected;
  final Map<String, String> categoryMap;
  final ValueChanged<String> onToggle;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<String> onTapRow;

  // Compact layout constants to improve mobile fit
  static const double _columnSpacing = 12.0;
  static const double _horizontalMargin = 8.0;
  static const double _headerGap = 2.0;
  static const double _gapSm = 6.0;
  static const double _gapMd = 8.0;
  static const double _actionIconSize = 20.0;
  static const double _actionButtonMinSize = 32.0;
  static const double _thumbSize = 32.0;

  @override
  Widget build(BuildContext context) {
    final allSelected = items.isNotEmpty && selected.length == items.length;
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: _columnSpacing,
          horizontalMargin: _horizontalMargin,
          columns: [
            DataColumn(
              label: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    onChanged: (v) => onToggleAll(v == true),
                  ),
                  const SizedBox(width: _headerGap),
                ],
              ),
            ),
            const DataColumn(label: Text('Title')),
            const DataColumn(label: SizedBox.shrink()), // status icon only
            const DataColumn(label: Text('Created')),
          ],
          rows: items.map((m) {
            final isSelected = selected.contains(m.id);
            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onTapRow(m.id),
                        iconSize: _actionIconSize,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: _actionButtonMinSize, minHeight: _actionButtonMinSize),
                      ),
                      const SizedBox(width: _gapSm),
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggle(m.id),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      _Thumb(imageUrl: m.imageUrl, size: _thumbSize),
                      const SizedBox(width: _gapMd),
                      Flexible(
                        child: Text(
                          m.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.softCharcoal),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(_StatusIcon(status: m.status)),
                DataCell(Text(
                  m.createdAt != null ? _formatDate(m.createdAt!) : '—',
                  style: TextStyle(color: AppTheme.richTaupe),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final mm = months[d.month - 1];
    final dd = d.day.toString();
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$mm $dd, $yy';
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.imageUrl, this.size = 40.0});
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.image_not_supported_outlined, size: 20),
      );
    }
    // Phase 2: keep it simple; avoid heavy image widgets
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined, size: 20),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPub = status == 'published';
    final appColors = Theme.of(context).extension<AppColors>();
    final color = isPub
        ? (appColors?.statusSuccess ?? AppTheme.brandPrimaryLight)
        : (appColors?.statusWarning ?? AppTheme.amberBrown);
    final icon = isPub ? Icons.check_circle : Icons.schedule;
    return Icon(icon, color: color, size: 18);
  }
}



