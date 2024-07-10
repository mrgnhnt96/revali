import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_app.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_parent_route.dart';
import 'package:revali_shelf/converters/shelf_reflect.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfServer with ExtractImport {
  ShelfServer({
    required this.routes,
    required this.apps,
    required this.context,
  });

  factory ShelfServer.fromMeta(RevaliContext context, MetaServer server) {
    return ShelfServer(
      context: context,
      routes: server.routes.map((e) => ShelfParentRoute.fromMeta(e)).toList(),
      apps: server.apps.map((e) => ShelfApp.fromMeta(e)).toList(),
    );
  }

  final List<ShelfParentRoute> routes;
  final List<ShelfApp> apps;
  final RevaliContext context;

  ShelfApp? get app {
    if (apps.isEmpty) {
      throw Exception('No apps found');
    }

    final flavor = context.flavor;
    if ((flavor == null || flavor.isEmpty) && apps.length == 1) {
      return apps.first;
    }

    for (final app in apps) {
      if (app.appAnnotation.flavor == context.flavor) {
        return app;
      }
    }

    return null;
  }

  void validate() {
    if (app != null) {
      return;
    }

    final configuredFlavors = 'Configured Flavors:'
        '\n\t- ${apps.map((e) => e.appAnnotation.flavor).join('\n\t- ')}';

    if (context.flavor case final flavor? when flavor.isNotEmpty) {
      throw Exception(
        'No app found for flavor "$flavor"\n$configuredFlavors',
      );
    }

    if (context.flavor == null) {
      throw Exception(
        'No app found, did you forget pass the --flavor arg?\n$configuredFlavors',
      );
    }

    throw Exception(
      [
        'No app found',
        'Flavor: ${context.flavor}',
        configuredFlavors,
      ].join('\n'),
    );
  }

  Iterable<ShelfReflect> get reflects sync* {
    for (final route in routes) {
      yield* route.reflects;
    }
  }

  @override
  List<ExtractImport?> get extractors => [
        ...routes,
        app,
      ];

  @override
  List<ShelfImports?> get imports => const [];
}
