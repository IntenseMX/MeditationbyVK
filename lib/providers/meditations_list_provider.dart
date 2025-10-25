import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meditation_service.dart';

class MeditationsQuery {
  final String? status; // draft | published | null (all)
  final String? categoryId;
  final String? difficulty;
  final bool? isPremium;
  final String search; // client-side contains (case-insensitive)

  const MeditationsQuery({
    this.status,
    this.categoryId,
    this.difficulty,
    this.isPremium,
    this.search = '',
  });

  MeditationsQuery copyWith({
    String? status,
    String? categoryId,
    String? difficulty,
    bool? isPremium,
    String? search,
  }) {
    return MeditationsQuery(
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      difficulty: difficulty ?? this.difficulty,
      isPremium: isPremium ?? this.isPremium,
      search: search ?? this.search,
    );
  }
}

final meditationServiceProvider = Provider<MeditationService>((ref) {
  return MeditationService();
});

class MeditationsQueryNotifier extends Notifier<MeditationsQuery> {
  @override
  MeditationsQuery build() => const MeditationsQuery();

  void setQuery(MeditationsQuery q) => state = q;
}

final meditationsQueryProvider = NotifierProvider<MeditationsQueryNotifier, MeditationsQuery>(
  () => MeditationsQueryNotifier(),
);

final meditationsStreamProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  final query = ref.watch(meditationsQueryProvider);
  return svc.streamMeditations(status: query.status).map((items) {
    // Client-side filters for search, category, difficulty, premium
    Iterable<MeditationListItem> filtered = items;

    if (query.categoryId != null && query.categoryId!.isNotEmpty) {
      filtered = filtered.where((m) => m.categoryId == query.categoryId);
    }
    if (query.difficulty != null && query.difficulty!.isNotEmpty) {
      filtered = filtered.where((m) => (m.difficulty ?? '').isNotEmpty && m.difficulty == query.difficulty);
    }

    if (query.isPremium != null) {
      filtered = filtered.where((m) => m.isPremium == query.isPremium);
    }

    final s = query.search.trim().toLowerCase();
    if (s.isNotEmpty) {
      filtered = filtered.where((m) => m.title.toLowerCase().contains(s));
    }

    return filtered.toList(growable: false);
  });
});

// Trending: newest 7 published
final trendingMeditationsProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  return svc.streamMeditations().map((items) {
    final published = items.where((m) => m.status == 'published');
    return published.take(7).toList(growable: false);
  });
});

// Recently Added: newest 4 published
final recentlyAddedMeditationsProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  return svc.streamMeditations().map((items) {
    final published = items.where((m) => m.status == 'published');
    return published.take(4).toList(growable: false);
  });
});

// Recommended: older 6 published (stable ordering, no shuffle for Phase 2)
final recommendedMeditationsProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  return svc.streamMeditations().map((items) {
    final published = items.where((m) => m.status == 'published').toList(growable: false);
    if (published.isEmpty) return const <MeditationListItem>[];
    final older = published.reversed.toList(growable: false);
    return older.take(6).toList(growable: false);
  });
});

// Fetch a single meditation by id; returns null if not found or not published
final meditationByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final svc = ref.watch(meditationServiceProvider);
  final data = await svc.getMeditation(id);
  final status = (data?['status'] as String?) ?? 'draft';
  if (data == null || status != 'published') return null;
  return data;
});

class MeditationsSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String id) {
    final next = {...state};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
  }

  void setAll(Iterable<String> ids) {
    state = ids.toSet();
  }

  void clear() {
    state = <String>{};
  }
}

final meditationsSelectionProvider = NotifierProvider<MeditationsSelection, Set<String>>(
  () => MeditationsSelection(),
);

class MeditationsActions {
  MeditationsActions(this.ref);
  final Ref ref;

  Future<void> bulkPublish() async {
    final ids = ref.read(meditationsSelectionProvider).toList(growable: false);
    if (ids.isEmpty) return;
    await ref.read(meditationServiceProvider).bulkPublish(ids);
    ref.read(meditationsSelectionProvider.notifier).clear();
  }

  Future<void> bulkUnpublish() async {
    final ids = ref.read(meditationsSelectionProvider).toList(growable: false);
    if (ids.isEmpty) return;
    await ref.read(meditationServiceProvider).bulkUnpublish(ids);
    ref.read(meditationsSelectionProvider.notifier).clear();
  }

  Future<void> bulkDelete() async {
    final ids = ref.read(meditationsSelectionProvider).toList(growable: false);
    if (ids.isEmpty) return;
    await ref.read(meditationServiceProvider).bulkDelete(ids);
    ref.read(meditationsSelectionProvider.notifier).clear();
  }
}

final meditationsActionsProvider = Provider<MeditationsActions>((ref) {
  return MeditationsActions(ref);
});


