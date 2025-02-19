import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/files/controller_impl_file.dart';
import 'package:server_client_gen/makers/files/server_file.dart';
import 'package:server_client_gen/models/client_server.dart';

DartFile serverClientFile(
  ClientServer server,
  String Function(Spec) formatter,
) {
  final imports = server.allImports(
    additionalPackages: [
      'dart:convert',
      'package:server_client/server_client.dart',
      'package:http/http.dart',
      if (server.hasWebsockets)
        'package:web_socket_channel/web_socket_channel.dart',
    ],
    additionalPaths: ['interfaces.dart'],
  );

  return DartFile(
    // TODO(mrgnhnt): replace with package name
    basename: 'server_client',
    parts: [
      for (final controller in server.controllers)
        controllerImplFile(controller, formatter),
      serverFile(server, formatter),
    ],
    content: '''
$imports
''',
    segments: ['lib'],
  );
}
