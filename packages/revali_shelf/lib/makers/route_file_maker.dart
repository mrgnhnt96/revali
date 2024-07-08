import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_child_route.dart';
import 'package:revali_shelf/converters/shelf_class.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_parent_route.dart';
import 'package:revali_shelf/converters/shelf_return_type.dart';
import 'package:revali_shelf/converters/shelf_route.dart';

PartFile routeFileMaker(
  ShelfParentRoute route,
  String Function(Spec) format,
) {
  final closure = Method(
    (p) => p
      ..name = route.handlerName
      ..returns = refer('Route')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = route.className.toCamelCase()
            ..type = refer(route.className),
        ),
      )
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

Spec createChildRoute(ShelfChildRoute route, ShelfParentRoute parent) {
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
    response = response?.cascade('setHeader').call([
      literalString(setHeader.name),
      literalString(setHeader.value),
    ]);
  }

  if ('$response' == '$ogResponse') {
    response = null;
  }

  return refer('Route').newInstance([
    literalString(route.path)
  ], {
    ...createRouteArgs(
      route: route,
      returnType: route.returnType,
      classVarName: parent.classVarName,
      method: route.method,
      statusCode: route.httpCode?.code,
      additionalHandlerCode: [
        if (response != null) response.statement,
      ],
    ),
    if (route.redirect case final redirect?)
      'redirect': literal(mimic(redirect)),
  });
}

Map<String, Expression> createRouteArgs({
  required ShelfRoute route,
  ShelfReturnType? returnType,
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
    if (route.annotations.catchers.isNotEmpty ||
        route.annotations.catches.isNotEmpty)
      'catchers': literalList([
        if (route.annotations.catchers.isNotEmpty)
          for (final catcher in route.annotations.catchers) mimic(catcher),
        if (route.annotations.catches.isNotEmpty)
          for (final catches in route.annotations.catches)
            for (final catcher in catches.types) createClass(catcher),
      ]),
    if (route.annotations.data.isNotEmpty)
      'data': literalConstList(
          [for (final data in route.annotations.data) mimic(data)]),
    if (route.annotations.guardsMimic.isNotEmpty ||
        route.annotations.guards.isNotEmpty)
      'guards': literalList([
        if (route.annotations.guardsMimic.isNotEmpty)
          for (final guard in route.annotations.guardsMimic) mimic(guard),
        if (route.annotations.guards.isNotEmpty)
          for (final guards in route.annotations.guards)
            for (final guard in guards.types) createClass(guard),
      ]),
    if (route.annotations.interceptors.isNotEmpty ||
        route.annotations.intercepts.isNotEmpty)
      'interceptors': literalConstList([
        if (route.annotations.interceptors.isNotEmpty)
          for (final interceptor in route.annotations.interceptors)
            mimic(interceptor),
        if (route.annotations.intercepts.isNotEmpty)
          for (final intercepts in route.annotations.intercepts)
            for (final interceptor in intercepts.types)
              createClass(interceptor),
      ]),
    if (route.annotations.middlewares.isNotEmpty ||
        route.annotations.uses.isNotEmpty)
      'middlewares': literalConstList([
        if (route.annotations.middlewares.isNotEmpty)
          for (final middleware in route.annotations.middlewares)
            mimic(middleware),
        if (route.annotations.uses.isNotEmpty)
          for (final uses in route.annotations.uses)
            for (final middleware in uses.types) createClass(middleware),
      ]),
    if (route.annotations.combine.isNotEmpty)
      'combine': literalConstList(
          [for (final combine in route.annotations.combine) mimic(combine)]),
    if (route.annotations.meta.isNotEmpty)
      ...() {
        final m = refer('m');

        return {
          'meta': Method((p) => p
            ..requiredParameters.add(Parameter((b) => b..name = 'm'))
            ..body = Block.of([
              for (final meta in route.annotations.meta)
                m.cascade('add').call([
                  mimic(meta),
                ]).statement,
            ])).closure
        };
      }(),
    if (method != null) 'method': literalString(method),
    if ('$handler' != '$literalNull')
      'handler': Method(
        (p) => p
          ..requiredParameters.add(Parameter((b) => b..name = 'context'))
          ..modifier = MethodModifier.async
          ..body = Block.of([
            ...additionalHandlerCode,
            Code('\n'),
            handler.statement,
          ]),
      ).closure,
  };
}

