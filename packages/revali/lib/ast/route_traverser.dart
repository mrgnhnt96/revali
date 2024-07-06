import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:revali/ast/checkers/checkers.dart';
import 'package:revali/ast/file_system/file_resource_provider.dart';
import 'package:revali_construct/revali_construct.dart';

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
      element: clazz,
      constructorName: constructor.name,
      methods: [...methodVisitor.methods.values.expand((e) => e)],
      annotationsFor: ({
        required List<OnMatch> onMatch,
        NonMatch? onNonMatch,
      }) =>
          getAnnotations(
        element: clazz,
        onMatch: onMatch,
        onNonMatch: onNonMatch,
      ),
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
  Map<String, List<MetaMethod>> methods = {};

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
    if (methods[method.name] case final parsed?) {
      for (final parsedMethod in parsed) {
        if (parsedMethod.path == method.path) {
          throw Exception('Conflicting paths ${parsedMethod.path}');
        }
      }
    }

    final params = getParams(element);

    final type = element.returnType.getDisplayString(withNullability: false);

    (methods[method.name] ??= []).add(
      MetaMethod(
        name: element.name,
        method: method.name,
        path: method.path,
        params: params,
        returnType: MetaReturnType(
          isVoid:
              element.returnType is VoidType ? true : type.contains('<void>'),
          isNullable:
              element.returnType.nullabilitySuffix != NullabilitySuffix.none,
          type: type,
          element: element.returnType.element,
          isFuture: element.returnType.isDartAsyncFuture,
        ),
        annotationsMapper: ({
          required List<OnMatch> onMatch,
          NonMatch? onNonMatch,
        }) =>
            getAnnotations(
          element: element,
          onNonMatch: onNonMatch,
          onMatch: onMatch,
        ),
      ),
    );
  }
}

Iterable<MetaParam> getParams(FunctionTypedElement element) {
  final params = <MetaParam>[];

  for (final param in element.parameters) {
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
        isNamed: param.isNamed,
        defaultValue: param.defaultValueCode,
        annotationsFor: ({
          required List<OnMatch> onMatch,
          NonMatch? onNonMatch,
        }) =>
            getAnnotations(
          element: param,
          onMatch: onMatch,
          onNonMatch: onNonMatch,
        ),
      ),
    );
  }

  return params;
}
