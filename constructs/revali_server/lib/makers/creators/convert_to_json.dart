// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/should_nest_json_in_data.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression? convertToJson(ServerType type, Expression result) {
  if (type.isStream) {
    if (type.typeArguments.length != 1) {
      throw Exception('Unsupported stream type: $type');
    }

    final typeArg = type.typeArguments.first;

    final toJson = convertToJson(typeArg, refer('e'));

    final shouldNest = shouldNestJsonInData(typeArg);

    if (toJson == null && !shouldNest) {
      return null;
    }

    return result.property('map').call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p.name = 'e'))
          ..body = switch ((shouldNest, toJson)) {
            (false, final json?) => json.code,
            (true, _) => literalMap({'data': toJson?.code ?? refer('e')}).code,
            (false, null) => throw Exception('Expected toJson to be non-null'),
          },
      ).closure,
    ]);
  }

  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Unsupported future type: $type');
    }

    return convertToJson(type.typeArguments.first, result);
  }

  if (type.iterableType case final IterableType iterableType) {
    if (type.typeArguments.length != 1) {
      throw Exception('Unsupported iterable type: ${type.iterableType}');
    }

    final typeArg = type.typeArguments.first;

    final toJson = convertToJson(typeArg, refer('e'));

    if (toJson == null) {
      return switch (iterableType) {
        IterableType.set => result.property('toList').call([]),
        IterableType.iterable => result.property('toList').call([]),
        IterableType.list => null,
      };
    }

    final iterates = Method(
      (p) => p
        ..requiredParameters.add(Parameter((b) => b..name = 'e'))
        ..lambda = true
        ..body = toJson.code,
    ).closure;

    return switch (type.isNullable) {
      true => result.nullSafeProperty('map'),
      false => result.property('map'),
    }
        .call([iterates])
        .property('toList')
        .call([]);
  }

  if (type.isMap) {
    if (type.typeArguments.length != 2) {
      throw Exception('Unsupported map type');
    }

    final [keyType, valueType] = type.typeArguments;

    if (!(keyType.hasToJsonMember || valueType.hasToJsonMember)) {
      return null;
    }

    final keyMethodBody = convertToJson(keyType, refer('key'));
    final valueMethodBody = convertToJson(valueType, refer('value'));

    if (keyMethodBody == null && valueMethodBody == null) {
      return null;
    }

    final iterates = Method(
      (p) => p
        ..requiredParameters.addAll(
          [
            Parameter((b) => b.name = 'key'),
            Parameter((b) => b.name = 'value'),
          ],
        )
        ..lambda = true
        ..body = refer((MapEntry).name).call([
          keyMethodBody ?? refer('key'),
          valueMethodBody ?? refer('value'),
        ]).code,
    ).closure;

    return result.property('map').call([iterates]);
  }

  if (type.recordProps case final props?
      when type.isRecord && props.isNotEmpty) {
    Expression extract(ServerRecordProp prop, String access) {
      var extract = result.property(access);
      if (prop.type.hasToJsonMember) {
        if (prop.type.isNullable) {
          extract = extract.nullSafeProperty('toJson').call([]);
        } else {
          extract = extract.property('toJson').call([]);
        }
      }

      return extract;
    }

    Expression namedProps() {
      final named = props.where((e) => e.isNamed).toList();

      if (named.isEmpty) {
        return const CodeExpression(Code(''));
      }

      return CodeExpression(
        Block.of([
          const Code('{'),
          for (final prop in named)
            if (prop.name case final String name when prop.isNamed) ...[
              literal(name).code,
              const Code(':'),
              extract(prop, name).code,
              const Code(','),
            ],
          const Code('}'),
        ]),
      );
    }

    if (props.first.isNamed) {
      // all props are named
      return namedProps();
    } else {
      Iterable<Expression> positionedProps() sync* {
        for (final (index, prop) in props.indexed) {
          if (prop.isNamed) continue;

          yield extract(prop, r'$' '${index + 1}');
        }
      }

      return CodeExpression(
        Block.of([
          const Code('['),
          for (final value in positionedProps()) ...[
            value.code,
            const Code(','),
          ],
          namedProps().code,
          const Code(']'),
        ]),
      );
    }
  }

  if (type.hasToJsonMember) {
    if (type.isNullable) {
      return result.nullSafeProperty('toJson').call([]);
    } else {
      return result.property('toJson').call([]);
    }
  }

  if (type.isStringContent) {
    return result.property('value');
  }

  return null;
}
