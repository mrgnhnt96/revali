import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
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
    required this.customParam,
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
    ServerMimic? customParam;
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
      ],
    );

    var isOnlyOne = false;
    for (final annotation in <Object?>[
      body,
      query,
      param,
      customParam,
      dep,
    ]) {
      if (annotation == null) {
        continue;
      }

      if (isOnlyOne) {
        throw ArgumentError(
          'Only one of the following annotations can be used: '
          '@Body, @Query, @Param, @CustomParam, @Dep',
        );
      }

      isOnlyOne = true;
    }

    return ServerParamAnnotations(
      body: body,
      query: query,
      param: param,
      customParam: customParam,
      dep: dep ?? false,
    );
  }

  final ServerBodyAnnotation? body;
  final ServerQueryAnnotation? query;
  final ServerParamAnnotation? param;
  final ServerMimic? customParam;
  final bool dep;

  bool get hasAnnotation =>
      body != null ||
      query != null ||
      param != null ||
      customParam != null ||
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
  }

  @override
  List<ExtractImport?> get extractors => [body, query, param, customParam];

  @override
  List<ServerImports?> get imports => const [];
}
