import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerClass with ExtractImport {
  ServerClass({
    required this.className,
    required this.params,
    required this.importPath,
  });

  factory ServerClass.fromType(
    DartType type, {
    required Type superType,
  }) {
    final className = type.getDisplayString(withNullability: false);
    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element',
      );
    }

    final superTypeWithoutGenerics = '$superType'.split('<').first;

    if (!element.allSupertypes.any(
      (e) => e
          .getDisplayString(withNullability: false)
          .startsWith(superTypeWithoutGenerics),
    )) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element that extends $superType',
      );
    }

    if (element.constructors.isEmpty) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element with a constructor',
      );
    }

    final constructor = element.constructors.first;

    final params = constructor.parameters.map((param) {
      return ServerParam.fromElement(param);
    });

    final uri = element.librarySource.uri.toString();

    final imports = ServerImports([uri]);

    return ServerClass(
      className: className,
      params: params,
      importPath: imports,
    );
  }
  final String className;
  final Iterable<ServerParam> params;
  final ServerImports importPath;

  @override
  List<ExtractImport> get extractors => [...params];

  @override
  List<ServerImports> get imports => [importPath];
}
