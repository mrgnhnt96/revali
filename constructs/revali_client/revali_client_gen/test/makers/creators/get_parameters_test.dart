import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/creators/get_parameters.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:test/test.dart';

void main() {
  group('getParameters', () {
    ClientParam bodyParam({List<String> access = const []}) {
      return ClientParam(
        name: 'body',
        position: ParameterPosition.body,
        type: ClientType(name: 'GetBody'),
        access: access,
        acceptMultiple: false,
        hasDefaultValue: false,
      );
    }

    ClientMethod method() {
      return ClientMethod(
        name: 'get',
        parentPath: '',
        method: 'GET',
        path: '',
        returnType: ClientType(name: 'Map<String, Object?>'),
        parameters: const [],
        lifecycleComponents: const [],
        isSse: false,
        websocketType: WebsocketType.none,
        isExcluded: false,
      );
    }

    test('dedupes duplicate body params with the same signature name', () {
      final params = getParameters([
        bodyParam(),
        bodyParam(access: ['data']),
      ], method()).toList();

      expect(params.where((param) => param.name == 'body').length, 1);
      expect(params.single, isA<Parameter>());
    });
  });
}
