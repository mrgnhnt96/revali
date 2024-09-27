import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_bind_annotation.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_param_annotation.dart';
import 'package:revali_server/converters/server_query_annotation.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerParamAnnotations with ExtractImport {
  ServerParamAnnotations({
    required this.body,
    required this.query,
    required this.param,
    required this.dep,
    required this.header,
    required this.customParam,
    required this.bind,
  });

  factory ServerParamAnnotations.fromMeta(MetaParam metaParam) {
    return ServerParamAnnotations._getter(metaParam.annotationsFor);
  }

  factory ServerParamAnnotations.fromElement(ParameterElement element) {
    return ServerParamAnnotations._getter(({
      required List<OnMatch> onMatch,
      NonMatch? onNonMatch,
    }) {
      return getAnnotations(
        element: element,
        onMatch: onMatch,
        onNonMatch: onNonMatch,
      );
    });
  }

  factory ServerParamAnnotations._getter(AnnotationMapper getter) {
    ServerBodyAnnotation? body;
    ServerQueryAnnotation? query;
    ServerParamAnnotation? param;
    ServerHeaderAnnotation? header;
    ServerMimic? customParam;
    ServerBindAnnotation? bind;
    bool? dep;

    getter(
      onMatch: [
        OnMatch(
          classType: Body,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            body = ServerBodyAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Query,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            query = ServerQueryAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Header,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            header = ServerHeaderAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Param,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            param = ServerParamAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: CustomParam,
          ignoreGenerics: true,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            customParam = ServerMimic.fromDartObject(object, annotation);
          },
        ),
        OnMatch(
          classType: Dep,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            dep = true;
          },
        ),
        OnMatch(
          classType: Bind,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            bind = ServerBindAnnotation.fromElement(object, annotation);
          },
        ),
      ],
    );

    var isOnlyOne = false;
    for (final annotation in <Object?>[
      body,
      query,
      header,
      param,
      customParam,
      dep,
      bind,
    ]) {
      if (annotation == null) {
        continue;
      }

      if (isOnlyOne) {
        throw ArgumentError(
          'Only one of the following annotations can be used: '
          '@Body, @Query, @Param, @<CustomParam>, @Dep, @Bind',
        );
      }

      isOnlyOne = true;
    }

    return ServerParamAnnotations(
      body: body,
      query: query,
      param: param,
      customParam: customParam,
      header: header,
      dep: dep ?? false,
      bind: bind,
    );
  }

  final ServerBodyAnnotation? body;
  final ServerQueryAnnotation? query;
  final ServerHeaderAnnotation? header;
  final ServerParamAnnotation? param;
  final ServerBindAnnotation? bind;
  final ServerMimic? customParam;
  final bool dep;

  bool get hasAnnotation =>
      body != null ||
      query != null ||
      header != null ||
      param != null ||
      customParam != null ||
      bind != null ||
      dep;

  Iterable<ServerReflect> get reflects sync* {
    if (body?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (query?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (param?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (header?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (bind?.customParam.reflect case final reflect?) {
      yield reflect;
    }
  }

  @override
  List<ExtractImport?> get extractors => [
        body,
        query,
        header,
        param,
        customParam,
        bind,
      ];

  @override
  List<ServerImports?> get imports => const [];
}
