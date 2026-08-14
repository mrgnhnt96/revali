import 'package:revali/server/contract/contract_check.dart';
import 'package:test/test.dart';

Map<String, dynamic> manifest(List<Map<String, dynamic>> routes) => {
  'version': 2,
  'prefix': 'api',
  'routes': routes,
};

Map<String, dynamic> route({
  String method = 'GET',
  String path = '/api/users',
  String returns = 'User',
  bool returnsNullable = false,
  bool sse = false,
  bool webSocket = false,
  List<Map<String, dynamic>> params = const [],
}) => {
  'method': method,
  'path': path,
  'controller': 'UsersController',
  'handler': 'get',
  'sse': sse,
  'webSocket': webSocket,
  'returns': returns,
  'returnsNullable': returnsNullable,
  'params': params,
  'lifecycle': <String>[],
};

Map<String, dynamic> param({
  String name = 'id',
  String type = 'String',
  bool required = true,
  String location = '@query',
  String? binding,
}) => {
  'name': name,
  'type': type,
  'required': required,
  'location': location,
  'binding': binding ?? name,
};

void main() {
  group('checkContract', () {
    test('reports nothing when the manifests match', () {
      final report = checkContract(manifest([route()]), manifest([route()]));

      expect(report.changes, isEmpty);
      expect(report.hasBreaking, isFalse);
    });

    test('a removed route is breaking', () {
      final report = checkContract(manifest([route()]), manifest([]));

      expect(report.hasBreaking, isTrue);
      expect(report.breaking.single.description, 'route removed');
    });

    test('an added route is compatible', () {
      final report = checkContract(
        manifest([route()]),
        manifest([route(), route(path: '/api/teams')]),
      );

      // Nothing the consumer already calls is affected.
      expect(report.hasBreaking, isFalse);
      expect(report.compatible.single.description, 'route added');
    });

    test('changing the method is seen as removal', () {
      final report = checkContract(
        manifest([route()]),
        manifest([route(method: 'POST')]),
      );

      expect(report.hasBreaking, isTrue);
      expect(report.breaking.single.description, 'route removed');
    });

    test('a changed return type is breaking', () {
      final report = checkContract(
        manifest([route()]),
        manifest([route(returns: 'UserDto')]),
      );

      expect(report.breaking.single.description, 'returns User, now UserDto');
    });

    test('a newly nullable return is breaking', () {
      final report = checkContract(
        manifest([route()]),
        manifest([route(returnsNullable: true)]),
      );

      // The consumer may be dereferencing it without a null check.
      expect(
        report.breaking.single.description,
        'return value is now nullable',
      );
    });

    test('a return that stops being nullable is compatible', () {
      final report = checkContract(
        manifest([route(returnsNullable: true)]),
        manifest([route()]),
      );

      expect(report.hasBreaking, isFalse);
    });

    test('switching transport is breaking', () {
      final report = checkContract(
        manifest([route()]),
        manifest([route(sse: true)]),
      );

      expect(
        report.breaking.single.description,
        'transport changed (sse/webSocket)',
      );
    });

    group('parameters', () {
      test('a new required parameter is breaking', () {
        final report = checkContract(
          manifest([route()]),
          manifest([
            route(params: [param(name: 'page')]),
          ]),
        );

        // It rejects every call the consumer already makes.
        expect(
          report.breaking.single.description,
          "new required parameter 'page'",
        );
      });

      test('a new optional parameter is compatible', () {
        final report = checkContract(
          manifest([route()]),
          manifest([
            route(params: [param(name: 'page', required: false)]),
          ]),
        );

        expect(report.hasBreaking, isFalse);
      });

      test('making an existing parameter required is breaking', () {
        final report = checkContract(
          manifest([
            route(params: [param(required: false)]),
          ]),
          manifest([
            route(params: [param()]),
          ]),
        );

        expect(
          report.breaking.single.description,
          "parameter 'id' is now required",
        );
      });

      test('relaxing a parameter to optional is compatible', () {
        final report = checkContract(
          manifest([
            route(params: [param()]),
          ]),
          manifest([
            route(params: [param(required: false)]),
          ]),
        );

        expect(report.hasBreaking, isFalse);
      });

      test('a changed parameter type is breaking', () {
        final report = checkContract(
          manifest([
            route(params: [param()]),
          ]),
          manifest([
            route(params: [param(type: 'int')]),
          ]),
        );

        expect(
          report.breaking.single.description,
          "parameter 'id' was String, now int",
        );
      });

      test('moving a parameter between query and body is breaking', () {
        final report = checkContract(
          manifest([
            route(params: [param()]),
          ]),
          manifest([
            route(params: [param(location: '@body')]),
          ]),
        );

        expect(
          report.breaking.single.description,
          "parameter 'id' moved from @query to @body",
        );
      });

      test('a removed parameter is reported but not breaking', () {
        final report = checkContract(
          manifest([
            route(params: [param()]),
          ]),
          manifest([route()]),
        );

        // The server still accepts a caller that sends it; the value is just
        // ignored now.
        expect(report.hasBreaking, isFalse);
        expect(report.compatible.single.description, contains('now ignored'));
      });

      test('renaming the Dart argument alone changes nothing', () {
        final report = checkContract(
          manifest([
            route(params: [param(binding: 'id')]),
          ]),
          manifest([
            route(
              params: [param(name: 'userId', binding: 'id')],
            ),
          ]),
        );

        // Callers depend on the wire name, not the Dart parameter name.
        expect(report.changes, isEmpty);
      });
    });

    group('manifest version', () {
      test('says so rather than silently skipping return comparison', () {
        final old = manifest([route()])..['version'] = 1;

        final report = checkContract(old, manifest([route()]));

        // Absent must not read as unchanged, or the check reports clean for a
        // comparison it never made.
        expect(
          report.compatible.single.description,
          contains('return types not compared'),
        );
      });

      test('does not compare returns across a version 1 pin', () {
        final old = manifest([route()])..['version'] = 1;

        final report = checkContract(old, manifest([route(returns: 'Other')]));

        expect(report.hasBreaking, isFalse);
      });
    });
  });
}
