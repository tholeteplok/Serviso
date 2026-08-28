import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/offline_banner.dart';

import '../../features/antrian/screens/antrian_screen.dart';
import '../../features/workorders/screens/wo_detail_screen.dart';
import '../../features/workorders/screens/wo_wizard_screen.dart';
import '../../features/customers/models/vehicle.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/auth/controllers/session_controller.dart';
import '../../features/auth/models/profile.dart';
import '../../features/auth/screens/admin_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/beranda/screens/beranda_screen.dart';
import '../../features/inventori/screens/inventori_screen.dart';
import '../../features/inventori/screens/part_detail_screen.dart';
import '../../features/laporan/screens/laporan_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

import '../../features/admin/screens/audit_log_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const beranda = '/beranda';
  static const antrian = '/antrian';
  static const inventori = '/inventori';
  static const laporan = '/laporan';
  static const profil = '/profil';
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminAuditLogs = '/admin/audit-logs';
  static const pengaturan = '/admin/pengaturan';
  static const pelanggan = '/pelanggan';
  static const pelangganDetail = '/pelanggan/:id';
  static const woBaru = '/antrian/baru';
}

String? authGuardRedirect({
  required AsyncValue<Profile?> session,
  required bool isAdmin,
  required String location,
}) {
  if (session.isLoading) {
    if (location == AppRoutes.login) return null;
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

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) => notifier._redirect(context, state),
    routes: _appRoutes,
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<Profile?>>(
      sessionProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? _redirect(BuildContext context, GoRouterState state) {
    final session = _ref.read(sessionProvider);
    final isAdmin = _ref.read(isAdminProvider);
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
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final session = ProviderScope.containerOf(context).read(sessionProvider);
    final isAdmin = ProviderScope.containerOf(context).read(isAdminProvider);
    return authGuardRedirect(
      session: session,
      isAdmin: isAdmin,
      location: state.uri.path,
    );
  },
  routes: _appRoutes,
);

final List<RouteBase> _appRoutes = [
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
    GoRoute(
      path: AppRoutes.adminUsers,
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminAuditLogs,
      builder: (context, state) => const AuditLogScreen(),
    ),
    GoRoute(
      path: AppRoutes.pengaturan,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.pelanggan,
      builder: (context, state) => const CustomerListScreen(),
    ),
    GoRoute(
      path: AppRoutes.pelangganDetail,
      builder: (context, state) =>
          CustomerDetailScreen(customerId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.woBaru,
      builder: (context, state) => WoWizardScreen(
        initialVehicle: state.extra as Vehicle?,
      ),
    ),
    GoRoute(
      path: '${AppRoutes.antrian}/:id',
      builder: (context, state) =>
          WoDetailScreen(workOrderId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '${AppRoutes.inventori}/:id',
      builder: (context, state) => PartDetailScreen(
        partId: state.pathParameters['id'] ?? '',
      ),
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
];

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
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
