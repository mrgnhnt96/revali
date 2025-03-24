import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_server_content.dart';
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_client_gen/models/settings.dart';
import 'package:revali_construct/revali_construct.dart';

PartFile serverFile(
  ClientServer client,
  String Function(Spec) formatter,
  Settings settings,
) {
  final content = createServerContent(client, settings);

  return PartFile(
    content: formatter(content),
    path: ['lib', 'src', 'server'],
  );
}
