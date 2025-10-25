import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/admin_stats_provider.dart';
import '../../widgets/admin/stat_card.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/main_nav_bar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMed = ref.watch(totalMeditationsProvider);
    final totalCat = ref.watch(totalCategoriesProvider);
    final totalPub = ref.watch(publishedMeditationsProvider);
    final recent = ref.watch(recentAdminActivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      bottomNavigationBar: const MainNavBar(selectedIndex: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatCard(
                  title: 'Total Meditations',
                  value: totalMed.maybeWhen(
                    data: (v) => v.toString(),
                    orElse: () => '—',
                  ),
                  icon: Icons.self_improvement,
                ),
                StatCard(
                  title: 'Total Categories',
                  value: totalCat.maybeWhen(
                    data: (v) => v.toString(),
                    orElse: () => '—',
                  ),
                  icon: Icons.category_outlined,
                ),
                StatCard(
                  title: 'Published Today',
                  value: totalPub.maybeWhen(
                    data: (v) => v.toString(),
                    orElse: () => '—',
                  ),
                  icon: Icons.public,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/meditations/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Meditation'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/categories'),
                  icon: const Icon(Icons.tune),
                  label: const Text('Manage Categories'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/meditations'),
                  icon: const Icon(Icons.list),
                  label: const Text('View All Meditations'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.softCharcoal,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/admin/activity'),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View all'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220, // fixed height with internal scrolling
                    child: recent.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'No recent activity.',
                              style: TextStyle(color: AppTheme.richTaupe),
                            ),
                          );
                        }
                        final limited = items.take(5).toList();
                        return ListView.separated(
                          itemCount: limited.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final a = limited[index];
                            final target = a.target;
                            final ts = a.ts?.toDate();
                            return ListTile(
                              dense: true,
                              title: Text(
                                '${a.action} ${target['collection'] ?? ''}/${target['id'] ?? ''}',
                                style: TextStyle(color: AppTheme.softCharcoal),
                              ),
                              subtitle: Text(
                                'by ${a.actorUid}${ts != null ? ' • ${ts.toLocal()}' : ''}',
                                style: TextStyle(color: AppTheme.richTaupe),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: TextStyle(color: AppTheme.richTaupe),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}


