import 'package:revali_router/src/data/data_impl.dart';
import 'package:test/test.dart';

void main() {
  group(DataImpl, () {
    group('#add', () {
      test('An item should be stored when it is added', () {
        final data = DataImpl();
        const instance = 'TestItem';

        data.add<String>(instance);

        expect(data.get<String>(), equals(instance));
      });
    });

    group('#get', () {
      test('No item should be found when it has not been added', () {
        final data = DataImpl();

        expect(data.get<int>(), isNull);
      });

      test('The correct item should be retrieved when it has been added', () {
        const instance = 42;
        final data = DataImpl()..add<int>(instance);

        expect(data.get<int>(), equals(instance));
      });
    });

    group('#has', () {
      test('The system should confirm presence when an item has been added',
          () {
        final data = DataImpl()..add<double>(3.14);

        expect(data.has<double>(), isTrue);
      });

      test('The system should confirm absence when an item has not been added',
          () {
        final data = DataImpl();

        expect(data.has<bool>(), isFalse);
      });
    });

    group('#contains', () {
      test('The system should confirm presence when the exact item exists', () {
        const instance = 'SpecificItem';
        final data = DataImpl()..add<String>(instance);

        expect(data.contains<String>(instance), isTrue);
      });

      test('The system should confirm absence when the item does not exist',
          () {
        final data = DataImpl();

        expect(data.contains<int>(123), isFalse);
      });
    });

    group('#remove', () {
      test('The system should remove an item when it exists', () {
        final data = DataImpl()..add<String>('RemovableItem');

        final removed = data.remove<String>();

        expect(removed, isTrue);
        expect(data.has<String>(), isFalse);
      });

      test('The system should not remove anything when the item does not exist',
          () {
        final data = DataImpl();

        final removed = data.remove<int>();

        expect(removed, isFalse);
      });

      test('The system should keep other items intact when removing one item',
          () {
        final data = DataImpl()
          ..add<String>('RemovableItem')
          ..add<int>(42)
          ..remove<String>();

        expect(data.has<String>(), isFalse);
        expect(data.has<int>(), isTrue);
      });
    });
  });
}
