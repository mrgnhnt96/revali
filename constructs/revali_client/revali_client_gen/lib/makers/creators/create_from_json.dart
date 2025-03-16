// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/models/iterable_type.dart';

// this is all sort of a mess, and it doesn't work
Expression createReturnTypeFromJson(ClientType provided, Expression variable) {
  final type = switch (provided) {
    _
        when (provided.isFuture || provided.isStream) &&
            provided.typeArguments.isNotEmpty =>
      provided.typeArguments.first,
    _ => provided,
  };

  if (type.isIterable) {
    if (type.typeArguments.length != 1) {
      throw Exception('Iterable type must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    Expression callToType(Expression variable) {
      return switch (type.iterableType) {
        IterableType.list => variable.property('toList').call([]),
        IterableType.set => variable.property('toSet').call([]),
        _ => variable,
      };
    }

    if (typeArgument.isPrimitive || typeArgument.isMap) {
      return callToType(variable).property('cast').call([]);
    }

    if (typeArgument.hasFromJsonConstructor) {
      return callToType(
        variable.property('map').call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = refer(typeArgument.name).newInstanceNamed('fromJson', [
                refer((Map).name).newInstanceNamed('from', [
                  refer('e').asA(refer('Map')),
                ]),
              ]).code,
          ).closure,
        ]),
      );
    }

    return createReturnTypeFromJson(typeArgument, variable);
  }

  if (type.isRecord) {
    final props = type.recordProps;
    if (props == null) {
      throw Exception('Record type must have props');
    }

    Expression namedParams() {
      return CodeExpression(
        Block.of([
          for (final prop in props)
            if (prop.name case final String name when prop.isNamed) ...[
              refer(name).code,
              const Code(':'),
              createReturnTypeFromJson(
                prop.type,
                variable.index(literal(name)),
              ).code,
              const Code(','),
            ],
        ]),
      );
    }

    if (props.first.isNamed) {
      // all are named
      return namedParams().parenthesized;
    }

    return CodeExpression(
      Block.of([
        for (final (index, prop) in props.indexed)
          if (prop.isPositioned) ...[
            createReturnTypeFromJson(
              prop.type,
              variable.index(literal(index + 1)),
            ).code,
            const Code(','),
          ],
        namedParams().code,
      ]),
    ).parenthesized;
  }

  if (type.isPrimitive) {
    return variable.asA(refer(type.name));
  }

  if (type.isMap) {
    if (type.typeArguments.length != 2) {
      throw Exception('Map type must have exactly two type arguments');
    }

    final [keyType, valueType] = type.typeArguments;

    return variable.property('map').call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.addAll([
            Parameter((b) => b..name = 'key'),
            Parameter((b) => b..name = 'value'),
          ])
          ..body = refer((MapEntry).name).newInstance([
            createReturnTypeFromJson(keyType, refer('key')),
            createReturnTypeFromJson(valueType, refer('value')),
          ]).code,
      ).closure,
    ]);
  }

  if (type.isDynamic) {
    return variable;
  }

  return refer(type.name).newInstanceNamed(
    'fromJson',
    [
      refer((Map).name).newInstanceNamed('from', [
        variable.asA(refer((Map).name)),
      ]),
    ],
  );
}
