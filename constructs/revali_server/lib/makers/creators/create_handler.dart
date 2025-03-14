// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/create_web_socket_handler.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/create_map.dart';

Expression? createHandler({
  required ServerRoute route,
  required ServerType? returnType,
  required String? classVarName,
  required MetaWebSocketMethod? webSocket,
  List<Code> additionalHandlerCode = const [],
}) {
  if (returnType == null || classVarName == null) {
    return null;
  }

  if (webSocket != null) {
    return createWebSocketHandler(
      webSocket,
      route: route,
      returnType: returnType,
      classVarName: classVarName,
    );
  }

  var handler = literalNull;

  final (:positioned, :named) = getParams(route.params);
  handler =
      refer(classVarName).property(route.handlerName).call(positioned, named);

  if (returnType.isFuture) {
    handler = handler.awaited;
  }

  if (!returnType.isVoid) {
    handler = declareFinal('result').assign(handler);
  }

  Expression? setBody;
  if (!returnType.isVoid) {
    Expression result = refer('result');

    final type = switch (returnType) {
      ServerType(typeArguments: [final type], :final isFuture) when isFuture =>
        type,
      _ => returnType,
    };

    if (type.iterableType != null) {
      if (type.typeArguments.length != 1) {
        throw Exception('Unsupported iterable type: ${type.iterableType}');
      }

      final typeArg = type.typeArguments.first;

      if (typeArg.hasToJsonMember) {
        final iterates = Method(
          (p) => p
            ..requiredParameters.add(Parameter((b) => b..name = 'e'))
            ..lambda = true
            ..body = switch ((typeArg.hasToJsonMember, typeArg.isNullable)) {
              (true, true) => refer('e').nullSafeProperty('toJson').call([]),
              (true, false) => refer('e').property('toJson').call([]),
              (_, _) => refer('e'),
            }
                .code,
        ).closure;

        if (type.isNullable) {
          result = result.nullSafeProperty('map');
        } else {
          result = result.property('map');
        }

        result = result.call([iterates]).property('toList').call([]);
      }
    } else if (type.isMap) {
      if (type.typeArguments.length != 2) {
        throw Exception('Unsupported map type');
      }

      final [keyType, valueType] = type.typeArguments;

      if (keyType.hasToJsonMember || valueType.hasToJsonMember) {
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
              switch ((keyType.hasToJsonMember, keyType.isNullable)) {
                (true, true) =>
                  refer('key').nullSafeProperty('toJson').call([]),
                (true, false) => refer('key').property('toJson').call([]),
                _ => refer('key'),
              },
              switch ((valueType.hasToJsonMember, valueType.isNullable)) {
                (true, true) =>
                  refer('value').nullSafeProperty('toJson').call([]),
                (true, false) => refer('value').property('toJson').call([]),
                (_, _) => refer('value'),
              },
            ]).code,
        ).closure;

        result = result.property('map').call([iterates]);
      }
    } else if (type.recordProps case final props?
        when type.isRecord && props.isNotEmpty) {
      Expression extract(ServerRecordProp prop, String access) {
        var extract = refer('result').property(access);
        if (prop.type.hasToJsonMember) {
          if (prop.type.isNullable) {
            extract = extract.nullSafeProperty('toJson').call([]);
          } else {
            extract = extract.property('toJson').call([]);
          }
        }

        return extract;
      }

      Iterable<(String, Expression)> namedProps() sync* {
        for (final prop in props) {
          if (!prop.isNamed) continue;

          final name = prop.name;
          if (name == null) {
            throw Exception('Named record prop has no name: $prop');
          }

          yield (name, extract(prop, name));
        }
      }

      if (props.first.isNamed) {
        // all props are named
        result = createMap(
          {
            for (final (key, value) in namedProps()) key: value,
          },
        );
      } else {
        Iterable<Expression> positionedProps() sync* {
          for (final (index, prop) in props.indexed) {
            if (prop.isNamed) continue;

            yield extract(prop, r'$' '${index + 1}');
          }
        }

        result = CodeExpression(
          Block.of([
            const Code('['),
            for (final value in positionedProps()) ...[
              value.code,
              const Code(','),
            ],
            if (namedProps() case final props when props.isNotEmpty)
              createMap(
                {
                  for (final (key, value) in namedProps()) key: value,
                },
              ).code,
            const Code(']'),
          ]),
        );
      }
    } else if (type.hasToJsonMember) {
      if (type.isNullable) {
        result = result.nullSafeProperty('toJson').call([]);
      } else {
        result = result.property('toJson').call([]);
      }
    }

    setBody = refer('context').property('response').property('body');

    if (type.isPrimitive ||
        type.isMap ||
        type.hasToJsonMember ||
        type.isRecord ||
        (type.iterableType != null &&
            type.typeArguments.every((e) => e.hasToJsonMember))) {
      setBody = setBody.index(literalString('data')).assign(result);
    } else if (type.isStringContent) {
      result = result.property('value');
      setBody = setBody.assign(result);
    } else {
      setBody = setBody.assign(result);
    }
  }

  return Method(
    (p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..modifier = MethodModifier.async
      ..body = Block.of([
        if (route.params.any((e) => e.annotations.body != null))
          refer('context')
              .property('request')
              .property('resolvePayload')
              .call([])
              .awaited
              .statement,
        const Code('\n'),
        ...additionalHandlerCode,
        const Code('\n'),
        handler.statement,
        if (setBody != null) ...[
          const Code('\n'),
          setBody.statement,
        ],
      ]),
  ).closure;
}
