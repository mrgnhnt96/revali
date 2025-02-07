import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client/makers/files/interface_file.dart';
import 'package:server_client/makers/files/server_file.dart';
import 'package:server_client/models/client_server.dart';

List<DartFile> interfaceFiles(
  ClientServer server,
  String Function(Spec) formatter,
) {
  return [
    for (final controller in server.controllers)
      ...interfaceFile(controller, formatter),
    serverInterfaceFile(server, formatter),
  ];
}
