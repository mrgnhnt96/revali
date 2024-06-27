import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:zora/checkers/checkers.dart';
import 'package:zora/file_system/file_resource_provider.dart';
import 'package:zora_construct/zora_construct.dart';

class RouteTraverser {
  const RouteTraverser({required this.fs});

  final FileSystem fs;

  Future<MetaRoute?> parse(File file) async {
    if (!path.basename(file.path).endsWith('.controller.dart')) {
      return null;
    }

    final collection = AnalysisContextCollection(
      includedPaths: [file.path],
      resourceProvider: FileResourceProvider(fs),
    );

    final context = collection.contexts.first;
    final result = await context.currentSession.getResolvedUnit(file.path);
    if (result is! ResolvedUnitResult) {
      print('Failed to resolve the unit.');
      exit(1);
    }

    final classVisitor = ClassVisitor();
    result.libraryElement.accept(classVisitor);

    if (classVisitor.clazz == null || classVisitor.path == null) {
      return null;
    }
    final clazz = classVisitor.clazz!;
    final routePath = classVisitor.path!;

    final methodVisitor = MethodVisitor();
    clazz.accept(methodVisitor);

    final middlewares = getMiddleware(clazz);

    if (clazz.constructors.isEmpty) {
      throw Exception('No constructor found in ${clazz.name}');
    }

    final constructor = clazz.constructors.first;

    final params = getParams(constructor);

    return MetaRoute(
      path: routePath,
      filePath: file.path,
      className: clazz.name,
      params: params,
      constructorName: constructor.name,
      methods: [...methodVisitor.methods.values],
      middlewares: middlewares,
    );
  }
}

class ClassVisitor extends RecursiveElementVisitor<void> {
  ClassElement? clazz;
  String? path;
  @override
  void visitClassElement(ClassElement element) {
    super.visitClassElement(element);

    if (!controllerChecker.hasAnnotationOf(element)) {
      return;
    }

    if (clazz != null) {
      throw Exception('Only one request class per file is allowed');
    }

    final annotation = controllerChecker.annotationsOf(element);

    if (annotation.length > 1) {
      throw Exception('Only one controller type per class is allowed');
    }

    final controller = ControllerAnnotation.fromAnnotation(annotation.first);

    clazz = element;
    path = controller.path;
  }
}

class MethodVisitor extends RecursiveElementVisitor<void> {
  // Method name to method element
  Map<String, MetaMethod> methods = {};

  @override
  void visitMethodElement(MethodElement element) {
    super.visitMethodElement(element);

    if (!methodChecker.hasAnnotationOf(element)) {
      return;
    }

    final annotation = methodChecker.annotationsOf(element);

    if (annotation.length > 1) {
      throw Exception('Only one method type per method is allowed');
    }

    final method = MethodAnnotation.fromAnnotation(annotation.first);

    // only one method type per method
    if (methods.containsKey(method.name)) {
      throw Exception('Only one method type per method is allowed');
    }

    final params = getParams(element);
    final middlewares = getMiddleware(element);

    methods[method.name] = MetaMethod(
      name: element.name,
      method: method.name,
      path: method.path,
      annotations: element.metadata,
      params: params,
      middlewares: middlewares,
      returnType: MetaReturnType(
        isVoid: element.returnType is VoidType,
        isNullable:
            element.returnType.nullabilitySuffix != NullabilitySuffix.none,
        type: element.returnType.getDisplayString(withNullability: false),
        element: element.returnType.element,
      ),
    );
  }
}

Iterable<MetaMiddleware> getMiddleware(Element element) {
  final middlewares = <MetaMiddleware>[];
  final middlewareAnnotations = middlewareChecker.annotationsOf(element);

  for (final annotation in middlewareAnnotations) {
    final name = annotation.type?.getDisplayString(withNullability: false);

    if (name == null) {
      continue;
    }

    middlewares.add(MetaMiddleware(
      name: name,
      element: annotation,
    ));
  }

  return middlewares;
}

Iterable<MetaParam> getParams(FunctionTypedElement element) {
  final params = <MetaParam>[];

  for (final param in element.parameters) {
    final annotations = param.metadata;
    final type = param.type.getDisplayString(withNullability: false);

    final element = param.type.element;
    if (element == null) {
      throw Exception('Element not found for type $type');
    }

    params.add(
      MetaParam(
        name: param.name,
        type: type,
        typeElement: element,
        nullable: param.type.nullabilitySuffix != NullabilitySuffix.none,
        isRequired: param.isRequired,
        annotations: annotations,
      ),
    );
  }

  return params;
}
