import 'package:change_case/change_case.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_lifecycle_component.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

class ClientController with ExtractImport {
  ClientController({
    required this.name,
    required this.methods,
    required this.isExcluded,
  });

  factory ClientController.fromMeta(
    MetaRoute route,
    List<ClientLifecycleComponent> parentComponents,
  ) {
    final lifecycleComponents = <ClientLifecycleComponent>[...parentComponents];
    var isExcluded = false;

    route.annotationsFor(
      onMatch: [
        OnMatch(
          classType: LifecycleComponent,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            final component = ClientLifecycleComponent.fromDartObject(
              annotation,
            );

            lifecycleComponents.add(component);
          },
        ),
        OnMatch(
          classType: ExcludeFromClient,
          package: 'revali_client',
          convert: (object, annotation) {
            isExcluded = true;
          },
        ),
      ],
    );

    return ClientController(
      name: route.className,
      isExcluded: isExcluded,
      methods: route.methods
          .map((e) => ClientMethod.fromMeta(e, route.path, lifecycleComponents))
          .toList(),
    );
  }

  final String name;
  final bool isExcluded;

  String get simpleName => name.replaceAll('Controller', '');
  String get interfaceName => '${simpleName}DataSource'.toPascalCase();
  String get implementationName => '${interfaceName}Impl';

  final List<ClientMethod> methods;

  @override
  List<ExtractImport?> get extractors => [
    ...methods.where((e) => !e.isExcluded),
  ];

  @override
  List<ClientImports?> get imports => [];

  bool get hasWebsockets => methods.any((e) {
    if (e.isExcluded) {
      return false;
    }

    return e.websocketType != WebsocketType.none;
  });
}
