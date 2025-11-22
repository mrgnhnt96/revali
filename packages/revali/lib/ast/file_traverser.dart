import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:revali/ast/analyzer/units.dart';
import 'package:revali/ast/visitors/app_visitor.dart';
import 'package:revali/ast/visitors/controller_visitor.dart';
import 'package:revali_construct/revali_construct.dart';

class FileTraverser {
  const FileTraverser(this.fs);

  final FileSystem fs;

  Stream<MetaAppConfig> parseApps(Units units) async* {
    if (!path.basename(units.parsed.path).contains(RegExp(r'[._]app\.dart$'))) {
      return;
    }

    final resolved = await units.resolved();

    final classVisitor = AppVisitor();
    resolved.libraryElement.accept2(classVisitor);

    if (!classVisitor.hasApp) {
      return;
    }

    for (final entry in classVisitor.entries) {
      final element = entry.element;
      yield MetaAppConfig(
        className: element.displayName,
        importPath: element.library.uri.toString(),
        element: element,
        constructor:
            entry.constructor.name3 ??
            (throw Exception('Constructor name is null')),
        params: entry.params,
        appAnnotation: entry.annotation,
        isSecure: entry.isSecure,
        annotationsFor:
            ({required List<OnMatch> onMatch, NonMatch? onNonMatch}) =>
                getAnnotations(
                  element: element,
                  onMatch: onMatch,
                  onNonMatch: onNonMatch,
                ),
      );
    }
  }

  Future<MetaRoute?> parseRoute(Units units) async {
    if (!path
        .basename(units.parsed.path)
        .contains(RegExp(r'[._]controller\.dart$'))) {
      return null;
    }

    final resolved = await units.resolved();

    final classVisitor = ControllerVisitor();
    resolved.libraryElement.accept(classVisitor);

    if (!classVisitor.hasController) {
      return null;
    }

    final (:element, path: routePath, :constructor, :params, :methods, :type) =
        classVisitor.values;

    return MetaRoute(
      path: routePath,
      filePath: units.parsed.path,
      className: element.name ?? (throw Exception('Class name is null')),
      params: params,
      element: element,
      constructorName:
          constructor.name ?? (throw Exception('Constructor name is null')),
      methods: methods,
      type: type,
      annotationsFor:
          ({required List<OnMatch> onMatch, NonMatch? onNonMatch}) =>
              getAnnotations(
                element: element,
                onMatch: onMatch,
                onNonMatch: onNonMatch,
              ),
    );
  }
}
