import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/makers/files/interface_file.dart';
import 'package:server_client_gen/makers/files/pubspec_file.dart';
import 'package:server_client_gen/makers/files/server_client_file.dart';
import 'package:server_client_gen/models/client_server.dart';

class ServerClient extends Construct {
  const ServerClient();

  @override
  RevaliDirectory generate(
    covariant RevaliContext context,
    MetaServer server,
  ) {
    final client = ClientServer.fromMeta(server);

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      return formatter.format(spec.accept(emitter).toString());
    }

    final files = [
      interfaceFile(client, format),
      serverClientFile(client, format),
      pubspecFile(client),
    ];

    return RevaliDirectory(files: files);
  }
}
