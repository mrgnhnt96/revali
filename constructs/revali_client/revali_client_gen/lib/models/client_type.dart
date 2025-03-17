// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';

class ClientType with ExtractImport {
  ClientType({
    required this.name,
    required this.hasFromJsonConstructor,
    required this.import,
    required this.isNullable,
    required this.iterableType,
    required this.isRecord,
    required this.isStream,
    required this.isFuture,
    required List<ClientType> typeArguments,
    required this.recordProps,
    required this.isVoid,
    required this.isPrimitive,
    required this.isDynamic,
    required this.isMap,
    required this.isStringContent,
  }) : _typeArguments = typeArguments;

  ClientType.map()
      : name = 'Map<String, dynamic>',
        import = ClientImports([]),
        isVoid = false,
        isStream = false,
        isFuture = false,
        isStringContent = false,
        isPrimitive = false,
        hasFromJsonConstructor = false,
        isNullable = false,
        iterableType = null,
        isRecord = false,
        recordProps = null,
        isDynamic = false,
        isMap = true,
        _typeArguments = [];

  factory ClientType.fromMeta(MetaType type) {
    var import =
        ClientImports([if (type.importPath case final String path) path]);

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
      isStringContent: isStringContent,
      isPrimitive: type.isPrimitive,
      iterableType: type.iterableType,
      isRecord: type.isRecord,
      recordProps: type.recordProps?.map(ClientRecordProp.fromMeta).toList(),
      isDynamic: type.isDynamic,
      isMap: type.isMap,
      hasFromJsonConstructor: type.hasFromJsonConstructor,
      isNullable: type.isNullable,
      typeArguments: type.typeArguments.map(ClientType.fromMeta).toList(),
    );
  }

  factory ClientType.fromElement(ParameterElement element) {
    return ClientType.fromMeta(MetaType.fromType(element.type));
  }

  final String name;
  final bool hasFromJsonConstructor;
  final ClientImports? import;
  final bool isNullable;
  final IterableType? iterableType;
  final bool isRecord;
  final bool isStream;
  final bool isFuture;
  final bool isVoid;
  final bool isPrimitive;
  final bool isMap;
  final bool isDynamic;
  final bool isStringContent;
  final List<ClientType> _typeArguments;
  final List<ClientRecordProp>? recordProps;

  List<ClientType> get typeArguments => List.unmodifiable([
        for (final arg in _typeArguments) arg..parent = this,
      ]);

  ClientType? parent;

  ClientType get root {
    if (parent == null) return this;

    var current = parent;
    while (true) {
      if (current == null) return this;

      if (current.parent == null) return current;

      current = current.parent;
    }
  }

  bool get isIterable => iterableType != null;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ClientImports?> get imports => [import];
}
