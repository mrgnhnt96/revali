import 'package:collection/collection.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:test/test.dart';

void main() {
  group('IterableClientParamX', () {
    ClientParam param({
      ParameterPosition position = ParameterPosition.body,
      List<String> access = const [],
      String? type,
    }) {
      return ClientParam(
        name: 'name',
        position: position,
        type: ClientType(
          name: type ?? 'FakeType',
          import: ClientImports([]),
          isVoid: false,
          isStream: false,
          isFuture: false,
          isStringContent: false,
          isPrimitive: false,
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
        access: access,
        acceptMultiple: false,
      );
    }

    group('#roots', () {
      const deepEquals = DeepCollectionEquality();

      test('should return an empty array when any access is empty', () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data']),
          param(access: []),
        ].roots();

        expect(result, isEmpty);
      });

      test('should throw when paths are the same and types differ', () {
        final result = [
          param(access: ['data']),
          param(access: ['data'], type: 'String'),
        ].roots;

        expect(result, throwsException);
      });

      test('should throw when paths are empty and types differ', () {
        final result = [
          param(access: []),
          param(access: [], type: 'String'),
        ].roots;

        expect(result, throwsException);
      });

      test('should return lowest access', () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data']),
        ].roots();

        final expected = RecursiveMap({
          'data': RecursiveMap(),
        });

        expect(deepEquals.equals(result, expected), isTrue);
      });

      test('should return all lowest access', () {
        final result = [
          param(access: ['meta']),
          param(access: ['meta', 'bananas']),
          param(access: ['data', 'email']),
          param(access: ['data']),
        ].roots();

        final expected = RecursiveMap({
          'meta': RecursiveMap(),
          'data': RecursiveMap(),
        });

        expect(deepEquals.equals(result, expected), isTrue);
      });

      test('should return all access with same roots when last is different',
          () {
        final result = [
          param(access: ['data', 'email']),
          param(access: ['data', 'password']),
        ].roots();

        final expected = RecursiveMap({
          'data': RecursiveMap({
            'email': RecursiveMap(),
            'password': RecursiveMap(),
          }),
        });

        expect(deepEquals.equals(result, expected), isTrue);
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

        expect(result, isTrue);
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
