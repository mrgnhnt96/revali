import 'package:revali/server/converters/server_app_annotation.dart';
import 'package:revali/server/converters/server_app_observers.dart';
import 'package:revali/server/converters/server_imports.dart';
import 'package:revali/server/converters/server_mimic.dart';
import 'package:revali/server/converters/server_param.dart';
import 'package:revali/server/converters/server_route_annotations.dart';
import 'package:revali/server/converters/server_type_reference.dart';
import 'package:revali/server/utils/extract_import.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_core/revali_core.dart';

class ServerApp with ExtractImport {
  ServerApp({
    required this.className,
    required this.importPath,
    required this.constructor,
    required this.params,
    required this.appAnnotation,
    required this.globalRouteAnnotations,
    required this.isSecure,
    required this.observers,
  });

  factory ServerApp.fromMeta(MetaAppConfig app) {
    final observers = ServerAppObservers();

    app.annotationsFor(
      onMatch: [
        OnMatch(
          classType: Observer,
          package: 'revali_core',
          convert: (object, annotation) {
            observers.mimics.add(
              ServerMimic.fromDartObject(object, annotation),
            );
          },
        ),
        OnMatch(
          classType: Observers,
          package: 'revali_annotations',
          convert: (object, annotation) {
            observers.types.add(
              ServerTypeReference.fromElement(object, superType: Observer),
            );
          },
        ),
      ],
    );

    return ServerApp(
      className: app.className,
      isSecure: app.isSecure,
      importPath: ServerImports([app.importPath]),
      constructor: app.constructor,
      params: app.params.map(ServerParam.fromMeta).toList(),
      appAnnotation: ServerAppAnnotation.fromMeta(app.appAnnotation),
      globalRouteAnnotations: ServerRouteAnnotations.fromApp(app),
      observers: observers,
    );
  }

  final String className;
  final ServerImports importPath;
  final String constructor;
  final List<ServerParam> params;
  final ServerAppAnnotation appAnnotation;
  final ServerRouteAnnotations globalRouteAnnotations;
  final bool isSecure;
  final ServerAppObservers observers;

  @override
  List<ExtractImport?> get extractors => [
    ...params,
    globalRouteAnnotations,
    observers,
  ];

  @override
  List<ServerImports?> get imports => [importPath];
}
