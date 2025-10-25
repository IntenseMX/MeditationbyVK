import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/admin_stats_provider.dart';
import 'package:go_router/go_router.dart';

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allAdminActivityProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Admin',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text('All Activity'),
      ),
      body: all.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('No activity yet.', style: TextStyle(color: AppTheme.softCharcoal)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = items[index];
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
          child: Text('Error: $e', style: TextStyle(color: AppTheme.richTaupe)),
        ),
      ),
    );
  }
}


