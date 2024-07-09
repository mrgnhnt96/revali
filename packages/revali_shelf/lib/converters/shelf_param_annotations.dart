import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_body_annotation.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_param_annotation.dart';
import 'package:revali_shelf/converters/shelf_query_annotation.dart';
import 'package:revali_shelf/converters/shelf_reflect.dart';

class ShelfParamAnnotations {
  const ShelfParamAnnotations({
    required this.body,
    required this.query,
    required this.param,
    required this.dep,
    required this.customParam,
  });

  factory ShelfParamAnnotations.fromMeta(MetaParam metaParam) {
    return ShelfParamAnnotations._getter(metaParam.annotationsFor);
  }

  factory ShelfParamAnnotations.fromElement(ParameterElement element) {
    return ShelfParamAnnotations._getter(({
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

  factory ShelfParamAnnotations._getter(AnnotationMapper getter) {
    ShelfBodyAnnotation? body;
    ShelfQueryAnnotation? query;
    ShelfParamAnnotation? param;
    ShelfMimic? customParam;
    bool? dep;

    getter(
      onMatch: [
        OnMatch(
          classType: Body,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            body = ShelfBodyAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Query,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            query = ShelfQueryAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Param,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            param = ShelfParamAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: CustomParam,
          ignoreGenerics: true,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            customParam = ShelfMimic.fromDartObject(object, annotation);
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
          '@Body, @Query, @Param, @CustomParam',
        );
      }

      isOnlyOne = true;
    }

    return ShelfParamAnnotations(
      body: body,
      query: query,
      param: param,
      customParam: customParam,
      dep: dep ?? false,
    );
  }

  final ShelfBodyAnnotation? body;
  final ShelfQueryAnnotation? query;
  final ShelfParamAnnotation? param;
  final ShelfMimic? customParam;
  final bool dep;

  bool get hasAnnotation =>
      body != null ||
      query != null ||
      param != null ||
      customParam != null ||
      dep;

  Iterable<String> get imports sync* {
    if (body?.pipe?.pipe.imports case final imports?) {
      yield* imports;
    }

    if (query?.pipe?.pipe.imports case final imports?) {
      yield* imports;
    }

    if (param?.pipe?.pipe.imports case final imports?) {
      yield* imports;
    }

    if (customParam?.imports.imports case final imports?) {
      yield* imports;
    }
  }

  Iterable<ShelfReflect> get reflects sync* {
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
}
