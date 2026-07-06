import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/ticket_repository.dart';
import '../domain/models/ticket_model.dart';
import '../domain/models/ticket_history_model.dart';
import '../domain/models/attachment_model.dart';
import '../domain/models/comment_model.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TicketRepository(supabase);
});

class SelectedHelpdeskFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setFilter(String? id) => state = id;
}

final selectedHelpdeskFilterProvider = NotifierProvider<SelectedHelpdeskFilterNotifier, String?>(() {
  return SelectedHelpdeskFilterNotifier();
});
final ticketsProvider = FutureProvider.autoDispose<List<TicketModel>>((ref) async {
  ref.watch(currentUserProvider);
  final selectedHelpdeskId = ref.watch(selectedHelpdeskFilterProvider);
  final repo = ref.watch(ticketRepositoryProvider);
  final allTickets = await repo.getTickets();
  
  if (selectedHelpdeskId != null) {
    return allTickets.where((t) => t.assignedHelpdeskId == selectedHelpdeskId).toList();
  }
  return allTickets;
});

final ticketDetailProvider = FutureProvider.autoDispose.family<TicketModel, String>((ref, ticketId) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketById(ticketId);
});

final ticketHistoryProvider = FutureProvider.autoDispose.family<List<TicketHistoryModel>, String>((ref, ticketId) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketHistory(ticketId);
});

final ticketAttachmentsProvider = FutureProvider.autoDispose.family<List<AttachmentModel>, String>((ref, ticketId) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getAttachments(ticketId);
});

final ticketCommentsProvider = FutureProvider.autoDispose.family<List<CommentModel>, String>((ref, ticketId) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getComments(ticketId);
});
