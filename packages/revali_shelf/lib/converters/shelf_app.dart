import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/revali_shelf.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfApp with ExtractImport {
  ShelfApp({
    required this.className,
    required this.importPath,
    required this.constructor,
    required this.params,
    required this.appAnnotation,
    required this.globalRouteAnnotations,
  });

  factory ShelfApp.fromMeta(MetaAppConfig app) {
    return ShelfApp(
      className: app.className,
      importPath: ShelfImports([app.importPath]),
      constructor: app.constructor,
      params: app.params.map((param) => ShelfParam.fromMeta(param)).toList(),
      appAnnotation: ShelfAppAnnotation.fromMeta(app.appAnnotation),
      globalRouteAnnotations: ShelfRouteAnnotations.fromApp(app),
    );
  }

  final String className;
  final ShelfImports importPath;
  final String constructor;
  final List<ShelfParam> params;
  final ShelfAppAnnotation appAnnotation;
  final ShelfRouteAnnotations globalRouteAnnotations;

  @override
  List<ExtractImport?> get extractors => [...params];

  @override
  List<ShelfImports?> get imports => [importPath];
}
