import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/favorites_service.dart';
import './auth_provider.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

// Stream of the current user's favorite meditationIds
final userFavoritesProvider = StreamProvider<Set<String>>((ref) {
  final auth = ref.watch(authProvider);
  final uid = auth.user?.uid;
  if (uid == null || uid.isEmpty) {
    // Not signed in → empty set stream
    return const Stream<Set<String>>.empty();
  }
  final svc = ref.watch(favoritesServiceProvider);
  return svc.streamUserFavorites();
});

// Derived: is a given meditationId favorited (bool)
final isFavoritedProvider = Provider.family<bool, String>((ref, meditationId) {
  final set = ref.watch(userFavoritesProvider).asData?.value ?? <String>{};
  return set.contains(meditationId);
});

class FavoritesActions {
  FavoritesActions(this.ref);
  final Ref ref;

  Future<void> toggle(String meditationId) async {
    print('[FAVORITES] Toggle clicked for meditation: $meditationId');
    final uid = ref.read(authProvider).user?.uid;
    if (uid == null || uid.isEmpty) {
      print('[FAVORITES] ❌ No authenticated user - skipping favorite');
      return;
    }
    print('[FAVORITES] User authenticated: $uid');
    final isFav = ref.read(isFavoritedProvider(meditationId));
    print('[FAVORITES] Current state - isFavorited: $isFav');
    final svc = ref.read(favoritesServiceProvider);
    if (isFav) {
      print('[FAVORITES] Removing favorite...');
      await svc.removeFavorite(meditationId);
    } else {
      print('[FAVORITES] Adding favorite...');
      await svc.addFavorite(meditationId);
    }
    print('[FAVORITES] ✅ Toggle complete');
  }
}

final favoritesActionsProvider = Provider<FavoritesActions>((ref) {
  return FavoritesActions(ref);
});


