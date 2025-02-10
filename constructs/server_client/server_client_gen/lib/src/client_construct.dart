import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';

import '../makers/files/implementation_files.dart';
import '../makers/files/interface_files.dart';
import '../makers/files/pubspec_file.dart';
import '../models/client_server.dart';

class ServerClient extends Construct {
  const ServerClient();

  @override
  RevaliDirectory<AnyFile> generate(
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

    return RevaliDirectory(
      files: [
        ...interfaceFiles(client, format),
        ...implementationFiles(client, format),
        pubspecFile(client),
      ],
    );
  }
}
