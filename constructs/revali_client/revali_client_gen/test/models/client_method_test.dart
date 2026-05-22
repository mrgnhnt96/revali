import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/creators/create_signature.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_client_gen/models/client_lifecycle_component_method.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:test/test.dart';

void main() {
  group(ClientMethod, () {
    ClientMethod method({String? parentPath, String? path}) {
      return ClientMethod(
        name: 'name',
        parameters: [],
        lifecycleComponents: [],
        returnType: ClientType(name: 'name'),
        isSse: false,
        websocketType: WebsocketType.none,
        path: path,
        parentPath: parentPath ?? '',
        method: 'GET',
        isExcluded: false,
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

      test(
        'should return list of params when path contains multiple params',
        () {
          final m = method(
            path: 'product/:productId',
            parentPath: 'shop/:shopId',
          );

          expect(m.params, ['shopId', 'productId']);
        },
      );

      test('should index params when multiple params have the same name', () {
        final m = method(parentPath: 'shop/:id', path: 'product/:id');

        expect(m.params, ['id1', 'id2']);
      });

      test('should format to comply with dart syntax', () {
        final m = method(path: ':product-id', parentPath: 'parentPath');

        expect(m.params, ['productId']);
      });
    });

    group('#fullPath', () {
      test('should ignore the parent when parent is empty', () {
        final m = method(parentPath: '', path: 'path');

        expect(m.fullPath, '/path');
      });

      test('should return the path with a starting slash', () {
        final m = method(parentPath: 'parentPath', path: 'path');

        expect(m.fullPath, '/parentPath/path');
      });

      test('should return the path without modifications', () {
        final m = method(
          parentPath: 'shop/:shop-id',
          path: 'product/:product-id',
        );

        expect(m.fullPath, '/shop/:shop-id/product/:product-id');
      });
    });

    group('#resolvedPath', () {
      test('should ignore the parent when parent is empty', () {
        final m = method(parentPath: '', path: 'path');

        expect(m.resolvedPath, '/path');
      });

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
        final m = method(
          parentPath: 'shop/:shop-id',
          path: 'product/:product-id',
        );

        expect(m.resolvedPath, r'/shop/${shopId}/product/${productId}');
      });

      test(
        'should format the param to comply with dart syntax with repeat ids',
        () {
          final m = method(
            parentPath: 'shop/:some-id',
            path: 'product/:some-id',
          );

          expect(m.resolvedPath, r'/shop/${someId1}/product/${someId2}');
        },
      );
    });

    group('#allParams', () {
      ClientParam bodyParam({required String name, required String type}) {
        return ClientParam(
          name: name,
          position: ParameterPosition.body,
          type: ClientType(name: type),
          access: [],
          acceptMultiple: false,
          hasDefaultValue: false,
        );
      }

      test(
        'excludes lifecycle body param when it matches endpoint body type',
        () {
          final endpointBody = bodyParam(name: 'body', type: 'UserBody');
          final lifecycleBody = bodyParam(name: 'body', type: 'UserBody');

          final m = ClientMethod(
            name: 'createUser',
            parentPath: '',
            method: 'POST',
            path: '',
            returnType: ClientType(name: 'void'),
            parameters: [endpointBody],
            lifecycleComponents: [
              ClientLifecycleComponent(
                guards: [
                  ClientLifecycleComponentMethod(
                    parameters: [lifecycleBody],
                    returnType: 'GuardResult',
                  ),
                ],
                middlewares: [],
                interceptors: (pre: [], post: []),
                instantiatedTypeArguments: [ClientType(name: 'UserBody')],
                genericTypeParameterNames: const ['T'],
              ),
            ],
            isSse: false,
            websocketType: WebsocketType.none,
            isExcluded: false,
          );

          expect(m.allParams, [endpointBody]);
        },
      );

      test('excludes unsubstituted generic lifecycle '
          'body when type arg is provided', () {
        final endpointBody = bodyParam(name: 'body', type: 'GetBody');
        final lifecycleBody = bodyParam(name: 'body', type: 'T');

        final m = ClientMethod(
          name: 'get',
          parentPath: '',
          method: 'GET',
          path: '',
          returnType: ClientType(name: 'Map<String, Object?>'),
          parameters: [endpointBody],
          lifecycleComponents: [
            ClientLifecycleComponent(
              guards: [
                ClientLifecycleComponentMethod(
                  parameters: [lifecycleBody],
                  returnType: 'GuardResult',
                ),
              ],
              middlewares: [],
              interceptors: (pre: [], post: []),
              instantiatedTypeArguments: [ClientType(name: 'GetBody')],
              genericTypeParameterNames: const ['T'],
            ),
          ],
          isSse: false,
          websocketType: WebsocketType.none,
          isExcluded: false,
        );

        expect(m.allParams, [endpointBody]);
      });

      test('keeps lifecycle param when endpoint param type differs', () {
        final endpointBody = bodyParam(name: 'request', type: 'UserBody');
        final lifecycleHeader = ClientParam(
          name: 'token',
          position: ParameterPosition.header,
          type: ClientType(name: 'String'),
          access: [],
          acceptMultiple: false,
          hasDefaultValue: false,
        );

        final m = ClientMethod(
          name: 'createUser',
          parentPath: '',
          method: 'POST',
          path: '',
          returnType: ClientType(name: 'void'),
          parameters: [endpointBody],
          lifecycleComponents: [
            ClientLifecycleComponent(
              guards: [
                ClientLifecycleComponentMethod(
                  parameters: [lifecycleHeader],
                  returnType: 'GuardResult',
                ),
              ],
              middlewares: [],
              interceptors: (pre: [], post: []),
              instantiatedTypeArguments: const [],
              genericTypeParameterNames: const [],
            ),
          ],
          isSse: false,
          websocketType: WebsocketType.none,
          isExcluded: false,
        );

        expect(m.allParams, [lifecycleHeader, endpointBody]);
      });

      test('dedupes duplicate lifecycle and endpoint '
          'body params with same binding', () {
        final endpointBody = bodyParam(name: 'body', type: 'GetBody');
        final lifecycleBody = bodyParam(name: 'body', type: 'GetBody');
        final component = ClientLifecycleComponent(
          guards: [
            ClientLifecycleComponentMethod(
              parameters: [lifecycleBody],
              returnType: 'GuardResult',
            ),
          ],
          middlewares: [],
          interceptors: (pre: [], post: []),
          instantiatedTypeArguments: [ClientType(name: 'GetBody')],
          genericTypeParameterNames: const ['T'],
        );

        final m = ClientMethod(
          name: 'get',
          parentPath: '',
          method: 'GET',
          path: '',
          returnType: ClientType(name: 'Map<String, Object?>'),
          parameters: [endpointBody],
          lifecycleComponents: [component, component],
          isSse: false,
          websocketType: WebsocketType.none,
          isExcluded: false,
        );

        expect(m.allParams, [endpointBody]);
      });

      test(
        'excludes lifecycle body when endpoint exposes the same type as query',
        () {
          final endpointQuery = ClientParam(
            name: 'body',
            position: ParameterPosition.query,
            type: ClientType(name: 'GetBody'),
            access: [],
            acceptMultiple: false,
            hasDefaultValue: false,
          );
          final lifecycleBody = bodyParam(name: 'body', type: 'GetBody');

          final m = ClientMethod(
            name: 'get',
            parentPath: '',
            method: 'GET',
            path: '',
            returnType: ClientType(name: 'Map<String, Object?>'),
            parameters: [endpointQuery],
            lifecycleComponents: [
              ClientLifecycleComponent(
                guards: [
                  ClientLifecycleComponentMethod(
                    parameters: [lifecycleBody],
                    returnType: 'GuardResult',
                  ),
                ],
                middlewares: [],
                interceptors: (pre: [], post: []),
                instantiatedTypeArguments: [ClientType(name: 'GetBody')],
                genericTypeParameterNames: const ['T'],
              ),
            ],
            isSse: false,
            websocketType: WebsocketType.none,
            isExcluded: false,
          );

          expect(m.allParams, [endpointQuery]);
          expect(
            createSignature(
              m,
            ).optionalParameters.where((param) => param.name == 'body').length,
            1,
          );
        },
      );
    });
  });
}
