import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/items/screens/items_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../shell/app_shell.dart';

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/pos',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final isAuth = authCubit.state is AuthAuthenticated;
      final isAdmin = authCubit.currentUser?.isAdmin ?? false;
      final loc = state.uri.toString();

      if (!isAuth && loc != '/login') return '/login';
      if (isAuth && loc == '/login') return '/pos';


      if (!isAdmin &&
          (loc.startsWith('/categories') ||
              loc.startsWith('/items') ||
              loc.startsWith('/users') ||
              loc.startsWith('/reports'))) {
        return '/pos';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/pos',
            builder: (_, __) => const PosScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (_, __) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/items',
            builder: (_, __) => const ItemsScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Converts a Bloc stream into a Listenable for go_router.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
