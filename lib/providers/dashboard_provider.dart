import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/dashboard_repository.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepository(client);
});

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getStats();
});
