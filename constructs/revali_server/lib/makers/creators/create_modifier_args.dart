// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method;
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/creators/create_mimic.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Map<String, Expression> createModifierArgs({
  required ServerRouteAnnotations annotations,
}) {
  final typeReferences = annotations.coreTypeReferences;
  final mimics = annotations.coreMimics;
  final lifecycleComponents = annotations.lifecycleComponents;

  return {
    if (mimics.catchers.isNotEmpty ||
        typeReferences.catchers.isNotEmpty ||
        lifecycleComponents.hasExceptions)
      'catchers': literalList([
        if (mimics.catchers case final catchers)
          for (final catcher in catchers) createMimic(catcher),
        if (typeReferences.catchers.expand((e) => e.types) case final catchers)
          for (final catcher in catchers) createClass(catcher),
        for (final component in lifecycleComponents)
          for (final (catcher, _) in component.exceptionClasses)
            createClass(catcher),
      ]),
    if (annotations.data.isNotEmpty)
      'data':
          literalList([for (final data in annotations.data) createMimic(data)]),
    if (mimics.guards.isNotEmpty ||
        typeReferences.guards.isNotEmpty ||
        lifecycleComponents.hasGuards)
      'guards': literalList([
        for (final guard in mimics.guards) createMimic(guard),
        for (final guards in typeReferences.guards)
          for (final guard in guards.types) createClass(guard),
        for (final component in lifecycleComponents)
          createClass(component.guardClass),
      ]),
    if (mimics.interceptors.isNotEmpty ||
        typeReferences.interceptors.isNotEmpty ||
        lifecycleComponents.hasInterceptors)
      'interceptors': literalList([
        for (final interceptor in mimics.interceptors) createMimic(interceptor),
        for (final intercepts in typeReferences.interceptors)
          for (final interceptor in intercepts.types) createClass(interceptor),
        for (final component in lifecycleComponents)
          createClass(component.interceptorClass),
      ]),
    if (mimics.middlewares.isNotEmpty ||
        typeReferences.middlewares.isNotEmpty ||
        lifecycleComponents.hasMiddlewares)
      'middlewares': literalList([
        for (final middleware in mimics.middlewares) createMimic(middleware),
        for (final middlewares in typeReferences.middlewares)
          for (final middleware in middlewares.types) createClass(middleware),
        for (final component in lifecycleComponents)
          createClass(component.middlewareClass),
      ]),
    if (annotations.allowOrigins case final allow?
        when allow.origins.isNotEmpty)
      'allowedOrigins': refer((AllowedOriginsImpl).name).constInstance([
        literalSet([
          for (final allowOrigin in allow.origins) literalString(allowOrigin),
        ]),
      ], {
        'inherit': literalBool(allow.inherit),
      }),
    if (annotations.allowHeaders case final allow?
        when allow.headers.isNotEmpty)
      'allowedHeaders': refer((AllowedHeadersImpl).name).constInstance([
        literalSet([
          for (final allowHeader in allow.headers) literalString(allowHeader),
        ]),
      ], {
        'inherit': literalBool(allow.inherit),
      }),
    if (annotations.expectHeaders case final expect?
        when expect.headers.isNotEmpty)
      'expectedHeaders': refer((ExpectedHeadersImpl).name).constInstance([
        literalSet([
          for (final expectHeader in expect.headers)
            literalString(expectHeader),
        ]),
      ]),
    if (mimics.combines.isNotEmpty || typeReferences.combines.isNotEmpty)
      'combine': literalList([
        if (mimics.combines.isNotEmpty)
          for (final combine in mimics.combines) createMimic(combine),
        if (typeReferences.combines.isNotEmpty)
          for (final uses in typeReferences.combines)
            for (final combine in uses.types) createClass(combine),
      ]),
    if (annotations.responseHandler case final ServerMimic handler)
      'responseHandler': createMimic(handler),
    if (annotations.meta.isNotEmpty)
      ...() {
        final m = refer('m');

        return {
          'meta': Method(
            (p) => p
              ..requiredParameters.add(Parameter((b) => b..name = 'm'))
              ..body = Block.of([
                for (final meta in annotations.meta)
                  m.cascade('add').call([
                    createMimic(meta),
                  ]).statement,
              ]),
          ).closure,
        };
      }(),
  };
}

extension _IterableServerLifecycleComponentX
    on Iterable<ServerLifecycleComponent> {
  bool get hasExceptions => any((e) => e.hasExceptionCatchers);
  bool get hasGuards => any((e) => e.hasGuards);
  bool get hasInterceptors => any((e) => e.hasInterceptors);
  bool get hasMiddlewares => any((e) => e.hasMiddlewares);
}
