import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryItem {
  final String id;
  final String name;
  final String slug;
  final int order;
  final String? imageUrl;
  final bool active;
  final int meditationCount;

  CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.order,
    required this.active,
    required this.meditationCount,
    this.imageUrl,
  });

  factory CategoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? <String, dynamic>{};
    return CategoryItem(
      id: d.id,
      name: (data['name'] ?? '') as String,
      slug: (data['slug'] ?? '') as String,
      order: (data['order'] ?? 0) as int,
      active: (data['active'] ?? true) as bool,
      imageUrl: data['imageUrl'] as String?,
      meditationCount: (data['meditationCount'] ?? 0) as int,
    );
  }
}

class CategoryService {
  CategoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _slugify(String input) {
    final s = input.trim().toLowerCase();
    final only = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return only.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'(^-|-$)'), '');
  }

  Stream<List<CategoryItem>> streamActiveCategories() {
    // Avoid composite index requirement by ordering only, filter active client-side
    return _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((q) => q.docs
            .map((d) => CategoryItem.fromDoc(d))
            .where((c) => c.active)
            .toList());
  }

  Future<String> createCategory(String name) async {
    final now = Timestamp.now();
    final doc = _firestore.collection('categories').doc();
    await doc.set({
      'name': name,
      'slug': _slugify(name),
      'order': 100000, // put at end; user can reorder
      'imageUrl': null,
      'active': true,
      'meditationCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }

  Future<void> renameCategory(String id, String newName) async {
    await _firestore.collection('categories').doc(id).update({
      'name': newName,
      'slug': _slugify(newName),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> archiveCategory(String id, {bool archive = true}) async {
    await _firestore.collection('categories').doc(id).update({
      'active': !archive ? true : false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> reorderCategories(List<CategoryItem> ordered) async {
    // Set order in gaps of 10
    final batch = _firestore.batch();
    int order = 10;
    for (final c in ordered) {
      final ref = _firestore.collection('categories').doc(c.id);
      batch.update(ref, {'order': order, 'updatedAt': Timestamp.now()});
      order += 10;
    }
    await batch.commit();
  }
}


