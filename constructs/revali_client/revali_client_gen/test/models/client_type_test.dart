import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_impl_method.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:test/test.dart';

void main() {
  group('ClientType.typeForClient', () {
    ClientMethod method({
      required ClientType returnType,
    }) {
      return ClientMethod(
        name: 'view',
        parentPath: 'api',
        method: 'GET',
        path: ':id',
        returnType: returnType,
        parameters: const [],
        lifecycleComponents: const [],
        isSse: false,
        websocketType: WebsocketType.none,
        isExcluded: false,
      );
    }

    ClientType listIntType() {
      return ClientType(
        name: 'List<int>',
        iterableType: IterableType.list,
        typeArguments: [
          ClientType(name: 'int', isPrimitive: true),
        ],
      );
    }

    ClientType streamListIntType() {
      return ClientType(
        name: 'Stream<List<int>>',
        isStream: true,
        typeArguments: [listIntType()],
      );
    }

    test('preserves Stream<List<int>> for byte stream responses', () {
      final returnType = streamListIntType();
      final clientMethod = method(returnType: returnType);

      expect(clientMethod.returnType.typeForClient.isStream, isTrue);
      expect(clientMethod.returnType.typeForClient.name, 'Stream<List<int>>');
    });

    test('unwraps Future<Stream<List<int>>> to Stream<List<int>>', () {
      final returnType = ClientType(
        name: 'Future<Stream<List<int>>>',
        isFuture: true,
        typeArguments: [streamListIntType()],
      );
      final clientMethod = method(returnType: returnType);

      expect(clientMethod.returnType.typeForClient.isStream, isTrue);
      expect(clientMethod.returnType.typeForClient.isFuture, isFalse);
      expect(clientMethod.returnType.typeForClient.name, 'Stream<List<int>>');
    });

    test('generates a streaming implementation for Future<Stream<List<int>>>', () {
      final returnType = ClientType(
        name: 'Future<Stream<List<int>>>',
        isFuture: true,
        typeArguments: [streamListIntType()],
      );
      final clientMethod = method(returnType: returnType);
      final generated =
          createImplMethod(clientMethod).accept(DartEmitter()).toString();

      expect(generated, contains('async*'));
      expect(generated, contains('yield*'));
      expect(generated, isNot(contains('response.toList()')));
    });
  });
}
