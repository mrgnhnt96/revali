import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/models/swagger_controller.dart';
import 'package:revali_swagger/models/swagger_settings.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

class SwaggerInfo {
  const SwaggerInfo({
    required this.title,
    required this.version,
    this.description,
  });

  final String title;
  final String version;
  final String? description;
}

class SwaggerServer {
  SwaggerServer({required this.controllers, required this.info});

  factory SwaggerServer.fromMeta(
    RevaliContext context,
    MetaServer server,
    SwaggerSettings settings,
    SchemaRegistry registry,
  ) {
    var title = settings.title;
    var version = settings.version;
    var description = settings.description;

    for (final app in server.apps) {
      if (context.flavor != null &&
          app.appAnnotation.flavor != context.flavor) {
        continue;
      }

      app.annotationsFor(
        onMatch: [
          OnMatch(
            classType: ApiInfo,
            package: 'revali_swagger_annotations',
            convert: (object, annotation) {
              title = object.getField('title')?.toStringValue() ?? title;
              version = object.getField('version')?.toStringValue() ?? version;
              description =
                  object.getField('description')?.toStringValue() ??
                  description;
            },
          ),
        ],
      );

      break;
    }

    return SwaggerServer(
      info: SwaggerInfo(
        title: title,
        version: version,
        description: description,
      ),
      controllers: server.routes
          .map((r) => SwaggerController.fromMeta(r, registry))
          .toList(),
    );
  }

  final List<SwaggerController> controllers;
  final SwaggerInfo info;

  Iterable<SwaggerController> get visibleControllers =>
      controllers.where((c) => !c.isHidden && c.hasVisibleMethods);
}
