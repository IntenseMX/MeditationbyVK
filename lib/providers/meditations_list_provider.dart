import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meditation_service.dart';
import './auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// Base stream; prefer server-side filters when possible. Kept for admin list or generic lists.
final meditationsStreamProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  final query = ref.watch(meditationsQueryProvider);
  return svc.streamMeditations(status: query.status).map((items) {
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
  return svc.streamTrending(limit: 10);
});

// Recently Added: newest 4 published
final recentlyAddedMeditationsProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  return svc.streamRecentlyPublished(limit: 4);
});

// Recommended For You: personalized by top categories from recent sessions (fallback to trending)
final recommendedMeditationsProvider = StreamProvider<List<MeditationListItem>>((ref) {
  final svc = ref.watch(meditationServiceProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.user?.uid;
  if (uid == null || uid.isEmpty) {
    return svc.streamTrending(limit: 6);
  }
  return svc.streamRecommendedForUser(uid);
});

// Fetch a single meditation by id; returns null if not found or not published
final meditationByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final svc = ref.watch(meditationServiceProvider);
  final data = await svc.getMeditation(id);
  final status = (data?['status'] as String?) ?? 'draft';
  if (data == null || status != 'published') return null;
  return data;
});

// Cursor-paginated published list (for future scaling)
class PublishedPaginationState {
  const PublishedPaginationState({
    required this.items,
    required this.lastDoc,
    required this.isLoading,
    required this.canLoadMore,
  });
  final List<MeditationListItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool isLoading;
  final bool canLoadMore;

  PublishedPaginationState copyWith({
    List<MeditationListItem>? items,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool? isLoading,
    bool? canLoadMore,
  }) => PublishedPaginationState(
        items: items ?? this.items,
        lastDoc: lastDoc ?? this.lastDoc,
        isLoading: isLoading ?? this.isLoading,
        canLoadMore: canLoadMore ?? this.canLoadMore,
      );
}

final publishedPaginationProvider = NotifierProvider<PublishedPaginationNotifier, PublishedPaginationState>(
  () => PublishedPaginationNotifier(),
);

class PublishedPaginationNotifier extends Notifier<PublishedPaginationState> {
  static const int pageSize = 20;

  @override
  PublishedPaginationState build() {
    return const PublishedPaginationState(items: <MeditationListItem>[], lastDoc: null, isLoading: false, canLoadMore: true);
  }

  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final svc = ref.read(meditationServiceProvider);
    final page = await svc.fetchPublishedPage(limit: pageSize);
    state = PublishedPaginationState(
      items: page.items,
      lastDoc: page.lastDoc,
      isLoading: false,
      canLoadMore: page.lastDoc != null,
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.canLoadMore) return;
    state = state.copyWith(isLoading: true);
    final svc = ref.read(meditationServiceProvider);
    final page = await svc.fetchPublishedPage(limit: pageSize, startAfter: state.lastDoc);
    state = PublishedPaginationState(
      items: [...state.items, ...page.items],
      lastDoc: page.lastDoc,
      isLoading: false,
      canLoadMore: page.lastDoc != null,
    );
  }
}

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

// Category-specific pagination (cursor-based)
class CategoryPaginationState {
  const CategoryPaginationState({
    required this.items,
    required this.lastDoc,
    required this.isLoading,
    required this.canLoadMore,
  });
  final List<MeditationListItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool isLoading;
  final bool canLoadMore;

  CategoryPaginationState copyWith({
    List<MeditationListItem>? items,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool? isLoading,
    bool? canLoadMore,
  }) => CategoryPaginationState(
        items: items ?? this.items,
        lastDoc: lastDoc ?? this.lastDoc,
        isLoading: isLoading ?? this.isLoading,
        canLoadMore: canLoadMore ?? this.canLoadMore,
      );
}

final categoryPaginationProvider = NotifierProvider.family<
    CategoryPaginationNotifier, CategoryPaginationState, String>(
  (categoryId) => CategoryPaginationNotifier(categoryId),
);

class CategoryPaginationNotifier extends Notifier<CategoryPaginationState> {
  CategoryPaginationNotifier(this.categoryId);
  static const int pageSize = 20;
  final String categoryId;

  @override
  CategoryPaginationState build() {
    return const CategoryPaginationState(
      items: <MeditationListItem>[],
      lastDoc: null,
      isLoading: false,
      canLoadMore: true,
    );
  }

  Future<void> loadFirstPage() async {
    try {
      state = state.copyWith(isLoading: true);
      final svc = ref.read(meditationServiceProvider);
      final page = await svc.fetchPublishedByCategory(
        categoryId: categoryId,
        limit: pageSize,
      );
      state = CategoryPaginationState(
        items: page.items,
        lastDoc: page.lastDoc,
        isLoading: false,
        canLoadMore: page.lastDoc != null,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, canLoadMore: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.canLoadMore) return;
    try {
      state = state.copyWith(isLoading: true);
      final svc = ref.read(meditationServiceProvider);
      final page = await svc.fetchPublishedByCategory(
        categoryId: categoryId,
        limit: pageSize,
        startAfter: state.lastDoc,
      );
      state = CategoryPaginationState(
        items: [...state.items, ...page.items],
        lastDoc: page.lastDoc,
        isLoading: false,
        canLoadMore: page.lastDoc != null,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, canLoadMore: false);
    }
  }
}

final meditationsActionsProvider = Provider<MeditationsActions>((ref) {
  return MeditationsActions(ref);
});


