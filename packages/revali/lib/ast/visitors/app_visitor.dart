import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/visitors/get_params.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_core/revali_core.dart';

class _AppEntry {
  const _AppEntry({
    required this.element,
    required this.constructor,
    required this.params,
    required this.annotation,
    required this.isSecure,
  });

  final ClassElement element;
  final ConstructorElement constructor;
  final Iterable<MetaParam> params;
  final AppAnnotation annotation;
  final bool isSecure;
}

class AppVisitor extends RecursiveElementVisitor<void> {
  final entries = <_AppEntry>[];

  bool get hasApp => entries.isEmpty;

  @override
  void visitClassElement(ClassElement element) {
    super.visitClassElement(element);

    if (!appChecker.hasAnnotationOf(element)) {
      return;
    }

    if (element.constructors.isEmpty) {
      throw Exception('No constructor found in ${element.name}');
    }

    if (element.constructors.every((e) => e.isPrivate)) {
      throw Exception('No public constructor found in ${element.name}');
    }

    if (element.allSupertypes.every((e) => e.element.name != '$AppConfig')) {
      throw Exception('App class must extend `$AppConfig`');
    }

    final constructor = element.constructors.first;

    entries.add(
      _AppEntry(
        element: element,
        constructor: constructor,
        params: getParams(constructor),
        annotation: AppAnnotation.fromAnnotation(
          appChecker.firstAnnotationOf(element)!,
        ),
        isSecure: constructor.superConstructor?.name == 'secure',
      ),
    );
  }
}
