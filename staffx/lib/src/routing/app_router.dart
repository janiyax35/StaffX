import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/dashboard/presentation/admin_dashboard.dart';
import '../features/dashboard/presentation/driver_dashboard.dart';
import '../features/dashboard/presentation/owner_dashboard.dart';
import '../features/dashboard/presentation/staff_dashboard.dart';
import '../features/user_profile/data/profile_repository.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // access the auth state directly from the stream provider we are watching
      final auth = authState.valueOrNull;

      final isLoggedIn = auth?.session != null;
      final isLoggingIn =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (!isLoggedIn) {
        if (isLoggingIn) return null;
        return '/login';
      }

      // If logged in and trying to access login/register, or just landed, redirect to role dashboard
      if (isLoggingIn) {
        // Fetch profile to know where to go
        // We use .future here to ensure we wait for it
        final profile = await ref.read(userProfileProvider.future);

        if (profile == null) {
          // Profile might not be created yet if this is immediate after signup
          // In a real app, we might want a 'setup profile' screen or a loading spinner
          // For now, let's assume profile creation is fast (trigger)
          // If null, maybe stay or show loading?
          return null;
        }

        switch (profile.role) {
          case 'admin':
            return '/admin';
          case 'owner':
            return '/owner';
          case 'driver':
            return '/driver';
          case 'staff':
            return '/staff';
          default:
            return '/staff';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboard(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverDashboard(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDashboard(),
      ),
    ],
  );
}
