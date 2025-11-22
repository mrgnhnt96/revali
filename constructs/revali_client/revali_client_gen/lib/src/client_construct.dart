import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_client_gen/makers/files/interface_file.dart';
import 'package:revali_client_gen/makers/files/pubspec_file.dart';
import 'package:revali_client_gen/makers/files/server_client_file.dart';
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_client_gen/models/settings.dart';
import 'package:revali_construct/revali_construct.dart';

class ServerClient extends Construct {
  const ServerClient(this.settings);

  final Settings settings;

  @override
  RevaliDirectory generate(covariant RevaliContext context, MetaServer server) {
    final client = ClientServer.fromMeta(context, server);

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      try {
        return formatter.format(spec.accept(emitter).toString());
      } catch (e) {
        // ignore: avoid_print
        print(e);
        rethrow;
      }
    }

    final files = [
      interfaceFile(client, format),
      serverClientFile(client, settings, format),
      pubspecFile(client, settings),
    ];

    return RevaliDirectory(files: files);
  }
}
