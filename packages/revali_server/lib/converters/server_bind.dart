import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerBind with ExtractImport {
  ServerBind({
    required this.bind,
    required this.reflect,
  });

  factory ServerBind.fromType(DartType type) {
    ServerReflect? reflect;

    if (type.element case final ClassElement element?) {
      final superBind = element.allSupertypes.firstWhereOrNull((element) {
        // ignore: unnecessary_parenthesis
        return element.element.name == (Bind).name;
      });

      final firstTypeArg = superBind?.typeArguments.first;

      if (firstTypeArg?.element case final ClassElement element) {
        reflect = ServerReflect.fromElement(element);
      }
    }

    return ServerBind(
      bind: ServerClass.fromType(type, superType: Bind),
      reflect: reflect,
    );
  }

  final ServerClass bind;
  final ServerReflect? reflect;

  @override
  List<ExtractImport> get extractors => [bind];

  @override
  List<ServerImports> get imports => const [];
}
