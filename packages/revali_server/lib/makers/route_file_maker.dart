import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_annotations/revali_annotations.dart' show DI;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/revali_server.dart';

PartFile routeFileMaker(
  ServerParentRoute route,
  String Function(Spec) format,
) {
  final closure = Method(
    (p) => p
      ..name = route.handlerName
      ..returns = refer('Route')
      ..requiredParameters.addAll([
        Parameter(
          (b) => b
            ..name = route.className.toCamelCase()
            ..type = refer(route.className),
        ),
        Parameter(
          (b) => b
            ..name = 'di'
            ..type = refer('$DI'),
        ),
      ])
      ..body = Block.of([
        refer('Route')
            .newInstance([
              literalString(route.routePath)
            ], {
              ...createRouteArgs(
                route: route,
                returnType: null,
                classVarName: route.classVarName,
                method: null,
              ),
              if (route.routes.isNotEmpty)
                'routes': literalList([
                  for (final child in route.routes)
                    createChildRoute(child, route)
                ])
            })
            .returned
            .statement,
      ]),
  );

  return PartFile(
    path: ['routes', '__${route.fileName}.dart'],
    content: format(closure),
  );
}

Spec createChildRoute(ServerChildRoute route, ServerParentRoute parent) {
  final headers = [
    ...route.annotations.setHeaders,
    ...parent.annotations.setHeaders,
  ];

  Expression? response = refer('context').property('response');
  final ogResponse = response;

  if (route.httpCode?.code case final code?) {
    response = response.cascade('statusCode').assign(literalNum(code));
  }

  for (final setHeader in headers) {
    response = response
        ?.cascade('headers')
        .index(literalString(setHeader.name))
        .assign(literalString(setHeader.value));
  }

  if ('$response' == '$ogResponse') {
    response = null;
  }

  final positioned = [literalString(route.path)];

  final named = {
    ...createRouteArgs(
      route: route,
      returnType: route.returnType,
      classVarName: parent.classVarName,
      method: route.isWebSocket ? null : route.method,
      statusCode: route.httpCode?.code,
      additionalHandlerCode: [
        if (response != null) response.statement,
      ],
    ),
    if (route.ping case final ping? when route.isWebSocket)
      'ping': refer('Duration').newInstance(
        [],
        {'microseconds': literalNum(ping.inMicroseconds)},
      ),
    if (route.redirect case final redirect?)
      'redirect': literal(mimic(redirect)),
  };

  if (route.isWebSocket) {
    return refer('Route').newInstanceNamed('webSocket', positioned, named);
  } else {
    return refer('Route').newInstance(positioned, named);
  }
}

Map<String, Expression> createModifierArgs({
  required ServerRouteAnnotations annotations,
}) {
  final typeReferences = annotations.coreTypeReferences;
  final mimics = annotations.coreMimics;

  return {
    if (mimics.catchers.isNotEmpty || typeReferences.catchers.isNotEmpty)
      'catchers': literalList([
        if (mimics.catchers.isNotEmpty)
          for (final catcher in mimics.catchers) mimic(catcher),
        if (typeReferences.catchers.isNotEmpty)
          for (final catches in typeReferences.catchers)
            for (final catcher in catches.types) createClass(catcher),
      ]),
    if (annotations.data.isNotEmpty)
      'data': literalList([for (final data in annotations.data) mimic(data)]),
    if (mimics.guards.isNotEmpty || typeReferences.guards.isNotEmpty)
      'guards': literalList([
        if (mimics.guards.isNotEmpty)
          for (final guard in mimics.guards) mimic(guard),
        if (typeReferences.guards.isNotEmpty)
          for (final guards in typeReferences.guards)
            for (final guard in guards.types) createClass(guard),
      ]),
    if (mimics.interceptors.isNotEmpty ||
        typeReferences.interceptors.isNotEmpty)
      'interceptors': literalList([
        if (mimics.interceptors.isNotEmpty)
          for (final interceptor in mimics.interceptors) mimic(interceptor),
        if (typeReferences.interceptors.isNotEmpty)
          for (final intercepts in typeReferences.interceptors)
            for (final interceptor in intercepts.types)
              createClass(interceptor),
      ]),
    if (mimics.middlewares.isNotEmpty || typeReferences.middlewares.isNotEmpty)
      'middlewares': literalList([
        if (mimics.middlewares.isNotEmpty)
          for (final middleware in mimics.middlewares) mimic(middleware),
        if (typeReferences.middlewares.isNotEmpty)
          for (final uses in typeReferences.middlewares)
            for (final middleware in uses.types) createClass(middleware),
      ]),
    if (annotations.combine.isNotEmpty)
      'combine': literalList(
        [
          for (final combine in annotations.combine) mimic(combine),
        ],
      ),
    if (annotations.meta.isNotEmpty)
      ...() {
        final m = refer('m');

        return {
          'meta': Method((p) => p
            ..requiredParameters.add(Parameter((b) => b..name = 'm'))
            ..body = Block.of([
              for (final meta in annotations.meta)
                m.cascade('add').call([
                  mimic(meta),
                ]).statement,
            ])).closure
        };
      }(),
  };
}

