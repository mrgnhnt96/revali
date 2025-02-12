import 'package:server_client_gen/enums/parameter_position.dart';
import 'package:server_client_gen/makers/utils/client_param_extensions.dart';
import 'package:server_client_gen/models/client_imports.dart';
import 'package:server_client_gen/models/client_param.dart';
import 'package:server_client_gen/models/client_type.dart';
import 'package:test/test.dart';

void main() {
  group('IterableClientParamX', () {
    ClientParam param({
      ParameterPosition position = ParameterPosition.body,
      List<String> access = const [],
    }) {
      return ClientParam(
        name: 'name',
        position: position,
        type: ClientType(
          name: 'name',
          import: ClientImports([]),
        ),
        nullable: false,
        access: access,
        acceptList: false,
      );
    }

    group('#roots', () {
      test('should return an empty array when any access is empty', () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data']),
          param(access: []),
        ].roots();

        expect(result, isEmpty);
      });

      test('should return lowest access', () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data']),
        ].roots();

        expect(result, hasLength(1));
        expect(result.single, ['data']);
      });

      test('should return all lowest access', () {
        final result = [
          param(access: ['meta']),
          param(access: ['meta', 'bananas']),
          param(access: ['data', 'email']),
          param(access: ['data']),
        ].roots();

        expect(result, hasLength(2));
        expect(result[0], ['meta']);
        expect(result[1], ['data']);
      });

      test('should return all lowest access', () {
        final result = [
          param(access: ['meta', 'bananas']),
          param(access: ['data', 'email']),
        ].roots();

        expect(result, hasLength(2));
        expect(result[0], ['meta', 'bananas']);
        expect(result[1], ['data', 'email']);
      });
    });

    group('#needsAssignment', () {
      test('should return false when root exists', () {
        final result = [
          param(access: ['data']),
        ].needsAssignment(param(access: ['data', 'email']));

        expect(result, isFalse);
      });

      test('should return true when root is the same', () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data', 'name']),
        ].needsAssignment(param(access: ['data', 'email']));

        expect(result, true);
      });

      test('should return false when root is empty', () {
        final result = [
          param(access: []),
        ].needsAssignment(param(access: ['data', 'email']));

        expect(result, isFalse);
      });

      test('should return true when root is empty and access is empty', () {
        final result = [
          param(access: []),
        ].needsAssignment(param(access: []));

        expect(result, isTrue);
      });

      test('should return false when root does not exist', () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data', 'name']),
        ].needsAssignment(param(access: ['meta']));

        expect(result, isFalse);
      });
    });
  });
}
