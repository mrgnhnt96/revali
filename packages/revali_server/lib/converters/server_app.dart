import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_app_annotation.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerApp with ExtractImport {
  ServerApp({
    required this.className,
    required this.importPath,
    required this.constructor,
    required this.params,
    required this.appAnnotation,
    required this.globalRouteAnnotations,
    required this.isSecure,
  });

  factory ServerApp.fromMeta(MetaAppConfig app) {
    return ServerApp(
      className: app.className,
      isSecure: app.isSecure,
      importPath: ServerImports([app.importPath]),
      constructor: app.constructor,
      params: app.params.map((param) => ServerParam.fromMeta(param)).toList(),
      appAnnotation: ServerAppAnnotation.fromMeta(app.appAnnotation),
      globalRouteAnnotations: ServerRouteAnnotations.fromApp(app),
    );
  }

  final String className;
  final ServerImports importPath;
  final String constructor;
  final List<ServerParam> params;
  final ServerAppAnnotation appAnnotation;
  final ServerRouteAnnotations globalRouteAnnotations;
  final bool isSecure;

  @override
  List<ExtractImport?> get extractors => [...params];

  @override
  List<ServerImports?> get imports => [importPath];
}
