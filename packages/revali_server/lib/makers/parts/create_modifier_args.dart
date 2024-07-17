import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core_access_control.dart';
import 'package:revali_server/revali_server.dart';

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
    if (annotations.allowOrigins case final allow?
        when allow.origins.isNotEmpty)
      'allowedOrigins': refer('$AllowOrigins').newInstance([
        literalSet([
          for (final allowOrigin in allow.origins) literalString(allowOrigin),
        ])
      ], {
        'inherit': literalBool(allow.inherit),
      }),
    if (annotations.allowHeaders case final allow?
        when allow.headers.isNotEmpty)
      'allowedHeaders': refer('$AllowHeaders').newInstance([
        literalSet([
          for (final allowHeader in allow.headers) literalString(allowHeader),
        ])
      ], {
        'inherit': literalBool(allow.inherit),
      }),
    if (mimics.combines.isNotEmpty || typeReferences.combines.isNotEmpty)
      'combine': literalList([
        if (mimics.combines.isNotEmpty)
          for (final combine in mimics.combines) mimic(combine),
        if (typeReferences.combines.isNotEmpty)
          for (final uses in typeReferences.combines)
            for (final combine in uses.types) createClass(combine),
      ]),
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
