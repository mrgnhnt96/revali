import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/visitors/get_params.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';

class AppVisitor extends RecursiveElementVisitor<void> {
  ClassElement? _app;
  ConstructorElement? _constructor;
  AppAnnotation? _annotation;

  final _params = <MetaParam>[];

  bool get hasApp => _app != null && _constructor != null;

  ({
    ClassElement element,
    ConstructorElement constructor,
    List<MetaParam> params,
    AppAnnotation annotation,
  }) get values {
    return (
      element: _app!,
      constructor: _constructor!,
      params: _params,
      annotation: _annotation!,
    );
  }

  @override
  void visitClassElement(ClassElement element) {
    super.visitClassElement(element);

    if (!appChecker.hasAnnotationOf(element)) {
      return;
    }

    if (_app != null) {
      throw Exception('Only one app class per file is allowed');
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

    _app = element;
    _constructor = element.constructors.first;
    _params.addAll(getParams(_constructor!));
    _annotation = AppAnnotation.fromAnnotation(
      appChecker.firstAnnotationOf(element)!,
    );
  }
}
