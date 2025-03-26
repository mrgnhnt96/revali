import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_app.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_parent_route.dart';
import 'package:revali_server/converters/server_public.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerServer with ExtractImport {
  ServerServer({
    required this.routes,
    required this.apps,
    required this.public,
    required this.context,
  });

  factory ServerServer.fromMeta(RevaliContext context, MetaServer server) {
    return ServerServer(
      context: context,
      routes: [
        for (final (index, route) in server.routes.indexed)
          ServerParentRoute.fromMeta(route, index),
      ],
      apps: server.apps.map(ServerApp.fromMeta).toList(),
      public: server.public.map(ServerPublic.fromMeta).toList(),
    );
  }

  final List<ServerParentRoute> routes;
  final List<ServerApp> apps;
  final List<ServerPublic> public;
  final RevaliContext context;

  List<ServerLifecycleComponent> get lifecycleComponents {
    final app = this.app;
    if (app == null) {
      return [];
    }

    final all = [
      ...app.globalRouteAnnotations.lifecycleComponents,
    ];

    for (final route in routes) {
      all.addAll(route.annotations.lifecycleComponents);

      for (final sub in route.routes) {
        all.addAll(sub.annotations.lifecycleComponents);
      }
    }

    final uniques = {
      for (final component in all) component.name: component,
    };

    return uniques.values.toList();
  }

  ServerApp? get app {
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
    _validateApp();
    _validateRoutes();
  }

  void _validateRoutes() {
    final uniquePaths = <String>{};

    for (final route in routes) {
      if (uniquePaths.contains(route.routePath)) {
        throw Exception('Duplicate route: ${route.routePath}');
      }

      uniquePaths.add(route.routePath);
    }
  }

  void _validateApp() {
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
        'No app found, did you forget pass the '
        '--flavor arg?\n$configuredFlavors',
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

  Iterable<ServerReflect> get reflects sync* {
    for (final route in routes) {
      yield* route.reflects.where((e) => e.isValid);
    }
  }

  @override
  List<ExtractImport?> get extractors => [
        ...routes,
        ...lifecycleComponents,
        app,
      ];

  @override
  List<ServerImports?> get imports => const [];
}
