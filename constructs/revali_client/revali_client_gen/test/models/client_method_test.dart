import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:test/test.dart';

void main() {
  group(ClientMethod, () {
    ClientMethod method({
      String? parentPath,
      String? path,
    }) {
      return ClientMethod(
        name: 'name',
        parameters: [],
        lifecycleComponents: [],
        returnType: ClientType(
          isStream: false,
          import: ClientImports([]),
          isPrimitive: false,
          isVoid: false,
          isStringContent: false,
          isFuture: false,
          name: 'name',
          hasFromJsonConstructor: false,
          isNullable: false,
          iterableType: null,
          isRecord: false,
          recordProps: null,
          isDynamic: false,
          isMap: false,
          typeArguments: [],
          hasToJsonMember: false,
        ),
        isSse: false,
        websocketType: WebsocketType.none,
        path: path,
        parentPath: parentPath ?? '',
        method: 'GET',
      );
    }

    group('#params', () {
      test('should return empty list when path contains no params', () {
        final m = method(path: 'path', parentPath: 'parentPath');

        expect(m.params, isEmpty);
      });

      test('should return list of params when path contains params', () {
        final m = method(path: 'product/:productId', parentPath: 'parentPath');

        expect(m.params, ['productId']);
      });

      test('should return list of params when path contains multiple params',
          () {
        final m =
            method(path: 'product/:productId', parentPath: 'shop/:shopId');

        expect(m.params, ['shopId', 'productId']);
      });

      test('should index params when multiple params have the same name', () {
        final m = method(
          parentPath: 'shop/:id',
          path: 'product/:id',
        );

        expect(m.params, ['id1', 'id2']);
      });

      test('should format to comply with dart syntax', () {
        final m = method(path: ':product-id', parentPath: 'parentPath');

        expect(m.params, ['productId']);
      });
    });

    group('#fullPath', () {
      test('should return the path with a starting slash', () {
        final m = method(parentPath: 'parentPath', path: 'path');

        expect(m.fullPath, '/parentPath/path');
      });

      test('should return the path without modifications', () {
        final m =
            method(parentPath: 'shop/:shop-id', path: 'product/:product-id');

        expect(m.fullPath, '/shop/:shop-id/product/:product-id');
      });
    });

    group('#resolvedPath', () {
      test('should return the path with a starting slash', () {
        final m = method(parentPath: 'parentPath', path: 'path');

        expect(m.resolvedPath, '/parentPath/path');
      });

      test('should resolve parent params', () {
        final m = method(parentPath: 'shop/:shopId', path: 'path');

        expect(m.resolvedPath, r'/shop/${shopId}/path');
      });

      test('should resolve path params', () {
        final m = method(parentPath: 'parentPath', path: 'product/:productId');

        expect(m.resolvedPath, r'/parentPath/product/${productId}');
      });

      test('should resolve params with same name', () {
        final m = method(parentPath: 'shop/:id', path: 'product/:id');

        expect(m.resolvedPath, r'/shop/${id1}/product/${id2}');
      });

      test('should format the param to comply with dart syntax', () {
        final m =
            method(parentPath: 'shop/:shop-id', path: 'product/:product-id');

        expect(m.resolvedPath, r'/shop/${shopId}/product/${productId}');
      });

      test('should format the param to comply with dart syntax with repeat ids',
          () {
        final m = method(parentPath: 'shop/:some-id', path: 'product/:some-id');

        expect(m.resolvedPath, r'/shop/${someId1}/product/${someId2}');
      });
    });
  });
}
