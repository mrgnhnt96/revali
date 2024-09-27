import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerCustomParam with ExtractImport {
  ServerCustomParam({
    required this.customParam,
    required this.reflect,
  });

  factory ServerCustomParam.fromType(DartType type) {
    ServerReflect? reflect;

    if (type.element case final ClassElement element?) {
      final superCustomParam =
          element.allSupertypes.firstWhereOrNull((element) {
        // ignore: unnecessary_parenthesis
        return element.element.name == (CustomParam).name;
      });

      final firstTypeArg = superCustomParam?.typeArguments.first;

      if (firstTypeArg?.element case final ClassElement element) {
        reflect = ServerReflect.fromElement(element);
      }
    }

    return ServerCustomParam(
      customParam: ServerClass.fromType(type, superType: CustomParam),
      reflect: reflect,
    );
  }

  final ServerClass customParam;
  final ServerReflect? reflect;

  @override
  List<ExtractImport> get extractors => [customParam];

  @override
  List<ServerImports> get imports => const [];
}
