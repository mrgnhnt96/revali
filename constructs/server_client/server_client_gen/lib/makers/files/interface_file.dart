import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/files/controller_interface_file.dart';
import 'package:server_client_gen/models/client_server.dart';

DartFile interfaceFile(
  ClientServer server,
  String Function(Spec) formatter,
) {
  final imports = server.allImports(
    additionalPackages: ['package:server_client/server_client.dart'],
  );
  return DartFile(
    basename: 'interfaces',
    content: '''
$imports
''',
    parts: [
      for (final controller in server.controllers)
        controllerInterfaceFile(controller, formatter),
    ],
    segments: ['lib'],
  );
}
