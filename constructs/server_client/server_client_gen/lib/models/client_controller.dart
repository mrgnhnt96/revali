import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/models/client_method.dart';

class ClientController {
  const ClientController({
    required this.name,
    required this.methods,
  });

  factory ClientController.fromMeta(MetaRoute route) {
    return ClientController(
      name: route.className,
      methods: route.methods.map(ClientMethod.fromMeta).toList(),
    );
  }

  final String name;
  String get interfaceName {
    return name.replaceAll('Controller', '');
  }

  String get implementationName => '${interfaceName}Impl';

  final List<ClientMethod> methods;
}
