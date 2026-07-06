import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/models/user_model.dart';
import 'supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

final authStateProvider = StreamProvider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
});

final currentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

final helpdesksProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(authRepositoryProvider).getHelpdesks();
});
