import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/makers/server_file.dart';

class revaliShelfConstruct implements ServerConstruct {
  const revaliShelfConstruct();

  @override
  ServerFile generate(MetaServer server) {
    final formatter = DartFormatter();
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      return formatter.format(spec.accept(emitter).toString());
    }

    return ServerFile(
      content: serverFile(server.routes, format),
      parts: [
        // registerDependencies(format),
        // registerControllers(format),
      ],
    );
  }
}
