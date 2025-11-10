import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/meditations_list_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/meditation_service.dart';
import '../widgets/meditation_card.dart';

// Uses categoryPaginationProvider for server-side filtering & cursor pagination

class CategoryMeditationsScreen extends ConsumerStatefulWidget {
  const CategoryMeditationsScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CategoryMeditationsScreen> createState() => _CategoryMeditationsScreenState();
}

class _CategoryMeditationsScreenState extends ConsumerState<CategoryMeditationsScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off first page after first frame to avoid lifecycle mutations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryPaginationProvider(widget.categoryId).notifier).loadFirstPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final state = ref.watch(categoryPaginationProvider(widget.categoryId));

    final colors = Theme.of(context).colorScheme;
    final gradient = [colors.primary.value, colors.tertiary.value];

    return Scaffold(
      appBar: AppBar(
        title: categoriesAsync.when(
          data: (cats) {
            var matchedName = 'Category';
            for (final c in cats) {
              if (c.id == widget.categoryId) {
                matchedName = c.name;
                break;
              }
            }
            return Text(matchedName);
          },
          loading: () => const Text('Category'),
          error: (_, __) => const Text('Category'),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.items.isEmpty && state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.items.isEmpty && !state.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No meditations in this category yet'),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                ...state.items.map((m) => MeditationCard(
                      id: m.id,
                      title: m.title,
                      subtitle: '',
                      duration: _minutesFromSeconds(m.durationSec),
                      imageUrl: m.imageUrl ?? '',
                      gradientColors: gradient,
                      isPremium: m.isPremium ?? false,
                      onTap: () => context.push('/player/${m.id}'),
                    )),
                const SizedBox(height: 12),
                if (state.canLoadMore)
                  Center(
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                              .read(categoryPaginationProvider(widget.categoryId).notifier)
                              .loadMore(),
                      child: Text(state.isLoading ? 'Loading...' : 'Load More'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _minutesFromSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return 0;
    return (seconds + 59) ~/ 60;
  }
}


