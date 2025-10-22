import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/category_service.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

final categoriesStreamProvider = StreamProvider<List<CategoryItem>>((ref) {
  final svc = ref.watch(categoryServiceProvider);
  return svc.streamActiveCategories();
});

class CategoryActions {
  CategoryActions(this.ref);
  final Ref ref;

  Future<void> create(String name) async {
    await ref.read(categoryServiceProvider).createCategory(name);
  }

  Future<void> rename(String id, String newName) async {
    await ref.read(categoryServiceProvider).renameCategory(id, newName);
  }

  Future<void> archive(String id, {bool archive = true}) async {
    await ref.read(categoryServiceProvider).archiveCategory(id, archive: archive);
  }

  Future<void> reorder(List<CategoryItem> newOrder) async {
    await ref.read(categoryServiceProvider).reorderCategories(newOrder);
  }
}

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  return CategoryActions(ref);
});


