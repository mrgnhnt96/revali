import 'package:revali_swagger/builders/openapi_builder.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/enums/param_location.dart';
import 'package:revali_swagger/models/swagger_controller.dart';
import 'package:revali_swagger/models/swagger_method.dart';
import 'package:revali_swagger/models/swagger_param.dart';
import 'package:revali_swagger/models/swagger_server.dart';
import 'package:revali_swagger/models/swagger_type.dart';
import 'package:test/test.dart';

SwaggerServer makeServer({
  String title = 'Test API',
  String version = '1.0.0',
  List<SwaggerController> controllers = const [],
}) {
  return SwaggerServer(
    info: SwaggerInfo(title: title, version: version),
    controllers: controllers,
  );
}

SwaggerController makeController({
  required String name,
  required String path,
  required List<SwaggerMethod> methods,
  bool isHidden = false,
  String tag = 'test',
}) {
  return SwaggerController(
    name: name,
    path: path,
    methods: methods,
    isHidden: isHidden,
    tag: tag,
  );
}

SwaggerMethod makeMethod({
  required String operationId,
  required String httpMethod,
  String path = '',
  bool isHidden = false,
  int defaultStatusCode = 200,
  SwaggerType? returnType,
}) {
  return SwaggerMethod(
    operationId: operationId,
    httpMethod: httpMethod,
    path: path,
    parameters: const [],
    bodyParam: null,
    returnType: returnType ?? const SwaggerType(schema: {}, isVoid: true),
    defaultStatusCode: defaultStatusCode,
    isHidden: isHidden,
    explicitResponses: const [],
  );
}

