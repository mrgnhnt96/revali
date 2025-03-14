import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/visitors/method_visitor.dart';
import 'package:revali_construct/revali_construct.dart';

class ControllerVisitor extends RecursiveElementVisitor<void> {
  ClassElement? _controller;
  String? _path;
  ConstructorElement? _constructor;

  final _params = <MetaParam>[];

  final _methods = <MetaMethod>[];

  bool get hasController =>
      _controller != null && _path != null && _constructor != null;

  ({
    ClassElement element,
    String path,
    ConstructorElement constructor,
    List<MetaParam> params,
    List<MetaMethod> methods,
  }) get values {
    return (
      element: _controller!,
      path: _path!,
      constructor: _constructor!,
      params: _params,
      methods: _methods,
    );
  }

  @override
  void visitClassElement(ClassElement element) {
    super.visitClassElement(element);

    if (!controllerChecker.hasAnnotationOf(element)) {
      return;
    }

    if (_controller != null) {
      throw Exception('Only one controller class per file is allowed');
    }

    final annotation = controllerChecker.annotationsOf(element);

    if (annotation.length > 1) {
      throw Exception('Only one controller annotation per class is allowed');
    }

    if (element.constructors.isEmpty) {
      throw Exception('No constructor found in ${element.name}');
    }

    if (element.constructors.every((e) => e.isPrivate)) {
      throw Exception('No public constructor found in ${element.name}');
    }

    _controller = element;
    _constructor = element.constructors.first;
    if (_constructor case ConstructorElement(:final parameters)) {
      _params.addAll(parameters.map(MetaParam.fromParam));
    }

    final controller = ControllerAnnotation.fromAnnotation(annotation.first);
    _path = controller.path;

    final methodVisitor = MethodVisitor();
    element.accept(methodVisitor);

    _methods.addAll(methodVisitor.methods.values.expand((e) => e));
  }
}
