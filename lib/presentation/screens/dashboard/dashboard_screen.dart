import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/notification_provider.dart';
import '../tickets/ticket_list_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          
          final screens = [
            _buildHomeTab(user),
            const TicketListScreen(isBottomNav: true),
            const NotificationScreen(),
            const ProfileScreen(),
          ];

          return screens[_currentIndex];
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.ticket), label: 'Tickets'),
          BottomNavigationBarItem(
            icon: Consumer(
              builder: (context, ref, child) {
                final unreadCount = ref.watch(unreadNotificationCountProvider);
                if (unreadCount > 0) {
                  return Badge(
                    label: Text(unreadCount.toString()),
                    child: const Icon(LucideIcons.bell),
                  );
                }
                return const Icon(LucideIcons.bell);
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(dynamic user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
            title: Text(
              'Halo, ${user.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text('Statistik Tiket', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  
                  _buildDashboardStats(),
                  
                  const SizedBox(height: 32),
                  Text('Menu Utama', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  
                  _buildMenuCard(
                    context,
                    title: 'Buat Tiket Baru',
                    icon: LucideIcons.plusCircle,
                    color: AppColors.statusClose,
                    onTap: () => context.push('/create-ticket'),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDashboardStats() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(dashboardStatsProvider);
        return statsAsync.when(
          data: (stats) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total', stats['total'].toString(), Colors.blue),
                _buildStatCard('Open', stats['open'].toString(), AppColors.statusOpen),
                _buildStatCard('Assign', stats['assign'].toString(), AppColors.statusAssign),
                _buildStatCard('Progress', stats['on_progress'].toString(), AppColors.statusOnProgress),
                _buildStatCard('Closed', stats['close'].toString(), AppColors.statusClose),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Gagal memuat statistik'),
        );
      }
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

