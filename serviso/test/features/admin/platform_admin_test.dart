import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/router/app_router.dart';
import 'package:serviso/features/admin/data/admin_repository.dart';
import 'package:serviso/features/admin/models/admin_models.dart';
import 'package:serviso/features/auth/models/profile.dart';

void main() {
  group('FakeAdminRepository Platform Admin methods', () {
    late FakeAdminRepository repo;

    setUp(() {
      repo = FakeAdminRepository();
    });

    test('getPlatformSummary menghitung metrik platform dengan benar', () async {
      final summary = await repo.getPlatformSummary();
      expect(summary.totalShopsCount, 2);
      expect(summary.activeShopsCount, 1);
      expect(summary.inactiveShopsCount, 1);
      expect(summary.totalUsersCount, 2);
    });

    test('listShops filter berdasarkan status dan pencarian', () async {
      final allShops = await repo.listShops();
      expect(allShops.length, 2);

      final activeOnly = await repo.listShops(isActive: true);
      expect(activeOnly.length, 1);
      expect(activeOnly.first.slug, 'maju-jaya');

      final inactiveOnly = await repo.listShops(isActive: false);
      expect(inactiveOnly.length, 1);
      expect(inactiveOnly.first.slug, 'berkah-abadi');

      final searchMaju = await repo.listShops(search: 'maju');
      expect(searchMaju.length, 1);
      expect(searchMaju.first.name, 'Bengkel Maju Jaya');
    });

    test('getShopDetail mengembalikan toko atau melempar jika tidak ditemukan', () async {
      final shop = await repo.getShopDetail('shop-1');
      expect(shop.name, 'Bengkel Maju Jaya');
      expect(shop.isActive, isTrue);

      expect(
        () => repo.getShopDetail('non-existent'),
        throwsException,
      );
    });

    test('setShopActive berhasil mengubah status toko', () async {
      final before = await repo.getShopDetail('shop-2');
      expect(before.isActive, isFalse);

      await repo.setShopActive('shop-2', true);

      final after = await repo.getShopDetail('shop-2');
      expect(after.isActive, isTrue);
    });

    test('getShopUsers dan getShopStats mengembalikan data terkait', () async {
      final users = await repo.getShopUsers('shop-1');
      expect(users.isNotEmpty, isTrue);

      final stats = await repo.getShopStats('shop-1');
      expect(stats.totalWorkOrders, 12);
      expect(stats.totalCustomers, 8);
      expect(stats.totalDirectSales, 25);
    });
  });

  group('ShopItem & PlatformSummary models', () {
    test('ShopItem.fromMap memetakan JSON dengan benar', () {
      final shop = ShopItem.fromMap({
        'id': 's100',
        'name': 'Bengkel Kilat',
        'slug': 'kilat',
        'is_active': true,
        'address': 'Jl. Kilat No. 1',
        'phone': '08111111',
        'created_at': '2026-01-15T10:00:00Z',
      });

      expect(shop.id, 's100');
      expect(shop.name, 'Bengkel Kilat');
      expect(shop.slug, 'kilat');
      expect(shop.isActive, isTrue);
      expect(shop.address, 'Jl. Kilat No. 1');
      expect(shop.phone, '08111111');
      expect(shop.createdAt.year, 2026);
    });
  });

  group('authGuardRedirect proteksi /platform', () {
    const regularUser = Profile(
      id: 'u1',
      username: 'budi',
      fullName: 'Budi',
      role: UserRole.admin,
      isActive: true,
      isPlatformAdmin: false,
    );

    const platformAdmin = Profile(
      id: 'pa1',
      username: 'superadmin',
      fullName: 'Super Admin',
      role: UserRole.admin,
      isActive: true,
      isPlatformAdmin: true,
      shopId: null,
    );

    test('user biasa diblokir dari /platform, dialihkan ke /beranda', () {
      final target = authGuardRedirect(
        session: const AsyncData<Profile?>(regularUser),
        isAdmin: true,
        isPlatformAdmin: false,
        location: AppRoutes.platformAdmin,
      );
      expect(target, AppRoutes.beranda);
    });

    test('user biasa diblokir dari /platform/toko/:id, dialihkan ke /beranda', () {
      final target = authGuardRedirect(
        session: const AsyncData<Profile?>(regularUser),
        isAdmin: true,
        isPlatformAdmin: false,
        location: '/platform/toko/shop-1',
      );
      expect(target, AppRoutes.beranda);
    });

    test('platform admin lolos ke /platform dan /platform/toko/:id', () {
      final targetMain = authGuardRedirect(
        session: const AsyncData<Profile?>(platformAdmin),
        isAdmin: true,
        isPlatformAdmin: true,
        location: AppRoutes.platformAdmin,
      );
      expect(targetMain, isNull);

      final targetDetail = authGuardRedirect(
        session: const AsyncData<Profile?>(platformAdmin),
        isAdmin: true,
        isPlatformAdmin: true,
        location: '/platform/toko/shop-1',
      );
      expect(targetDetail, isNull);
    });
  });
}
