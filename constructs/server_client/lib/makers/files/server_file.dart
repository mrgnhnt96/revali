import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client/makers/creators/create_server_content.dart';
import 'package:server_client/models/client_server.dart';

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
