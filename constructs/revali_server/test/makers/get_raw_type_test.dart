import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/get_raw_type.dart';
import 'package:test/test.dart';

void main() {
  group('getRawType', () {
    test('preserves list element type', () {
      final type = ServerType(
        name: 'List<int>',
        iterableType: IterableType.list,
        typeArguments: [ServerType(name: 'int', isPrimitive: true)],
      );

      expect(getRawType(type), 'List<int>');
    });

    test('unwraps stream to typed list element', () {
      final listType = ServerType(
        name: 'List<int>',
        iterableType: IterableType.list,
        typeArguments: [ServerType(name: 'int', isPrimitive: true)],
      );

      final type = ServerType(
        name: 'Stream<List<int>>',
        isStream: true,
        typeArguments: [listType],
      );

      expect(getRawType(type), 'List<int>');
    });
  });
}
