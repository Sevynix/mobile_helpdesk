import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/update_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tickets/ticket_list_screen.dart';
import '../screens/tickets/create_ticket_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';
import '../screens/tickets/ticket_tracking_screen.dart';
import '../screens/notifications/notification_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/setting_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = authState.value;
      final session = auth?.session;
      final event = auth?.event;
      final isAuth = session != null;
      final path = state.uri.path;
      final isLoggingIn = path == '/login';
      final isRegistering = path == '/register';
      final isForgotPw = path == '/forgot-password';
      final isUpdatePw = path == '/update-password';
      final isSplash = path == '/splash';
      
      if (event == AuthChangeEvent.passwordRecovery) {
        return '/update-password';
      }
      
      if (!isAuth && !isLoggingIn && !isRegistering && !isForgotPw && !isUpdatePw && !isSplash) return '/login';
      if (isAuth && (isLoggingIn || isRegistering || isSplash)) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return UpdatePasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketListScreen(),
      ),
      GoRoute(
        path: '/create-ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) {
          final ticketId = state.pathParameters['id']!;
          return TicketDetailScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/tickets/:id/tracking',
        builder: (context, state) {
          final ticketId = state.pathParameters['id']!;
          return TicketTrackingScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
    ],
  );
});
