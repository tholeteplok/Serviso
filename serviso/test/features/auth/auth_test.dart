import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/router/app_router.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';

Profile _profile(UserRole role, {bool active = true}) => Profile(
      id: 'u1',
      username: 'user',
      fullName: 'Budi',
      role: role,
      isActive: active,
      isPlatformAdmin: false,
    );

void main() {
  group('authGuardRedirect', () {
    test('anon ke /beranda dialihkan ke /login', () {
      final target = authGuardRedirect(
        session: const AsyncData<Profile?>(null),
        isAdmin: false,
        isPlatformAdmin: false,
        location: AppRoutes.beranda,
      );
      expect(target, AppRoutes.login);
    });

    test('kasir diblokir dari /admin, dialihkan ke /beranda', () {
      final target = authGuardRedirect(
        session: AsyncData<Profile?>(_profile(UserRole.kasir)),
        isAdmin: false,
        isPlatformAdmin: false,
        location: AppRoutes.admin,
      );
      expect(target, AppRoutes.beranda);
    });

    test('admin lolos ke /admin', () {
      final target = authGuardRedirect(
        session: AsyncData<Profile?>(_profile(UserRole.admin)),
        isAdmin: true,
        isPlatformAdmin: false,
        location: AppRoutes.admin,
      );
      expect(target, isNull);
    });

    test('saat sesi loading tampilkan splash untuk rute selain login', () {
      final target = authGuardRedirect(
        session: const AsyncLoading<Profile?>(),
        isAdmin: false,
        isPlatformAdmin: false,
        location: AppRoutes.beranda,
      );
      expect(target, AppRoutes.splash);
    });

    test('saat sesi loading di login jangan dialihkan ke splash', () {
      final target = authGuardRedirect(
        session: const AsyncLoading<Profile?>(),
        isAdmin: false,
        isPlatformAdmin: false,
        location: AppRoutes.login,
      );
      expect(target, isNull);
    });
  });

  group('Profile mapping & is_admin', () {
    test('role admin -> isAdmin true, kasir/mekanik false', () {
      expect(_profile(UserRole.admin).isAdmin, isTrue);
      expect(_profile(UserRole.kasir).isAdmin, isFalse);
      expect(_profile(UserRole.mekanik).isAdmin, isFalse);
    });

    test('fromMap memetakan field dengan benar', () {
      final p = Profile.fromMap({
        'id': 'abc',
        'username': 'kasir1',
        'email': 'a@b.co',
        'full_name': 'Kasir Satu',
        'role': 'admin',
        'is_active': false,
        'phone': '0812',
        'shop_id': 'shop-1',
        'shops': {
          'name': 'Bengkel Maju',
          'slug': 'bengkel-maju',
        },
      });
      expect(p.id, 'abc');
      expect(p.username, 'kasir1');
      expect(p.email, 'a@b.co');
      expect(p.fullName, 'Kasir Satu');
      expect(p.role, UserRole.admin);
      expect(p.isActive, isFalse);
      expect(p.phone, '0812');
      expect(p.shopId, 'shop-1');
      expect(p.shopName, 'Bengkel Maju');
      expect(p.shopSlug, 'bengkel-maju');
      expect(p.isAdmin, isTrue);
    });

    test('isAdminProvider true hanya untuk admin', () {
      final container = ProviderContainer();
      container
          .read(sessionProvider.notifier)
          .state = AsyncData<Profile?>(_profile(UserRole.admin));
      expect(container.read(isAdminProvider), isTrue);
      container
          .read(sessionProvider.notifier)
          .state = AsyncData<Profile?>(_profile(UserRole.kasir));
      expect(container.read(isAdminProvider), isFalse);
    });
  });

  group('logout memanggil repository (record_auth_event best-effort)', () {
    test('logout tidak melempar walau record_auth_event gagal', () async {
      final fake = FakeAuthRepository()
        ..profileToReturn = _profile(UserRole.admin)
        ..recordEventThrows = true;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      await container
          .read(sessionProvider.notifier)
          .login(username: 'user', password: 'pass', shopSlug: 'test-shop');
      expect(container.read(sessionProvider).valueOrNull, isNotNull);

      await container.read(sessionProvider.notifier).logout();

      expect(fake.logoutCalled, isTrue);
      expect(container.read(sessionProvider).valueOrNull, isNull);
    });

    test('logout tetap sukses walau _recordEvent melempar (swallow)', () async {
      final fake = FakeAuthRepository()
        ..profileToReturn = _profile(UserRole.kasir)
        ..recordEventThrows = true;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      await container
          .read(sessionProvider.notifier)
          .login(username: 'user', password: 'pass', shopSlug: 'test-shop');

      final future = container.read(sessionProvider.notifier).logout();
      await expectLater(future, completes);
      expect(container.read(sessionProvider).valueOrNull, isNull);
    });
  });

  group('resolveLoginEmail (Universal Login)', () {
    test('username biasa ditambahkan domain sintetis', () {
      expect(resolveLoginEmail('admin', 'test-shop'), 'admin.test-shop@users.serviso.app');
      expect(resolveLoginEmail('  kasir01  ', 'test-shop'), 'kasir01.test-shop@users.serviso.app');
    });

    test('email langsung dipakai apa adanya', () {
      expect(resolveLoginEmail('owner@gmail.com', 'test-shop'), 'owner@gmail.com');
      expect(resolveLoginEmail('  User@Bengkel.co.id  ', 'test-shop'), 'user@bengkel.co.id');
    });

    test('email domain sintetis tetap valid', () {
      expect(
        resolveLoginEmail('admin.test-shop@users.serviso.app', 'test-shop'),
        'admin.test-shop@users.serviso.app',
      );
    });
  });
}