void main() {
  late SchemaRegistry registry;

  setUp(() => registry = SchemaRegistry());

  group('buildOpenApiSpec', () {
    test('emits openapi 3.0.3 version', () {
      final spec = buildOpenApiSpec(makeServer(), registry);
      expect(spec['openapi'], '3.0.3');
    });

    test('info section contains title and version', () {
      final spec = buildOpenApiSpec(
        makeServer(title: 'My API', version: '2.0.0'),
        registry,
      );
      final info = spec['info'] as Map<String, dynamic>;
      expect(info['title'], 'My API');
      expect(info['version'], '2.0.0');
    });

    test('info omits description when null', () {
      final spec = buildOpenApiSpec(makeServer(), registry);
      final info = spec['info'] as Map<String, dynamic>;
      expect(info.containsKey('description'), isFalse);
    });

    test('info includes description when provided', () {
      final server = SwaggerServer(
        info: const SwaggerInfo(
          title: 'API',
          version: '1.0.0',
          description: 'My docs',
        ),
        controllers: const [],
      );
      final spec = buildOpenApiSpec(server, registry);
      final info = spec['info'] as Map<String, dynamic>;
      expect(info['description'], 'My docs');
    });

    test('paths uses OpenAPI {param} format for :param segments', () {
      final spec = buildOpenApiSpec(
        makeServer(
          controllers: [
            makeController(
              name: 'UserController',
              path: '/users',
              tag: 'users',
              methods: [
                makeMethod(
                  operationId: 'user_getById',
                  httpMethod: 'get',
                  path: ':id',
                ),
              ],
            ),
          ],
        ),
        registry,
      );

      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths.containsKey('/users/{id}'), isTrue);
    });

    test('operation has operationId and tag', () {
      final spec = buildOpenApiSpec(
        makeServer(
          controllers: [
            makeController(
              name: 'UserController',
              path: '/users',
              tag: 'users',
              methods: [
                makeMethod(operationId: 'user_list', httpMethod: 'get'),
              ],
            ),
          ],
        ),
        registry,
      );

      final paths = spec['paths'] as Map<String, dynamic>;
      final operation = (paths['/users'] as Map<String, dynamic>)['get'] as Map;
      expect(operation['operationId'], 'user_list');
      expect((operation['tags'] as List).first, 'users');
    });

    test('hidden controllers are excluded', () {
      final spec = buildOpenApiSpec(
        makeServer(
          controllers: [
            makeController(
              name: 'AdminController',
              path: '/admin',
              tag: 'admin',
              isHidden: true,
              methods: [
                makeMethod(operationId: 'admin_list', httpMethod: 'get'),
              ],
            ),
          ],
        ),
        registry,
      );

      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths.containsKey('/admin'), isFalse);
    });

    test('hidden methods are excluded', () {
      final spec = buildOpenApiSpec(
        makeServer(
          controllers: [
            makeController(
              name: 'UserController',
              path: '/users',
              tag: 'users',
              methods: [
                makeMethod(operationId: 'user_list', httpMethod: 'get'),
                makeMethod(
                  operationId: 'user_secret',
                  httpMethod: 'post',
                  isHidden: true,
                ),
              ],
            ),
          ],
        ),
        registry,
      );

      final paths = spec['paths'] as Map<String, dynamic>;
      final pathItem = paths['/users'] as Map<String, dynamic>;
      expect(pathItem.containsKey('get'), isTrue);
      expect(pathItem.containsKey('post'), isFalse);
    });

    test('components/schemas omitted when empty', () {
      final spec = buildOpenApiSpec(makeServer(), registry);
      expect(spec.containsKey('components'), isFalse);
    });

    test('components/schemas included when registry has entries', () {
      final userRef = registry.register('User', {'type': 'object'});
      // A method whose return type $ref's User so the schema survives pruning.
      final server = makeServer(
        controllers: [
          makeController(
            name: 'UserController',
            path: '/users',
            methods: [
              makeMethod(
                operationId: 'users_list',
                httpMethod: 'get',
                returnType: SwaggerType(schema: userRef),
              ),
            ],
          ),
        ],
      );
      final spec = buildOpenApiSpec(server, registry);
      final components = spec['components'] as Map<String, dynamic>;
      expect((components['schemas'] as Map).containsKey('User'), isTrue);
    });

    test('void return type emits no-content response', () {
      final spec = buildOpenApiSpec(
        makeServer(
          controllers: [
            makeController(
              name: 'UserController',
              path: '/users',
              tag: 'users',
              methods: [
                makeMethod(
                  operationId: 'user_delete',
                  httpMethod: 'delete',
                  defaultStatusCode: 204,
                ),
              ],
            ),
          ],
        ),
        registry,
      );

      final paths = spec['paths'] as Map<String, dynamic>;
      final responses = (paths['/users'] as Map)['delete'] as Map;
      final respMap = responses['responses'] as Map;
      expect(respMap.containsKey('204'), isTrue);
      expect((respMap['204'] as Map)['description'], 'No content');
    });

    test('non-void return type emits content in response', () {
      final spec = buildOpenApiSpec(
        makeServer(
          controllers: [
            makeController(
              name: 'UserController',
              path: '/users',
              tag: 'users',
              methods: [
                makeMethod(
                  operationId: 'user_get',
                  httpMethod: 'get',
                  returnType: const SwaggerType(schema: {'type': 'string'}),
                ),
              ],
            ),
          ],
        ),
        registry,
      );

      final paths = spec['paths'] as Map<String, dynamic>;
      final operation = (paths['/users'] as Map)['get'] as Map;
      final responses = operation['responses'] as Map;
      final resp200 = responses['200'] as Map;
      expect(resp200.containsKey('content'), isTrue);
    });

    test(
      'GET with body param emits query parameter instead of requestBody',
      () {
        final spec = buildOpenApiSpec(
          makeServer(
            controllers: [
              makeController(
                name: 'UserController',
                path: '/users',
                tag: 'users',
                methods: [
                  SwaggerMethod(
                    operationId: 'users_search',
                    httpMethod: 'get',
                    path: 'search',
                    parameters: const [],
                    bodyParam: SwaggerParam(
                      name: 'query',
                      location: ParamLocation.body,
                      type: const SwaggerType(schema: {'type': 'string'}),
                      isRequired: true,
                      wireName: 'q',
                    ),
                    returnType: const SwaggerType(
                      schema: {
                        'type': 'array',
                        'items': {'type': 'string'},
                      },
                    ),
                    defaultStatusCode: 200,
                    isHidden: false,
                    explicitResponses: const [],
                  ),
                ],
              ),
            ],
          ),
          registry,
        );

        final paths = spec['paths'] as Map<String, dynamic>;
        final operation = (paths['/users/search'] as Map)['get'] as Map;
        expect(operation.containsKey('requestBody'), isFalse);
        final parameters = operation['parameters'] as List;
        final qParam =
            parameters.firstWhere((p) => (p as Map)['name'] == 'q') as Map;
        expect(qParam['in'], 'query');
        expect(qParam['required'], isTrue);
      },
    );
  });
}
