import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/models/app_annotation.dart';
import 'package:revali_construct/models/meta_param.dart';
import 'package:revali_construct/types/annotation_getter.dart';

class MetaAppConfig {
  const MetaAppConfig({
    required this.className,
    required this.importPath,
    required this.constructor,
    required this.params,
    required this.element,
    required this.annotationsFor,
    required this.appAnnotation,
  });

  factory MetaAppConfig.defaultConfig() = _DefaultAppConfig;

  final String className;
  final String importPath;
  final AppAnnotation appAnnotation;
  final ClassElement? element;
  final String constructor;
  final List<MetaParam> params;
  final AnnotationMapper annotationsFor;
}

class _DefaultAppConfig extends MetaAppConfig {
  const _DefaultAppConfig()
      : super(
          className: 'AppConfig',
          importPath: 'package:revali_construct/revali_construct.dart',
          element: null,
          constructor: 'defaultApp',
          params: const [],
          appAnnotation: const AppAnnotation(flavor: null),
          annotationsFor: _fakeAnnotationsFor,
        );
}

void _fakeAnnotationsFor({
  required List<OnMatch> onMatch,
  NonMatch? onNonMatch,
}) {}