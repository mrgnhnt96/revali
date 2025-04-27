// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/create_switch_pattern.dart';
import 'package:revali_client_gen/makers/utils/safe_property.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_from_json.dart';
import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/models/iterable_type.dart';

Expression? createReturnTypeFromJson(ClientType type, Expression variable) {
  if (type.isStream) {
    if (type.typeArguments.length != 1) {
      throw Exception('Stream type must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return createReturnTypeFromJson(typeArgument, variable);
  }

  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Future type must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return createReturnTypeFromJson(typeArgument, variable);
  }

  if (type.isBytes) {
    return null;
  }

  if (type.isIterable) {
    if (type.typeArguments.length != 1) {
      throw Exception('Iterable type must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    Expression callToType(Expression variable, {bool includeList = true}) {
      return switch (type.iterableType) {
        IterableType.list when includeList =>
          variable.safeProperty(type, 'toList').call([]),
        IterableType.set => variable.safeProperty(type, 'toSet').call([]),
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
          .safeProperty(type, 'cast<${typeArgument.name}>')
          .call([]),
      final e => callToType(
          variable.safeProperty(type, 'map').call([
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
      var access = variable;
      if (props.indexWhere((e) => e.isNamed) case final index when index > 0) {
        access = variable.safeIndex(type, literal(index));
      }

      Iterable<Code> params(ClientRecordProp prop) sync* {
        if (prop.isPositioned) return;
        final name = prop.name;
        if (name == null) return;

        yield refer(name).code;
        yield const Code(':');

        final variableAccess = access.safeIndex(type, literal(name));
        if (createReturnTypeFromJson(prop.type, variableAccess)
            case final fromJson?) {
          yield fromJson.code;
        } else {
          yield variableAccess.asA(refer(prop.type.name)).code;
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
      return switch (type.isNullable) {
        true => createSwitchPattern(variable, {
            literalNull: literalNull,
            const Code('_'): namedParams().parenthesized,
          }),
        false => namedParams().parenthesized,
      };
    }

    Iterable<Code> positionalParams(int index, ClientRecordProp prop) sync* {
      if (prop.isNamed) return;

      final access = variable.safeIndex(type, literal(index));

      if (createReturnTypeFromJson(prop.type, access) case final fromJson?) {
        yield fromJson.code;
      } else {
        yield access.asA(refer(prop.type.name)).code;
      }

      yield const Code(',');
    }

    final record = CodeExpression(
      Block.of([
        for (final (index, prop) in props.indexed)
          ...positionalParams(index, prop),
        namedParams().code,
      ]),
    ).parenthesized;

    return switch (type.isNullable) {
      true => createSwitchPattern(variable, {
          literalNull: literalNull,
          const Code('_'): record,
        }),
      false => record,
    };
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

    return variable.safeProperty(type, 'map').call([
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

  if (type.fromJson case final fromJson?) {
    return refer(type.nonNullName).newInstanceNamed(
      'fromJson',
      [
        if (fromJson case ClientFromJson(params: [ClientType(isMap: true)]))
          refer((Map).name).newInstanceNamed('from', [
            variable.asA(refer((Map).name)),
          ])
        else if (fromJson case ClientFromJson(params: [final type]))
          variable.asA(refer(type.name))
        else
          variable,
      ],
    );
  }

  if (type.isEnum) {
    return refer(type.name)
        .property('values')
        .property('byName')
        .call([variable]);
  }

  return null;
}
