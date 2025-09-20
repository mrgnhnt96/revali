import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerPipe with ExtractImport {
  ServerPipe({
    required this.clazz,
    required this.reflect,
    required this.convertFrom,
    required this.convertTo,
  });

  static ServerPipe? fromType(DartType? type) {
    if (type == null) {
      return null;
    }

    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(type, 'type', 'Expected a class element');
    }
    final superPipe = element.allSupertypes.firstWhereOrNull((element) {
      // ignore: unnecessary_parenthesis
      return element.element.name == (Pipe).name;
    });

    final typeArgs = superPipe?.typeArguments;
    if (typeArgs == null) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a pipe with two type arguments',
      );
    }

    final [first, second] = typeArgs;

    return ServerPipe(
      clazz: ServerClass.fromType(type, superType: Pipe),
      reflect: ServerReflect.fromElement(first.element),
      convertFrom: ServerType.fromType(first),
      convertTo: ServerType.fromType(second),
    );
  }

  final ServerClass clazz;
  final ServerReflect reflect;
  final ServerType convertFrom;
  final ServerType convertTo;

  @override
  List<ExtractImport> get extractors => [clazz, convertFrom, convertTo];

  @override
  List<ServerImports> get imports => const [];
}
