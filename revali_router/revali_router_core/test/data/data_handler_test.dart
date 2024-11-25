import 'package:revali_router_core/data/data_handler.dart';
import 'package:test/test.dart';

void main() {
  group(DataHandler, () {
    group('#add', () {
      test('An item should be stored when it is added', () {
        final dataHandler = DataHandler();
        const instance = 'TestItem';

        dataHandler.add<String>(instance);

        expect(dataHandler.get<String>(), equals(instance));
      });
    });

    group('#get', () {
      test('No item should be found when it has not been added', () {
        final dataHandler = DataHandler();

        expect(dataHandler.get<int>(), isNull);
      });

      test('The correct item should be retrieved when it has been added', () {
        const instance = 42;
        final dataHandler = DataHandler()..add<int>(instance);

        expect(dataHandler.get<int>(), equals(instance));
      });
    });

    group('#has', () {
      test('The system should confirm presence when an item has been added',
          () {
        final dataHandler = DataHandler()..add<double>(3.14);

        expect(dataHandler.has<double>(), isTrue);
      });

      test('The system should confirm absence when an item has not been added',
          () {
        final dataHandler = DataHandler();

        expect(dataHandler.has<bool>(), isFalse);
      });
    });

    group('#contains', () {
      test('The system should confirm presence when the exact item exists', () {
        const instance = 'SpecificItem';
        final dataHandler = DataHandler()..add<String>(instance);

        expect(dataHandler.contains<String>(instance), isTrue);
      });

      test('The system should confirm absence when the item does not exist',
          () {
        final dataHandler = DataHandler();

        expect(dataHandler.contains<int>(123), isFalse);
      });
    });

    group('#remove', () {
      test('The system should remove an item when it exists', () {
        final dataHandler = DataHandler()..add<String>('RemovableItem');

        final removed = dataHandler.remove<String>();

        expect(removed, isTrue);
        expect(dataHandler.has<String>(), isFalse);
      });

      test('The system should not remove anything when the item does not exist',
          () {
        final dataHandler = DataHandler();

        final removed = dataHandler.remove<int>();

        expect(removed, isFalse);
      });

      test('The system should keep other items intact when removing one item',
          () {
        final dataHandler = DataHandler()
          ..add<String>('RemovableItem')
          ..add<int>(42)
          ..remove<String>();

        expect(dataHandler.has<String>(), isFalse);
        expect(dataHandler.has<int>(), isTrue);
      });
    });
  });
}
