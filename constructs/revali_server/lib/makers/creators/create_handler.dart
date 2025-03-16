// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/create_web_socket_handler.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

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

  Expression? setBody;
  if (!returnType.isVoid) {
    handler = declareFinal('result').assign(handler);

    setBody = refer('context')
        .property('response')
        .property('body')
        .index(literalString('data'))
        .assign(createJsonSafe(returnType, refer('result')) ?? refer('result'));
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

Expression? createJsonSafe(ServerType type, Expression result) {
  if (type.isStream) {
    if (type.typeArguments.length != 1) {
      throw Exception('Unsupported stream type: $type');
    }

    final typeArg = type.typeArguments.first;

    final methodBody = createJsonSafe(typeArg, refer('e'));

    if (methodBody == null) {
      return null;
    }

    return result.property('map').call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.add(Parameter((p) => p.name = 'e'))
          ..body = methodBody.code,
      ).closure,
    ]);
  }

  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Unsupported future type: $type');
    }

    return createJsonSafe(type.typeArguments.first, result);
  }

  if (type.isIterable) {
    if (type.typeArguments.length != 1) {
      throw Exception('Unsupported iterable type: ${type.iterableType}');
    }

    final typeArg = type.typeArguments.first;

    final methodBody = createJsonSafe(typeArg, refer('e'));

    if (methodBody == null) {
      return null;
    }

    final iterates = Method(
      (p) => p
        ..requiredParameters.add(Parameter((b) => b..name = 'e'))
        ..lambda = true
        ..body = methodBody.code,
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

    final keyMethodBody = createJsonSafe(keyType, refer('key'));
    final valueMethodBody = createJsonSafe(valueType, refer('value'));

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

  return null;
}
