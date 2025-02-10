import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';

import '../../models/client_server.dart';
import 'implementation_file.dart';

List<DartFile> implementationFiles(
  ClientServer server,
  String Function(Spec) formatter,
) {
  return [
    for (final controller in server.controllers)
      ...implementationFile(controller, formatter),
  ];
}
