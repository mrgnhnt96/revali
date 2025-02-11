import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/creators/create_server_content.dart';
import 'package:server_client_gen/models/client_server.dart';

PartFile serverFile(
  ClientServer client,
  String Function(Spec) formatter,
) {
  final content = createServerContent(client);

  return PartFile(
    content: formatter(content),
    path: ['lib', 'src', 'server'],
  );
}
