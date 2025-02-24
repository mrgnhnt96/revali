import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/files/controller_impl_file.dart';
import 'package:revali_client_gen/makers/files/server_file.dart';
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_client_gen/models/settings.dart';
import 'package:revali_construct/revali_construct.dart';

DartFile serverClientFile(
  ClientServer server,
  Settings settings,
  String Function(Spec) formatter,
) {
  final imports = server.allImports(
    additionalPackages: [
      'dart:convert',
      'package:revali_client/revali_client.dart',
      'package:http/http.dart',
      if (server.hasWebsockets)
        'package:web_socket_channel/web_socket_channel.dart',
      if (settings.integrateGetIt) 'package:get_it/get_it.dart',
    ],
    additionalPaths: ['interfaces.dart'],
  );

  return DartFile(
    basename: settings.packageName,
    parts: [
      for (final controller in server.controllers)
        controllerImplFile(controller, formatter),
      serverFile(server, formatter, settings),
    ],
    content: '''
$imports
''',
    segments: ['lib'],
  );
}
