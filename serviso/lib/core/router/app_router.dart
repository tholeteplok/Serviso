import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

import '../../features/antrian/screens/antrian_screen.dart';
import '../../features/auth/controllers/session_controller.dart';
import '../../features/auth/models/profile.dart';
import '../../features/auth/screens/admin_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/beranda/screens/beranda_screen.dart';
import '../../features/inventori/screens/inventori_screen.dart';
import '../../features/laporan/screens/laporan_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const beranda = '/beranda';
  static const antrian = '/antrian';
  static const inventori = '/inventori';
  static const laporan = '/laporan';
  static const profil = '/profil';
  static const admin = '/admin';
}

String? authGuardRedirect({
  required AsyncValue<Profile?> session,
  required bool isAdmin,
  required String location,
}) {
  if (session.isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final profile = session.valueOrNull;
  final loggedIn = profile != null && profile.isActive;

  if (!loggedIn) {
    if (location == AppRoutes.login) return null;
    if (location == AppRoutes.splash) return AppRoutes.login;
    return AppRoutes.login;
  }

  if (location == AppRoutes.login || location == AppRoutes.splash) {
    return AppRoutes.beranda;
  }
  if (location.startsWith('/admin') && !isAdmin) {
    return AppRoutes.beranda;
  }
  return null;
}

class SessionRefreshListenable extends ChangeNotifier implements Listenable {
  SessionRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
    // Cover the initial session restore (e.g. persisted session).
    notifyListeners();
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable:
      AppConfig.isConfigured ? SessionRefreshListenable() : null,
  redirect: (context, state) {
    final session = ProviderScope.containerOf(context).read(sessionProvider);
    final isAdmin = ProviderScope.containerOf(context).read(isAdminProvider);
    final target = authGuardRedirect(
      session: session,
      isAdmin: isAdmin,
      location: state.uri.path,
    );
    if (target == AppRoutes.beranda && state.uri.path.startsWith('/admin')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Hanya pemilik yang dapat membuka menu ini'),
          ),
        );
      });
    }
    return target;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.profil,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => const AdminScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.beranda,
              builder: (context, state) => const BerandaScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.antrian,
              builder: (context, state) => const AntrianScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.inventori,
              builder: (context, state) => const InventoriScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.laporan,
              builder: (context, state) => const LaporanScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Antrian',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventori',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
