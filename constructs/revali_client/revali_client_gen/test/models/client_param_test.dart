import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:test/test.dart';

void main() {
  group('ClientParam', () {
    ClientParam param({
      required String name,
      required ParameterPosition position,
      required String type,
      List<String> access = const [],
    }) {
      return ClientParam(
        name: name,
        position: position,
        type: ClientType(name: type),
        access: access,
        acceptMultiple: false,
        hasDefaultValue: false,
      );
    }

    group('#matchesBinding', () {
      test('returns true for same position, access, and type', () {
        final lifecycle = param(
          name: 'body',
          position: ParameterPosition.body,
          type: 'UserBody',
        );
        final endpoint = param(
          name: 'request',
          position: ParameterPosition.body,
          type: 'UserBody',
        );

        expect(lifecycle.matchesBinding(endpoint), isTrue);
      });

      test('returns false when types differ', () {
        final lifecycle = param(
          name: 'body',
          position: ParameterPosition.body,
          type: 'OrderBody',
        );
        final endpoint = param(
          name: 'request',
          position: ParameterPosition.body,
          type: 'UserBody',
        );

        expect(lifecycle.matchesBinding(endpoint), isFalse);
      });

      test('returns false when access paths differ', () {
        final lifecycle = param(
          name: 'email',
          position: ParameterPosition.body,
          type: 'String',
          access: ['data'],
        );
        final endpoint = param(
          name: 'email',
          position: ParameterPosition.body,
          type: 'String',
        );

        expect(lifecycle.matchesBinding(endpoint), isFalse);
      });
    });
  });
}
