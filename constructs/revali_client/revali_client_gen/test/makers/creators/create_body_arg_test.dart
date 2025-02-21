import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/creators/create_body_arg.dart';
import 'package:revali_client_gen/makers/utils/create_map.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:test/test.dart';

void main() {
  group('createBodyArg', () {
    ClientParam param({
      ParameterPosition position = ParameterPosition.body,
      List<String> access = const [],
      String? name,
    }) {
      return ClientParam(
        name: name ?? 'FakeName',
        position: position,
        type: ClientType(
          name: 'FakeType',
          import: ClientImports([]),
        ),
        nullable: false,
        access: access,
        acceptList: false,
      );
    }

    test('creates a json object with both props', () {
      final result = createBodyArg([
        param(
          access: ['data', 'email'],
          name: 'email',
        ),
        param(
          access: ['data', 'password'],
          name: 'password',
        ),
      ]);

      final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

      final expected = createMap({
        'data': createMap({
          'email': refer('email'),
          'password': refer('password'),
        }),
      });

      expect(
        result.accept(emitter).toString(),
        expected.accept(emitter).toString(),
      );
    });
  });
}
