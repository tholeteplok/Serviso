import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/features/inventori/data/service_repository.dart';
import 'package:serviso/features/inventori/models/service_item.dart';

void main() {
  group('FakeServiceRepository Tests', () {
    late FakeServiceRepository repo;

    setUp(() {
      repo = FakeServiceRepository();
    });

    test('create and list services', () async {
      final s1 = await repo.create(const ServiceInput(
        name: 'Ganti Oli Mesin',
        code: 'JS-OLI',
        price: 20000,
      ));
      final s2 = await repo.create(const ServiceInput(
        name: 'Tune Up Injeksi',
        code: 'JS-TUNE',
        price: 75000,
      ));

      final all = await repo.list();
      expect(all.length, 2);
      expect(all.any((s) => s.id == s1.id), isTrue);
      expect(all.any((s) => s.id == s2.id), isTrue);
    });

    test('list with search keyword filters by name and code', () async {
      await repo.create(const ServiceInput(
        name: 'Ganti Oli Mesin',
        code: 'JS-OLI',
        price: 20000,
      ));
      await repo.create(const ServiceInput(
        name: 'Tune Up Motor Matic',
        code: 'JS-TUNE',
        price: 60000,
      ));
      await repo.create(const ServiceInput(
        name: 'Cuci Motor Salju',
        code: 'JS-CUCI',
        price: 15000,
      ));

      final searchName = await repo.list(search: 'Oli');
      expect(searchName.length, 1);
      expect(searchName.first.name, 'Ganti Oli Mesin');

      final searchCode = await repo.list(search: 'TUNE');
      expect(searchCode.length, 1);
      expect(searchCode.first.name, 'Tune Up Motor Matic');
    });

    test('update service changes values', () async {
      final created = await repo.create(const ServiceInput(
        name: 'Tambal Ban',
        price: 10000,
      ));

      final updated = await repo.update(
        created.id,
        const ServiceInput(
          name: 'Tambal Ban Tubeless',
          price: 15000,
        ),
      );

      expect(updated.name, 'Tambal Ban Tubeless');
      expect(updated.price, 15000);

      final fetched = await repo.getById(created.id);
      expect(fetched?.name, 'Tambal Ban Tubeless');
      expect(fetched?.price, 15000);
    });

    test('delete service removes from list', () async {
      final created = await repo.create(const ServiceInput(
        name: 'Jasa Las',
        price: 30000,
      ));

      var list = await repo.list();
      expect(list.length, 1);

      await repo.delete(created.id);
      list = await repo.list();
      expect(list.isEmpty, isTrue);

      final fetched = await repo.getById(created.id);
      expect(fetched, isNull);
    });
  });
}
