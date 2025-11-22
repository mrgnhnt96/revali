// ignore_for_file: overridden_fields

import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerReflect with ExtractImport {
  ServerReflect({
    required this.className,
    required this.importPath,
    required this.metas,
  });

  static ServerReflect? fromElement(Element? element) {
    if (element == null) {
      return null;
    }

    if (element is! ClassElement) {
      return null;
    }

    if (element.library.isInSdk) {
      return null;
    }

    final className = element.displayName;

    final importPath = element.importPath;

    final metas = <String, List<ServerMimic>>{};

    for (final field in element.fields) {
      getAnnotations(
        element: field,
        onMatch: [
          OnMatch(
            classType: MetaData,
            package: 'revali_router_annotations',
            convert: (object, annotation) {
              final meta = ServerMimic.fromDartObject(object, annotation);
              if (field.name3 case final String name) {
                (metas[name] ??= []).add(meta);
              }
            },
          ),
        ],
      );
    }

    return ServerReflect(
      className: className,
      importPath: ServerImports([if (importPath != null) importPath]),
      metas: metas,
    );
  }

  final String className;
  final ServerImports? importPath;
  final Map<String, List<ServerMimic>> metas;

  bool get hasReflects => metas.isNotEmpty;
  bool get isValid => hasReflects;

  @override
  List<ExtractImport?> get extractors => [...metas.values.expand((e) => e)];

  @override
  List<ServerImports?> get imports => [importPath];
}
