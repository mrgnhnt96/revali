import 'package:server_client_gen/models/client_imports.dart';
import 'package:server_client_gen/models/client_method.dart';
import 'package:server_client_gen/models/client_return_type.dart';
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
        returnType: ClientReturnType(
          fullName: 'fullName',
          resolvedName: 'resolvedName',
          isStream: false,
          import: ClientImports([]),
          isPrimitive: false,
          isIterable: false,
          hasFromJson: false,
          isVoid: false,
        ),
        isSse: false,
        isWebsocket: false,
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
    });

    group('#fullPath', () {
      test('should return the path with a starting slash', () {
        final m = method(parentPath: 'parentPath', path: 'path');

        expect(m.resolvedPath, '/parentPath/path');
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
    });
  });
}
