import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_from_json.dart';
import 'package:revali/server/converters/server_to_json.dart';
import 'package:revali/server/converters/server_type.dart';
import 'package:revali/server/makers/creators/convert_to_json.dart';
import 'package:revali/server/makers/creators/create_from_json.dart';
import 'package:test/test.dart';

void main() {
  final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

  // Mirrors `json_serializable`'s `genericArgumentFactories: true` shape:
  //   factory ApiResponse.fromJson(
  //     Map<String, dynamic> json, T Function(Object?) fromJsonT)
  //   Map<String, dynamic> toJson(Object? Function(T value) toJsonT)
  ServerType apiResponseOf(ServerType typeArgument) {
    return ServerType(
      name: 'ApiResponse<${typeArgument.name}>',
      typeArguments: [typeArgument],
      hasToJsonMember: true,
      fromJson: ServerFromJson(
        params: [
          ServerType(name: 'Map<String, dynamic>', isMap: true),
          ServerType(name: 'Object? Function(Object?)'),
        ],
      ),
      toJson: ServerToJson(
        returnType: ServerType(name: 'Map<String, dynamic>', isMap: true),
        paramCount: 1,
      ),
    );
  }

  final userBodyType = ServerType(
    name: 'UserBody',
    hasToJsonMember: true,
    fromJson: ServerFromJson(
      params: [ServerType(name: 'Map<String, dynamic>', isMap: true)],
    ),
  );

  final intType = ServerType(name: 'int', isPrimitive: true);

  group('createFromJson with generic-argument-factories fromJson', () {
    test('recurses into a nested type with its own fromJson', () {
      final code = createFromJson(
        apiResponseOf(userBodyType),
        refer('json'),
      )!.accept(emitter).toString();

      expect(
        code,
        'ApiResponse<UserBody>.fromJson('
        'Map.from((json as Map)), '
        '(e) => UserBody.fromJson(Map.from((e as Map))), '
        ')',
      );
    });

    test('falls back to a cast for a type argument with no fromJson', () {
      final code = createFromJson(
        apiResponseOf(intType),
        refer('json'),
      )!.accept(emitter).toString();

      expect(
        code,
        'ApiResponse<int>.fromJson('
        'Map.from((json as Map)), (e) => (e as int), '
        ')',
      );
    });

    test('non-generic fromJson is unaffected (still single-arg call)', () {
      final code = createFromJson(
        userBodyType,
        refer('json'),
      )!.accept(emitter).toString();

      expect(code, 'UserBody.fromJson(Map.from((json as Map)))');
    });
  });

  group('convertToJson with generic-argument-factories toJson', () {
    test('recurses into a nested type with its own toJson', () {
      final code = convertToJson(
        apiResponseOf(userBodyType),
        refer('result'),
      )!.accept(emitter).toString();

      expect(code, 'result.toJson((v) => v.toJson())');
    });

    test('falls back to the raw value for a type argument with no toJson', () {
      final code = convertToJson(
        apiResponseOf(intType),
        refer('result'),
      )!.accept(emitter).toString();

      expect(code, 'result.toJson((v) => v)');
    });

    test('non-generic toJson is unaffected (still zero-arg call)', () {
      final code = convertToJson(
        userBodyType,
        refer('result'),
      )!.accept(emitter).toString();

      expect(code, 'result.toJson()');
    });
  });
}
