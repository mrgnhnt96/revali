import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/files/controller_impl_file.dart';
import 'package:server_client_gen/makers/files/server_file.dart';
import 'package:server_client_gen/models/client_server.dart';

DartFile implementationFile(
  ClientServer server,
  String Function(Spec) formatter,
) {
  return DartFile(
    // TODO(mrgnhnt): replace with package name
    basename: 'server_client',
    parts: [
      for (final controller in server.controllers)
        controllerImplFile(controller, formatter),
      serverInterfaceFile(server, formatter),
    ],
    content: '',
    segments: ['lib'],
  );
}
