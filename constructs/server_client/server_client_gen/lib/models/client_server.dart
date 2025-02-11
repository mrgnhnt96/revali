import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/utils/extract_import.dart';
import 'package:server_client_gen/models/client_controller.dart';
import 'package:server_client_gen/models/client_imports.dart';

class ClientServer with ExtractImport {
  ClientServer({
    required this.controllers,
  });

  factory ClientServer.fromMeta(MetaServer server) {
    return ClientServer(
      controllers: server.routes.map(ClientController.fromMeta).toList(),
    );
  }

  final List<ClientController> controllers;

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
