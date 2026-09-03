import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icons.dart';
import '../widgets/pastel_pop_bottom_bar.dart';

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
import '../../features/inventori/models/part.dart';
import '../../features/inventori/screens/inventori_screen.dart';
import '../../features/inventori/screens/part_detail_screen.dart';
import '../../features/inventori/screens/part_form_screen.dart';
import '../../features/laporan/controllers/report_controllers.dart';
import '../../features/laporan/screens/details/debt_detail_screen.dart';
import '../../features/laporan/screens/details/direct_sale_detail_screen.dart';
import '../../features/laporan/screens/details/hpp_detail_screen.dart';
import '../../features/laporan/screens/details/omset_detail_screen.dart';
import '../../features/laporan/screens/details/part_sold_detail_screen.dart';
import '../../features/laporan/screens/details/profit_detail_screen.dart';
import '../../features/laporan/screens/details/wo_done_detail_screen.dart';
import '../../features/laporan/screens/laporan_screen.dart';
import '../../features/direct_sales/screens/direct_sale_screen.dart';
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
  static const laporanOmset = '/laporan/omset';
  static const laporanLaba = '/laporan/laba';
  static const laporanHpp = '/laporan/hpp';
  static const laporanPenjualanLangsung = '/laporan/penjualan-langsung';
  static const laporanHutang = '/laporan/hutang';
  static const laporanWoSelesai = '/laporan/wo-selesai';
  static const laporanPartTerjual = '/laporan/part-terjual';
  static const profil = '/profil';
  static const admin = '/admin';
  static const platformAdmin = '/platform';
  static const adminUsers = '/admin/users';
  static const adminAuditLogs = '/admin/audit-logs';
  static const pengaturan = '/admin/pengaturan';
  static const pelanggan = '/pelanggan';
  static const pelangganDetail = '/pelanggan/:id';
  static const woBaru = '/antrian/baru';
  static const jualLangsung = '/jual-langsung';
  static const inventoriTambah = '/inventori/tambah';
  static const inventoriEdit = '/inventori/:id/edit';
}

String? authGuardRedirect({
  required AsyncValue<Profile?> session,
  required bool isAdmin,
  required bool isPlatformAdmin,
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
  if (location.startsWith('/admin') && !isAdmin && !isPlatformAdmin) {
    return AppRoutes.beranda;
  }
  if (location.startsWith('/platform') && !isPlatformAdmin) {
    return AppRoutes.beranda;
  }
  final isLaporanOwnerOnly = location.startsWith(AppRoutes.laporanLaba) ||
      location.startsWith(AppRoutes.laporanHpp) ||
      location.startsWith(AppRoutes.laporanHutang);
  if (isLaporanOwnerOnly && !isAdmin && !isPlatformAdmin) {
    return AppRoutes.laporan;
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
    final isPlatformAdmin = _ref.read(isPlatformAdminProvider);
    final target = authGuardRedirect(
      session: session,
      isAdmin: isAdmin,
      isPlatformAdmin: isPlatformAdmin,
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
    if (target == AppRoutes.laporan &&
        (state.uri.path.startsWith(AppRoutes.laporanLaba) ||
            state.uri.path.startsWith(AppRoutes.laporanHpp) ||
            state.uri.path.startsWith(AppRoutes.laporanHutang))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Hanya pemilik dapat membuka rincian ini'),
          ),
        );
      });
    }
    return target;
  }
}

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
      path: AppRoutes.jualLangsung,
      builder: (context, state) => const DirectSaleScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.antrian}/:id',
      builder: (context, state) =>
          WoDetailScreen(workOrderId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.inventoriTambah,
      builder: (context, state) => const PartFormScreen(),
    ),
    GoRoute(
      path: '/inventori/:id/edit',
      builder: (context, state) => PartFormScreen(
        partId: state.pathParameters['id'],
        initial: state.extra is Part ? state.extra as Part : null,
      ),
    ),
    GoRoute(
      path: '${AppRoutes.inventori}/:id',
      builder: (context, state) => PartDetailScreen(
        partId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.laporanOmset,
      builder: (context, state) => const OmsetDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.laporanWoSelesai,
      builder: (context, state) => const WoDoneDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.laporanPartTerjual,
      builder: (context, state) => const PartSoldDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.laporanLaba,
      builder: (context, state) => const ProfitDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.laporanHpp,
      builder: (context, state) => const HppDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.laporanPenjualanLangsung,
      builder: (context, state) => const DirectSaleDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.laporanHutang,
      builder: (context, state) => const DebtDetailScreen(),
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
    final canPop = GoRouter.of(context).canPop();
    final isHome = navigationShell.currentIndex == 0;

    return PopScope(
      canPop: isHome && !canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (canPop) return;
        if (!isHome) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: PastelPopBottomBar(
          currentIndex: navigationShell.currentIndex,
          onCenterActionTap: () => context.push(AppRoutes.woBaru),
          onTap: (index) {
            if (index == 0) {
              ref.invalidate(dashboardSummaryProvider);
            } else if (index == 3) {
              ref.invalidate(laporanDailySummariesProvider);
              ref.invalidate(topPartsProvider);
              ref.invalidate(dailyRevenueByMethodProvider);
            }
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: [
            PastelPopBottomBarItem(
              icon: AppIcons.home,
              selectedIcon: AppIcons.homeFill,
              label: 'Beranda',
            ),
            PastelPopBottomBarItem(
              icon: AppIcons.queue,
              selectedIcon: AppIcons.queueFill,
              label: 'Antrian',
            ),
            PastelPopBottomBarItem(
              icon: AppIcons.inventory,
              selectedIcon: AppIcons.inventoryFill,
              label: 'Inventori',
            ),
            PastelPopBottomBarItem(
              icon: AppIcons.report,
              selectedIcon: AppIcons.reportFill,
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}

