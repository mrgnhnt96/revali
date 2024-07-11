import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:revali/ast/file_system/file_resource_provider.dart';
import 'package:revali/ast/visitors/app_visitor.dart';
import 'package:revali/ast/visitors/controller_visitor.dart';
import 'package:revali_construct/revali_construct.dart';

class FileTraverser {
  const FileTraverser(this.fs);

  final FileSystem fs;

  Future<MetaAppConfig?> parseApp(File file) async {
    if (!path.basename(file.path).endsWith('.app.dart')) {
      return null;
    }

    final resolved = await _resolve(file.path, fs);

    final classVisitor = AppVisitor();
    resolved.libraryElement.accept(classVisitor);

    if (!classVisitor.hasApp) {
      return null;
    }

    final (:element, :constructor, :params, :annotation, :isSecure) =
        classVisitor.values;

    return MetaAppConfig(
      className: element.displayName,
      importPath: element.librarySource.uri.toString(),
      element: element,
      constructor: constructor.name,
      params: params,
      appAnnotation: annotation,
      isSecure: isSecure,
      annotationsFor: ({
        required List<OnMatch> onMatch,
        NonMatch? onNonMatch,
      }) =>
          getAnnotations(
        element: element,
        onMatch: onMatch,
        onNonMatch: onNonMatch,
      ),
    );
  }

  Future<ResolvedUnitResult> _resolve(String file, FileSystem fs) async {
    final collection = AnalysisContextCollection(
      includedPaths: [file],
      resourceProvider: FileResourceProvider(fs),
    );

    final context = collection.contexts.first;
    final result = await context.currentSession.getResolvedUnit(file);
    if (result is! ResolvedUnitResult) {
      print('Failed to resolve the unit.');
      exit(1);
    }

    return result;
  }

  Future<MetaRoute?> parseRoute(File file) async {
    if (!path.basename(file.path).endsWith('.controller.dart')) {
      return null;
    }

    final resolved = await _resolve(file.path, fs);

    final classVisitor = ControllerVisitor();
    resolved.libraryElement.accept(classVisitor);

    if (!classVisitor.hasController) {
      return null;
    }

    final (:element, path: routePath, :constructor, :params, :methods) =
        classVisitor.values;

    return MetaRoute(
      path: routePath,
      filePath: file.path,
      className: element.name,
      params: params,
      element: element,
      constructorName: constructor.name,
      methods: methods,
      annotationsFor: ({
        required List<OnMatch> onMatch,
        NonMatch? onNonMatch,
      }) =>
          getAnnotations(
        element: element,
        onMatch: onMatch,
        onNonMatch: onNonMatch,
      ),
    );
  }
}
