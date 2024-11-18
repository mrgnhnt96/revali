// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method;
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

  return {
    if (mimics.catchers.isNotEmpty || typeReferences.catchers.isNotEmpty)
      'catchers': literalList([
        if (mimics.catchers case final catchers when catchers.isNotEmpty)
          for (final catcher in catchers) createMimic(catcher),
        if (typeReferences.catchers.expand((e) => e.types) case final catchers
            when catchers.isNotEmpty)
          for (final catcher in catchers) createClass(catcher),
      ]),
    if (annotations.data.isNotEmpty)
      'data':
          literalList([for (final data in annotations.data) createMimic(data)]),
    if (mimics.guards.isNotEmpty || typeReferences.guards.isNotEmpty)
      'guards': literalList([
        if (mimics.guards.isNotEmpty)
          for (final guard in mimics.guards) createMimic(guard),
        if (typeReferences.guards.isNotEmpty)
          for (final guards in typeReferences.guards)
            for (final guard in guards.types) createClass(guard),
      ]),
    if (mimics.interceptors.isNotEmpty ||
        typeReferences.interceptors.isNotEmpty)
      'interceptors': literalList([
        if (mimics.interceptors.isNotEmpty)
          for (final interceptor in mimics.interceptors)
            createMimic(interceptor),
        if (typeReferences.interceptors.isNotEmpty)
          for (final intercepts in typeReferences.interceptors)
            for (final interceptor in intercepts.types)
              createClass(interceptor),
      ]),
    if (mimics.middlewares.isNotEmpty || typeReferences.middlewares.isNotEmpty)
      'middlewares': literalList([
        if (mimics.middlewares.isNotEmpty)
          for (final middleware in mimics.middlewares) createMimic(middleware),
        if (typeReferences.middlewares.isNotEmpty)
          for (final middlewares in typeReferences.middlewares)
            for (final middleware in middlewares.types) createClass(middleware),
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
