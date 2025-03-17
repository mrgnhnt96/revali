// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/models/iterable_type.dart';

// this is all sort of a mess, and it doesn't work
Expression? createReturnTypeFromJson(ClientType provided, Expression variable) {
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

    Expression callToType(Expression variable, {bool includeList = true}) {
      return switch (type.iterableType) {
        IterableType.list when includeList =>
          variable.property('toList').call([]),
        IterableType.set => variable.property('toSet').call([]),
        _ => variable,
      };
    }

    final reference = switch (typeArgument) {
      ClientType(isMap: true) => refer('e').asA(refer((Map).name)),
      ClientType(isIterable: true) => refer('e').asA(refer((List).name)),
      _ => refer('e')
    };

    return switch (createReturnTypeFromJson(typeArgument, reference)) {
      null => callToType(variable, includeList: false)
          .property('cast<${typeArgument.name}>')
          .call([]),
      final e => callToType(
          variable.property('map').call([
            Method(
              (b) => b
                ..lambda = true
                ..requiredParameters.add(Parameter((b) => b..name = 'e'))
                ..body = e.code,
            ).closure,
          ]),
        ),
    };
  }

  if (type.isRecord) {
    final props = type.recordProps;
    if (props == null) {
      throw Exception('Record type must have props');
    }

    Expression namedParams() {
      Iterable<Code> params(ClientRecordProp prop) sync* {
        if (prop.isPositioned) return;
        final name = prop.name;
        if (name == null) return;

        yield refer(name).code;
        yield const Code(':');

        final access = variable.index(literal(name));
        if (createReturnTypeFromJson(prop.type, access) case final fromJson?) {
          yield fromJson.code;
        } else {
          yield access.asA(refer(prop.type.name)).code;
        }
        yield const Code(',');
      }

      return CodeExpression(
        Block.of([
          for (final prop in props) ...params(prop),
        ]),
      );
    }

    if (props.first.isNamed) {
      // all are named
      return namedParams().parenthesized;
    }

    Iterable<Code> positionalParams(int index, ClientRecordProp prop) sync* {
      if (prop.isNamed) return;

      final access = variable.index(literal(index + 1));

      if (createReturnTypeFromJson(prop.type, access) case final fromJson?) {
        yield fromJson.code;
      } else {
        yield variable.asA(refer(prop.type.name)).code;
      }

      yield const Code(',');
    }

    return CodeExpression(
      Block.of([
        for (final (index, prop) in props.indexed)
          ...positionalParams(index, prop),
        namedParams().code,
      ]),
    ).parenthesized;
  }

  if (type.isMap) {
    if (type.typeArguments.length != 2) {
      throw Exception('Map type must have exactly two type arguments');
    }

    final [keyType, valueType] = type.typeArguments;

    final keyJson = switch (keyType) {
      ClientType(isPrimitive: true) => refer('key').asA(refer(keyType.name)),
      _ => createReturnTypeFromJson(keyType, refer('key')),
    };

    final valueJson = switch (valueType) {
      ClientType(isPrimitive: true) =>
        refer('value').asA(refer(valueType.name)),
      _ => createReturnTypeFromJson(valueType, refer('value')),
    };

    if (keyJson == null && valueJson == null) {
      return null;
    }

    return variable.property('map').call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.addAll([
            Parameter((b) => b..name = 'key'),
            Parameter((b) => b..name = 'value'),
          ])
          ..body = refer((MapEntry).name).newInstance(
            [keyJson ?? refer('key'), valueJson ?? refer('value')],
          ).code,
      ).closure,
    ]);
  }

  if (type.hasFromJsonConstructor) {
    return refer(type.name).newInstanceNamed(
      'fromJson',
      [
        refer((Map).name).newInstanceNamed('from', [
          variable.asA(refer((Map).name)),
        ]),
      ],
    );
  }

  return null;
}
