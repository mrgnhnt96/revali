import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/models/client_app.dart';
import 'package:revali_client_gen/models/client_controller.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

class ClientServer with ExtractImport {
  ClientServer({
    required this.controllers,
    required this.app,
  });

  factory ClientServer.fromMeta(RevaliContext context, MetaServer server) {
    MetaAppConfig? metaApp;
    var app = ClientApp.defaultConfig();

    if (server.apps case final apps when apps.isNotEmpty) {
      final flavor = context.flavor;
      if ((flavor == null || flavor.isEmpty) && apps.length == 1) {
        app = ClientApp.fromMeta(apps.first);
      }

      for (final e in apps) {
        if (e.appAnnotation.flavor == context.flavor) {
          app = ClientApp.fromMeta(e);
          metaApp = e;
          break;
        }
      }
    }

    final lifecycleComponents = <ClientLifecycleComponent>[];

    metaApp?.annotationsFor(
      onMatch: [
        OnMatch(
          classType: LifecycleComponent,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            final component =
                ClientLifecycleComponent.fromDartObject(annotation);

            lifecycleComponents.add(component);
          },
        ),
      ],
    );

    return ClientServer(
      app: app,
      controllers: server.routes
          .map((e) => ClientController.fromMeta(e, lifecycleComponents))
          .toList(),
    );
  }

  final List<ClientController> controllers;
  final ClientApp app;

  @override
  List<ExtractImport?> get extractors => [
        ...controllers.where((e) => !e.isExcluded),
      ];

  @override
  List<ClientImports?> get imports => [];

  bool get hasWebsockets =>
      controllers.any((e) => e.hasWebsockets && !e.isExcluded);

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
