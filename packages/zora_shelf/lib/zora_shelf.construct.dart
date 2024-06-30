import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:zora_construct/models/files/server_file.dart';
import 'package:zora_construct/zora_construct.dart';
import 'package:zora_shelf/makers/register_controllers.dart';
import 'package:zora_shelf/makers/register_dependencies.dart';
import 'package:zora_shelf/makers/route_handlers.dart';
import 'package:zora_shelf/makers/server_file.dart';

class ZoraShelfConstruct implements ServerConstruct {
  const ZoraShelfConstruct();

  @override
  ServerFile generate(List<MetaRoute> routes) {
    final formatter = DartFormatter();
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    String format(Spec spec) {
      return formatter.format(spec.accept(emitter).toString());
    }

    return ServerFile(
      content: serverFile(routes, format),
      parts: [
        registerDependencies(format),
        registerControllers(format),
        ...routeHandlers(routes),
      ],
    );
  }
}
