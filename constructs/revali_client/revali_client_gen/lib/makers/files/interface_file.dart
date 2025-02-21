import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/files/controller_interface_file.dart';
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_construct/revali_construct.dart';

DartFile interfaceFile(
  ClientServer server,
  String Function(Spec) formatter,
) {
  final imports = server.allImports(
    additionalPackages: ['package:revali_client/revali_client.dart'],
  );
  return DartFile(
    basename: 'interfaces',
    content: '''
$imports
export 'package:revali_client/src/storage.dart';
''',
    parts: [
      for (final controller in server.controllers)
        controllerInterfaceFile(controller, formatter),
    ],
    segments: ['lib'],
  );
}
