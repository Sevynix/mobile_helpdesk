import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/ticket_provider.dart';

class TicketTrackingScreen extends ConsumerWidget {
  final String ticketId;

  const TicketTrackingScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(ticketHistoryProvider(ticketId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket History')),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final date = item.changedAt.toLocal();
              final isLast = index == history.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.fromStatus?.toUpperCase() ?? 'NEW'} → ${item.toStatus.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By: ${item.changedByUserName ?? 'System'}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              date.toString().substring(0, 16),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

