import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client/makers/files/implementation_file.dart';
import 'package:server_client/models/client_server.dart';

List<DartFile> implementationFiles(
  ClientServer server,
  String Function(Spec) formatter,
) {
  return [
    for (final controller in server.controllers)
      ...implementationFile(controller, formatter),
  ];
}
