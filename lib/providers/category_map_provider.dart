import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_provider.dart';

/// Provides a memoized map of categoryId -> categoryName.
/// Recomputes only when the underlying categories stream emits a new value.
final categoryMapProvider = Provider<Map<String, String>>((ref) {
  final catsAsync = ref.watch(categoriesStreamProvider);
  final cats = catsAsync.asData?.value;
  return <String, String>{
    if (cats != null) for (final c in cats) c.id: c.name,
  };
});


