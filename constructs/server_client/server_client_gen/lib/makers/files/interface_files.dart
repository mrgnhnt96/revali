import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';

import '../../models/client_server.dart';
import 'interface_file.dart';
import 'server_file.dart';

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