Expression mimic(ShelfMimic mimic) => CodeExpression(Code(mimic.instance));

({Iterable<Expression> positioned, Map<String, Expression> named}) getParams(
  Iterable<ShelfParam> params,
) {
  final positioned = <Expression>[];
  final named = <String, Expression>{};

  for (final param in params) {
    if (param.isNamed) {
      named[param.name] = refer(param.name);
    } else {
      positioned.add(refer(param.name));
    }
  }
  return (positioned: [], named: {});
}

Expression createClass(ShelfClass clas) {
  final positioned = <Expression>[];
  final named = <String, Expression>{};
  final additionalExpressions = <Expression>[];

  for (final param in clas.params) {
    final arg = createParamArg(param, additionalExpressions);
    if (param.isNamed) {
      named[param.name] = arg;
    } else {
      positioned.add(arg);
    }
  }

  final constructor = refer(clas.className).newInstance(
    positioned,
    named,
  );

  return constructor;
}

Expression createParamArg(
  ShelfParam param,
  List<Expression> additionalExpressions,
) {
  final annotation = param.annotations;

  if (!annotation.hasAnnotation && !param.hasDefaultValue) {
    throw ArgumentError(
        'No annotation or default value for param ${param.name}');
  }

  if (param.defaultValue case final value? when !annotation.hasAnnotation) {
    return CodeExpression(Code(value));
  }

  if (annotation.dep) {
    return refer('DI').property('instance').property('get').call([]);
  }

  if (annotation.body case final body?) {
    final bodyVar = declareFinal('body')
        .assign(refer('context').property('request').property('body').awaited);
    final json = refer('json')
        .assign(refer('jsonDecode').call([refer('body')]))
        .asA(TypeReference(
          (p) => p
            ..symbol = 'Map'
            ..types.addAll([refer('String'), refer('dynamic')]),
        ));

    additionalExpressions.addAll([bodyVar, json]);

    Expression prePipe;

    if (body.access case final access?) {
      Expression bodyValue = refer('body');

      for (final part in access) {
        bodyValue = bodyValue.index(literalString(part)).nullChecked;
      }
      prePipe = bodyValue;
    } else {
      prePipe = refer('json');
    }

    if (body.pipe case final pipe?) {
      final pipeClass = createClass(pipe);

      return pipeClass.property('transform').call([prePipe]);
    }

    return prePipe;
  }

  if (annotation.param case final paramAnnotation?) {
    final paramsVar = declareFinal('params').assign(
      refer('context').property('request').property('pathParameters'),
    );

    additionalExpressions.add(paramsVar);

    final paramValue = refer('params')
        .index(literalString(paramAnnotation.name ?? param.name))
        .nullChecked;

    if (paramAnnotation.pipe case final pipe?) {
      final pipeClass = createClass(pipe);

      return pipeClass.property('transform').call([paramValue]);
    }

    return paramValue;
  }

  if (annotation.query case final query?) {
    var queryVar = declareFinal('query');

    if (query.all) {
      queryVar = queryVar.assign(
        refer('context').property('request').property('queryParametersAll'),
      );
    } else {
      queryVar = queryVar.assign(
        refer('context').property('request').property('queryParameters'),
      );
    }

    additionalExpressions.add(queryVar);

    final queryValue = refer('query')
        .index(literalString(query.name ?? param.name))
        .nullChecked;

    if (query.pipe case final pipe?) {
      final pipeClass = createClass(pipe);

      return pipeClass.property('transform').call([queryValue]);
    }

    return queryValue;
  }

  if (annotation.customParam case final customParam?) {
    final context = declareFinal('context').assign(
      refer('$CustomParamContext').newInstance(
        [],
        {
          'name': literalString(param.name),
          'type': refer(param.type),
          'data': refer('context').property('data'),
          'meta': refer('context').property('meta'),
          'request': refer('context').property('request'),
          'response': refer('context').property('response'),
        },
      ),
    );

    additionalExpressions.add(context);

    return mimic(customParam).property('parse').call([refer('context')]);
  }

  throw ArgumentError('Unknown annotation for param ${param.name}');
}
