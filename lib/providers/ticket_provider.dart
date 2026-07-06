import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/ticket_repository.dart';
import '../domain/models/ticket_model.dart';
import '../domain/models/ticket_history_model.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TicketRepository(supabase);
});

final ticketsProvider = FutureProvider.autoDispose<List<TicketModel>>((ref) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTickets();
});

final ticketDetailProvider = FutureProvider.autoDispose.family<TicketModel, String>((ref, id) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketById(id);
});

final ticketHistoryProvider = FutureProvider.autoDispose.family<List<TicketHistoryModel>, String>((ref, id) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketHistory(id);
});
