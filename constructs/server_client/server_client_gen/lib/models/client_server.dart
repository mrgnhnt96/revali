import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_app.dart';
import 'package:server_client_gen/models/client_controller.dart';
import 'package:server_client_gen/models/client_imports.dart';

class ClientServer with ExtractImport {
  ClientServer({
    required this.controllers,
    required this.app,
  });

  factory ClientServer.fromMeta(RevaliContext context, MetaServer server) {
    var app = ClientApp.defaultConfig();

    if (server.apps case final apps when apps.isNotEmpty) {
      final flavor = context.flavor;
      if ((flavor == null || flavor.isEmpty) && apps.length == 1) {
        app = ClientApp.fromMeta(apps.first);
      }

      for (final e in apps) {
        if (e.appAnnotation.flavor == context.flavor) {
          app = ClientApp.fromMeta(e);
          break;
        }
      }
    }

    return ClientServer(
      app: app,
      controllers: server.routes.map(ClientController.fromMeta).toList(),
    );
  }

  final List<ClientController> controllers;
  final ClientApp app;

  @override
  List<ExtractImport?> get extractors => [...controllers];

  @override
  List<ClientImports?> get imports => [];

  String allImports({
    Iterable<String> additionalPackages = const [],
    Iterable<String> additionalPaths = const [],
  }) {
    final packages = <String>[
      ...packageImports(),
      ...additionalPackages.where((e) => e.isNotEmpty),
    ]..sort();

    final paths = <String>[
      ...pathImports(),
      ...additionalPaths.where((e) => e.isNotEmpty),
    ]..sort();

    final imports = <String>[
      for (final import in packages) "import '$import';",
      '',
      for (final import in paths) "import '$import';",
    ];

    return imports.join('\n');
  }
}
