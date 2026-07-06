import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/ticket_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../domain/models/ticket_model.dart';

class TicketListScreen extends ConsumerWidget {
  final bool isBottomNav;
  
  const TicketListScreen({super.key, this.isBottomNav = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: isBottomNav ? null : IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (userAsync.value?.role == 'admin')
            IconButton(
              icon: const Icon(LucideIcons.filter),
              onPressed: () {
                _showFilterDialog(context, ref);
              },
            ),
        ],
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('Belum ada tiket', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(ticketsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  delay: Duration(milliseconds: 100 * index.clamp(0, 5)),
                  child: _TicketCard(ticket: ticket),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final helpdesksAsync = ref.watch(helpdesksProvider);
            final currentFilter = ref.watch(selectedHelpdeskFilterProvider);

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Helpdesk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Semua Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: currentFilter == null ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                    onTap: () {
                      ref.read(selectedHelpdeskFilterProvider.notifier).setFilter(null);
                      Navigator.pop(context);
                    },
                  ),
                  helpdesksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                    data: (helpdesks) {
                      if (helpdesks.isEmpty) return const Text('Belum ada helpdesk');
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: helpdesks.length,
                        itemBuilder: (context, index) {
                          final h = helpdesks[index];
                          return ListTile(
                            title: Text(h.name),
                            subtitle: Text(h.email),
                            trailing: currentFilter == h.id ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                            onTap: () {
                              ref.read(selectedHelpdeskFilterProvider.notifier).setFilter(h.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.statusOpen;
      case 'assign':
        return AppColors.statusAssign;
      case 'on_progress':
        return AppColors.statusOnProgress;
      case 'close':
        return AppColors.statusClose;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'OPEN';
      case 'assign':
        return 'ASSIGN';
      case 'on_progress':
        return 'IN PROGRESS';
      case 'close':
        return 'CLOSED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/tickets/${ticket.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _getStatusText(ticket.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')}/${ticket.createdAt.year} ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
