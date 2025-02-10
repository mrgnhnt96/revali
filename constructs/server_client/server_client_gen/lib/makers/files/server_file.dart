import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';

import '../../models/client_server.dart';
import '../creators/create_server_content.dart';

DartFile serverInterfaceFile(
  ClientServer client,
  String Function(Spec) formatter,
) {
  final content = createServerContent(client);

  return DartFile(
    basename: 'server',
    content: formatter(content),
    segments: ['lib', 'src'],
  );
}
