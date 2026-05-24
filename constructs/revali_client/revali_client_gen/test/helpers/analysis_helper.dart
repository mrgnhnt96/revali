import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

class AnalysisHelper {
  AnalysisHelper({required this.fixtureRoot});

  final String fixtureRoot;

  AnalysisContextCollection? _collection;

  AnalysisContextCollection get collection {
    return _collection ??= AnalysisContextCollection(
      includedPaths: [fixtureRoot],
    );
  }

  static Future<AnalysisHelper> create() async {
    final fixtureRoot = p.normalize(
      p.join(
        Directory.current.path,
        '..',
        '..',
        'revali_server',
        'test',
        'fixtures',
        'generic_lifecycle',
      ),
    );

    final pubGet = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: fixtureRoot);

    if (pubGet.exitCode != 0) {
      throw StateError(
        'Failed to run pub get in $fixtureRoot:\n${pubGet.stderr}',
      );
    }

    return AnalysisHelper(fixtureRoot: fixtureRoot);
  }

  Future<ResolvedUnitResult> resolveLib(String relativePath) async {
    final path = p.normalize(
      p.joinAll([fixtureRoot, ...p.split(relativePath)]),
    );
    final session = collection.contextFor(path).currentSession;
    final result = await session.getResolvedUnit(path);

    if (result is! ResolvedUnitResult) {
      throw StateError('Failed to resolve $path: $result');
    }

    return result;
  }

  Future<TopLevelFunctionElement> topLevelFunction(String name) async {
    final result = await resolveLib('lib/usage.dart');

    for (final function in result.libraryElement.topLevelFunctions) {
      if (function.name == name) {
        return function;
      }
    }

    throw StateError('Could not find top-level function $name');
  }

  Future<({DartObject object, ElementAnnotation annotation})>
  lifecycleComponentAnnotation({
    required String functionName,
    required String annotationName,
  }) async {
    final function = await topLevelFunction(functionName);

    for (final annotation in function.metadata.annotations) {
      if (annotation.element?.displayName != annotationName) {
        continue;
      }

      final object = annotation.computeConstantValue();
      if (object == null) {
        throw StateError(
          'Annotation $annotationName on $functionName is not constant',
        );
      }

      return (object: object, annotation: annotation);
    }

    throw StateError('Could not find @$annotationName on $functionName');
  }

  Future<({DartObject object, ElementAnnotation annotation})>
  lifecycleComponentsAnnotation({required String functionName}) async {
    return lifecycleComponentAnnotation(
      functionName: functionName,
      annotationName: 'LifecycleComponents',
    );
  }

  Future<ClassElement> classElement({
    required String unitPath,
    required String className,
  }) async {
    final result = await resolveLib(unitPath);

    for (final element in result.libraryElement.classes) {
      if (element.name == className) {
        return element;
      }
    }

    throw StateError('Could not find class $className in $unitPath');
  }

  Future<MethodElement> methodElement({
    required String unitPath,
    required String className,
    required String methodName,
  }) async {
    final classElement = await this.classElement(
      unitPath: unitPath,
      className: className,
    );

    for (final method in classElement.methods) {
      if (method.name == methodName) {
        return method;
      }
    }

    throw StateError(
      'Could not find method $methodName on $className in $unitPath',
    );
  }
}
