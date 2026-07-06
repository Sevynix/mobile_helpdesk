import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/ticket_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/supabase_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  bool _isLoadingAction = false;
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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

  Future<void> _handleAction(String action) async {
    setState(() => _isLoadingAction = true);
    try {
      final repo = ref.read(ticketRepositoryProvider);
      if (action == 'start') {
        await repo.startTicket(widget.ticketId);
      } else if (action == 'finish') {
        await repo.finishTicket(widget.ticketId);
      }
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(ticketHistoryProvider(widget.ticketId));
      ref.invalidate(ticketsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Status tiket berhasil diperbarui',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.statusClose,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _submitComment(String userId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      final repo = ref.read(ticketRepositoryProvider);
      await repo.addComment(widget.ticketId, userId, text);
      _commentController.clear();
      ref.invalidate(ticketCommentsProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  void _showAssignHelpdeskDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final helpdesksAsync = ref.watch(helpdesksProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Helpdesk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  helpdesksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                    data: (helpdesks) {
                      if (helpdesks.isEmpty)
                        return const Text('Belum ada helpdesk terdaftar');
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: helpdesks.length,
                        itemBuilder: (context, index) {
                          final helpdesk = helpdesks[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                LucideIcons.user,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              helpdesk.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(helpdesk.email),
                            onTap: () async {
                              if (_isLoadingAction) return;
                              _isLoadingAction = true;
                              Navigator.pop(context);
                              setState(() {});
                              try {
                                await ref
                                    .read(ticketRepositoryProvider)
                                    .assignTicket(widget.ticketId, helpdesk.id);
                                ref.invalidate(
                                  ticketDetailProvider(widget.ticketId),
                                );
                                ref.invalidate(
                                  ticketHistoryProvider(widget.ticketId),
                                );
                                ref.invalidate(ticketsProvider);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tiket berhasil di-assign',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.statusClose,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: AppColors.accent,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  _isLoadingAction = false;
                                  setState(() {});
                                }
                              }
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

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final historyAsync = ref.watch(ticketHistoryProvider(widget.ticketId));
    final attachmentsAsync = ref.watch(ticketAttachmentsProvider(widget.ticketId));
    final commentsAsync = ref.watch(ticketCommentsProvider(widget.ticketId));
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Tiket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.gitCommit),
            tooltip: 'Tracking Tiket',
            onPressed: () {
              context.push('/tickets/${widget.ticketId}/tracking');
            },
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (ticket) {
          final statusColor = _getStatusColor(ticket.status);
          final user = userAsync.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ticket.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getStatusText(ticket.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')}/${ticket.createdAt.year} ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Deskripsi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Text(ticket.description),
                  ),
                  const SizedBox(height: 24),
                  
                  attachmentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading attachments: $e'),
                    data: (attachments) {
                      if (attachments.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lampiran:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: attachments.length,
                            itemBuilder: (context, index) {
                              final attachment = attachments[index];
                              final client = ref.read(supabaseClientProvider);
                              final url = client.storage.from('ticket_attachments').getPublicUrl(attachment.filePath);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  if (user != null) ...[
                    if (user.role == 'helpdesk' &&
                        ticket.assignedHelpdeskId == user.id &&
                        ticket.status == 'assign')
                      ElevatedButton.icon(
                        onPressed: _isLoadingAction
                            ? null
                            : () => _handleAction('start'),
                        icon: _isLoadingAction
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.play),
                        label: const Text('Mulai Kerjakan'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.statusOnProgress,
                        ),
                      ),
                    if (user.role == 'helpdesk' &&
                        ticket.assignedHelpdeskId == user.id &&
                        ticket.status == 'on_progress')
                      ElevatedButton.icon(
                        onPressed: _isLoadingAction
                            ? null
                            : () => _handleAction('finish'),
                        icon: _isLoadingAction
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.checkCircle),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.statusClose,
                        ),
                      ),
                    if (user.role == 'admin' && ticket.status == 'open')
                      ElevatedButton.icon(
                        onPressed: _showAssignHelpdeskDialog,
                        icon: const Icon(LucideIcons.users),
                        label: const Text('Assign ke Helpdesk'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.statusAssign,
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],

                  const Text(
                    'Riwayat Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  historyAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading history: $e'),
                    data: (histories) {
                      if (histories.isEmpty)
                        return const Text('Belum ada riwayat');
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: histories.length,
                        itemBuilder: (context, index) {
                          final h = histories[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              LucideIcons.clock,
                              color: _getStatusColor(h.toStatus),
                            ),
                            title: Text(
                              _getStatusText(h.toStatus),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${h.changedAt.day.toString().padLeft(2, '0')}/${h.changedAt.month.toString().padLeft(2, '0')}/${h.changedAt.year} ${h.changedAt.hour.toString().padLeft(2, '0')}:${h.changedAt.minute.toString().padLeft(2, '0')}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Diskusi / Komentar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  commentsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading comments: $e'),
                    data: (comments) {
                      if (comments.isEmpty) return const Text('Belum ada diskusi');
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c.userName ?? 'User',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.year} ${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(c.commentText),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (user != null && ticket.status != 'close') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Tulis komentar...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSubmittingComment
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppColors.primary),
                          onPressed: _isSubmittingComment ? null : () => _submitComment(user.id),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
