import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/files/controller_interface_file.dart';
import 'package:server_client_gen/models/client_server.dart';

DartFile interfaceFile(
  ClientServer server,
  String Function(Spec) formatter,
) {
  return DartFile(
    basename: 'interfaces',
    content: '',
    parts: [
      for (final controller in server.controllers)
        controllerInterfaceFile(controller, formatter),
    ],
    segments: ['lib'],
  );
}
