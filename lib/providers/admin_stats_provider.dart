import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

final totalMeditationsProvider = FutureProvider<int>((ref) async {
  final svc = ref.watch(adminServiceProvider);
  return svc.getMeditationsCount();
});

final totalCategoriesProvider = FutureProvider<int>((ref) async {
  final svc = ref.watch(adminServiceProvider);
  return svc.getCategoriesCount();
});

final publishedMeditationsProvider = FutureProvider<int>((ref) async {
  final svc = ref.watch(adminServiceProvider);
  return svc.getPublishedMeditationsCount();
});

final recentAdminActivityProvider = StreamProvider((ref) {
  final svc = ref.watch(adminServiceProvider);
  return svc.recentAdminActivity(limit: 10);
});

final allAdminActivityProvider = StreamProvider((ref) {
  final svc = ref.watch(adminServiceProvider);
  return svc.recentAdminActivity(limit: 200); // show more on the full page
});


