import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/models/client_server.dart';

AnyFile pubspecFile(ClientServer server) {
  final websocket = switch (server.hasWebsockets) {
    true => '''
  web_socket_channel:
''',
    false => ''
  };

  // TODO: Leverage options to set properties
  return AnyFile(
    basename: 'pubspec',
    extension: 'yaml',
    content: '''
name: client_server
description: A client server for the server.

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  # TODO(mrgnhnt): Add dynamic dependencies
  http: ^1.3.0
  client_gen_models:
    path: ../../models
  server_client:
    path: ../../../../constructs/server_client/server_client

$websocket
''',
  );
}
