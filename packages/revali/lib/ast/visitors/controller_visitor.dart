// ignore_for_file: use_late_for_private_fields_and_variables

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/visitors/method_visitor.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';

class ControllerVisitor extends RecursiveElementVisitor2<void> {
  ClassElement? _controller;
  String? _path;
  ConstructorElement? _constructor;
  InstanceType? _type;
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
    InstanceType type,
  })
  get values {
    return (
      element: _controller!,
      path: _path!,
      constructor: _constructor!,
      params: _params,
      methods: _methods,
      type: _type!,
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
    if (_constructor case ConstructorElement(:final formalParameters)) {
      _params.addAll(formalParameters.map(MetaParam.fromParam));
    }

    final controller = ControllerAnnotation.fromAnnotation(annotation.first);
    _path = controller.path;
    _type = controller.type;
    final controllerName = element.name ?? 'Unknown';
    final methodVisitor = MethodVisitor(controllerName);

    // The controller's own methods first, so an override beats the
    // annotation it inherits.
    element.accept(methodVisitor);

    for (final supertype in element.allSupertypes) {
      final superElement = supertype.element;

      if (!superElement.methods.any(methodChecker.hasAnnotationOf)) {
        continue;
      }

      if (supertype.typeArguments.isNotEmpty) {
        throw Exception(
          'Controller $controllerName inherits endpoints from generic type '
          '${superElement.name}<${supertype.typeArguments.join(', ')}>, which '
          'is not supported: the inherited signatures still refer to the type '
          'parameters, so the generated bindings would be wrong. Move the '
          'endpoints onto $controllerName, or make the base non-generic.',
        );
      }

      superElement.accept(methodVisitor);
    }

    _methods.addAll(methodVisitor.methods.values.expand((e) => e));
  }
}
