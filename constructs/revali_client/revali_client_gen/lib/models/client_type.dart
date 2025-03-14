// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';

class ClientType with ExtractImport {
  ClientType({
    required this.name,
    required this.import,
    required this.isVoid,
    required this.isStream,
    required this.isFuture,
    required this.fullName,
    required this.isStringContent,
    required this.isPrimitive,
    required this.isIterable,
    required this.resolvedName,
    required this.hasFromJsonConstructor,
  });

  ClientType.map()
      : name = 'Map<String, dynamic>',
        import = ClientImports([]),
        isVoid = false,
        isStream = false,
        isFuture = false,
        fullName = 'Map<String, dynamic>',
        isStringContent = false,
        isPrimitive = false,
        isIterable = false,
        resolvedName = 'Map<String, dynamic>',
        hasFromJsonConstructor = false;

  factory ClientType.fromMeta(MetaType type) {
    var import =
        ClientImports([if (type.importPath case final String path) path]);

    if (import.packages.isEmpty && import.paths.isNotEmpty) {
      return ClientType.map();
    }

    final (resolvedName, isStringContent) =
        switch (type.element?.name ?? type.name) {
      final e when e == (StringContent).name => ('String', true),
      final e => (e, false),
    };

    if (isStringContent) {
      import = ClientImports([]);
    }

    return ClientType(
      name: type.name,
      import: import,
      isVoid: type.isVoid,
      isStream: type.isStream,
      isFuture: type.isFuture,
      fullName: type.name,
      isStringContent: isStringContent,
      isPrimitive: type.isPrimitive,
      isIterable: type.iterableType != null,
      resolvedName: resolvedName,
      hasFromJsonConstructor: type.hasFromJsonConstructor,
    );
  }

  factory ClientType.fromElement(ParameterElement element) {
    final import = ClientImports.fromElement(element.type.element);

    if (import.packages.isEmpty && import.paths.isNotEmpty) {
      return ClientType.map();
    }

    final (resolvedName, isStringContent) =
        switch (element.type.element?.name ?? element.type.getDisplayString()) {
      final e when e == (StringContent).name => ('String', true),
      final e => (e, false),
    };

    return ClientType(
      name: element.type.getDisplayString(),
      import: import,
      isVoid: element.type is VoidType,
      isStream: false,
      isFuture: false,
      fullName: element.type.getDisplayString(),
      isStringContent: false,
      isPrimitive: false,
      isIterable: false,
      resolvedName: resolvedName,
      hasFromJsonConstructor:
          element.type.element?.hasFromJsonConstructor ?? false,
    );
  }

  final String name;
  final ClientImports import;
  final bool isVoid;
  final bool isStream;
  final bool isFuture;
  final String fullName;
  final bool isStringContent;
  final bool isPrimitive;
  final bool isIterable;
  final String resolvedName;
  final bool hasFromJsonConstructor;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
