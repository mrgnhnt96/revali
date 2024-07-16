import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_app.dart';
import 'package:revali_server/converters/server_imports.dart';
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
      routes: server.routes.map((e) => ServerParentRoute.fromMeta(e)).toList(),
      apps: server.apps.map((e) => ServerApp.fromMeta(e)).toList(),
      public: server.public.map((e) => ServerPublic.fromMeta(e)).toList(),
    );
  }

  final List<ServerParentRoute> routes;
  final List<ServerApp> apps;
  final List<ServerPublic> public;
  final RevaliContext context;

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

  Iterable<ServerReflect> get reflects sync* {
    for (final route in routes) {
      yield* route.reflects.where((e) => e.isValid);
    }
  }

  @override
  List<ExtractImport?> get extractors => [
        ...routes,
        app,
      ];

  @override
  List<ServerImports?> get imports => const [];
}