Map<String, Expression> createRouteArgs({
  required ServerRoute route,
  ServerReturnType? returnType,
  String? classVarName,
  String? method,
  int? statusCode,
  List<Code> additionalHandlerCode = const [],
}) {
  var handler = literalNull;

  if (returnType != null && classVarName != null) {
    final (:positioned, :named) = getParams(route.params);
    handler =
        refer(classVarName).property(route.handlerName).call(positioned, named);

    if (returnType.isFuture) {
      handler = handler.awaited;
    }

    if (!returnType.isVoid) {
      handler = declareFinal('result').assign(handler);
    }
  }

  return {
    ...createModifierArgs(annotations: route.annotations),
    if (method != null) 'method': literalString(method),
    if ('$handler' != '$literalNull')
      'handler': Method(
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
            Code('\n'),
            ...additionalHandlerCode,
            Code('\n'),
            handler.statement,
          ]),
      ).closure,
  };
}

Expression mimic(ServerMimic mimic) => CodeExpression(Code(mimic.instance));

({Iterable<Expression> positioned, Map<String, Expression> named}) getParams(
  Iterable<ServerParam> params,
) {
  final positioned = <Expression>[];
  final named = <String, Expression>{};

  for (final param in params) {
    final arg = createParamArg(param);

    if (param.isNamed) {
      named[param.name] = arg;
    } else {
      positioned.add(arg);
    }
  }
  return (positioned: positioned, named: named);
}

Expression createClass(ServerClass c) {
  final (:positioned, :named) = getParams(c.params);

  final constructor = refer(c.className).newInstance(positioned, named);

  return constructor;
}

Expression createParamArg(
  ServerParam param,
) {
  final annotation = param.annotations;

  if (!annotation.hasAnnotation && !param.hasDefaultValue) {
    throw ArgumentError(
      'No annotation or default value for param ${param.name}',
    );
  }

  if (param.defaultValue case final value? when !annotation.hasAnnotation) {
    return CodeExpression(Code(value));
  }

  if (annotation.dep) {
    return refer('di').property('get').call([]);
  }

  if (annotation.body case final body?) {
    var bodyVar = refer('context').property('request').property('body');

    if (body.access case final access?) {
      bodyVar = bodyVar.property('data?');
      for (final part in access) {
        bodyVar = bodyVar.index(literalString(part));

        final acceptsNull = body.acceptsNull;
        if ((acceptsNull != null && !acceptsNull) ||
            (!param.isNullable && body.pipe == null)) {
          bodyVar = bodyVar
              // TODO(MRGNHNT): Throw custom exception here
              .ifNullThen(literalString('Missing value!').thrown.parenthesized);
        }
      }
    } else {
      bodyVar = bodyVar.property('data');
    }

    if (body.pipe case final pipe?) {
      final pipeClass = createClass(pipe.pipe);

      return pipeClass.property('transform').call([bodyVar]);
    }

    return bodyVar;
  }

  if (annotation.param case final paramAnnotation?) {
    final paramsRef =
        refer('context').property('request').property('pathParameters');

    var paramValue =
        paramsRef.index(literalString(paramAnnotation.name ?? param.name));

    final acceptsNull = paramAnnotation.acceptsNull;
    if ((acceptsNull != null && !acceptsNull) ||
        (!param.isNullable && paramAnnotation.pipe == null)) {
      paramValue = paramValue
          // TODO(MRGNHNT): Throw custom exception here
          .ifNullThen(literalString('Missing value!').thrown.parenthesized);
    }

    if (paramAnnotation.pipe case final pipe?) {
      final pipeClass = createClass(pipe.pipe);

      final context = refer((PipeContextImpl).name).newInstanceNamed(
        'from',
        [
          refer('context'),
        ],
        {
          'arg': paramAnnotation.name == null
              ? literalNull
              : literalString(paramAnnotation.name!),
          'paramName': literalString(paramAnnotation.name ?? param.name),
          'type': refer('${ParamType.param}'),
        },
      );

      return pipeClass.property('transform').call([paramValue, context]);
    }

    return paramValue;
  }

  if (annotation.query case final query?) {
    Expression queryVar;

    if (query.all) {
      queryVar =
          refer('context').property('request').property('queryParametersAll');
    } else {
      queryVar =
          refer('context').property('request').property('queryParameters');
    }

    var queryValue = queryVar.index(literalString(query.name ?? param.name));

    final acceptsNull = query.acceptsNull;
    if ((acceptsNull != null && !acceptsNull) ||
        (!param.isNullable && query.pipe == null)) {
      queryValue = queryValue
          // TODO(MRGNHNT): Throw custom exception here
          .ifNullThen(literalString('Missing value!').thrown.parenthesized);
      ;
    }

    if (query.pipe case final pipe?) {
      final pipeClass = createClass(pipe.pipe);

      final context = refer((PipeContextImpl).name).newInstanceNamed(
        'from',
        [
          refer('context'),
        ],
        {
          'arg': query.name == null ? literalNull : literalString(query.name!),
          'paramName': literalString(query.name ?? param.name),
          'type':
              refer(query.all ? '${ParamType.queryAll}' : '${ParamType.query}'),
        },
      );

      return pipeClass.property('transform').call([queryValue, context]);
    }

    return queryValue;
  }

  if (annotation.customParam case final customParam?) {
    final context = refer((CustomParamContextImpl).name).newInstanceNamed(
      'from',
      [
        refer('context'),
      ],
      {
        'name': literalString(param.name),
        'type': refer(param.type),
      },
    );

    return mimic(customParam).property('parse').call([context]);
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}

extension _TypeX on Type {
  String get name => '$this'.split('<').first;
}
