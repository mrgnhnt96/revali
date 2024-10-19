import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerPipe with ExtractImport {
  ServerPipe({
    required this.pipe,
    required this.reflect,
  });

  factory ServerPipe.fromType(DartType type) {
    ServerReflect? reflect;

    if (type.element case final ClassElement element?) {
      final superPipe = element.allSupertypes.firstWhereOrNull((element) {
        // ignore: unnecessary_parenthesis
        return element.element.name == (Pipe).name;
      });

      final firstTypeArg = superPipe?.typeArguments.first;

      if (firstTypeArg?.element case final ClassElement element) {
        reflect = ServerReflect.fromElement(element);
      }
    }

    return ServerPipe(
      pipe: ServerClass.fromType(type, superType: Pipe),
      reflect: reflect,
    );
  }

  final ServerClass pipe;
  final ServerReflect? reflect;

  @override
  List<ExtractImport> get extractors => [pipe];

  @override
  List<ServerImports> get imports => const [];
}
