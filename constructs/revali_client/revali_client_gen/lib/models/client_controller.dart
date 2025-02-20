import 'package:change_case/change_case.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

class ClientController with ExtractImport {
  ClientController({
    required this.name,
    required this.methods,
  });

  factory ClientController.fromMeta(
    MetaRoute route,
    List<ClientLifecycleComponent> parentComponents,
  ) {
    final lifecycleComponents = <ClientLifecycleComponent>[
      ...parentComponents,
    ];

    route.annotationsFor(
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

    return ClientController(
      name: route.className,
      methods: route.methods
          .map((e) => ClientMethod.fromMeta(e, route.path, lifecycleComponents))
          .toList(),
    );
  }

  final String name;

  String get simpleName => name.replaceAll('Controller', '');
  String get interfaceName => '${simpleName}DataSource'.toPascalCase();
  String get implementationName => '${interfaceName}Impl';

  final List<ClientMethod> methods;

  @override
  List<ExtractImport?> get extractors => [...methods];

  @override
  List<ClientImports?> get imports => [];

  bool get hasWebsockets =>
      methods.any((e) => e.websocketType != WebsocketType.none);
}
