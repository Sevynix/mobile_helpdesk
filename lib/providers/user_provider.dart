import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/user_repository.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
});

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(userRepositoryProvider);
  return repo.getCurrentUserProfile();
});

final usersListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUsers();
});

class UserNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  late UserRepository repo;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    repo = ref.watch(userRepositoryProvider);
    return repo.getUsers();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await repo.getUsers();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await repo.updateUserStatus(userId, !currentStatus);
      if (state.hasValue) {
        final users = state.value!;
        final updatedUsers = users.map((u) {
          if (u['id'] == userId) {
            return {...u, 'is_active': !currentStatus};
          }
          return u;
        }).toList();
        state = AsyncValue.data(updatedUsers);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await repo.updateUserRole(userId, role);
      if (state.hasValue) {
        final users = state.value!;
        final updatedUsers = users.map((u) {
          if (u['id'] == userId) {
            return {...u, 'role': role};
          }
          return u;
        }).toList();
        state = AsyncValue.data(updatedUsers);
      }
    } catch (e) {
      rethrow;
    }
  }
}

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, List<Map<String, dynamic>>>(() {
  return UserNotifier();
});
