import 'package:revali_construct/revali_construct.dart';

import 'client_controller.dart';

class ClientServer {
  const ClientServer({
    required this.controllers,
  });

  factory ClientServer.fromMeta(MetaServer server) {
    return ClientServer(
      controllers: server.routes.map(ClientController.fromMeta).toList(),
    );
  }

  final List<ClientController> controllers;
}
