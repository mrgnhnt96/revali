// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerType with ExtractImport {
  ServerType({
    required this.name,
    required this.hasFromJsonConstructor,
    required this.importPath,
    required this.isVoid,
    required this.reflect,
    required this.isFuture,
    required this.isStream,
    required this.iterableType,
    required this.isNullable,
    required this.isPrimitive,
    required this.isStringContent,
    required this.hasToJsonMember,
    required this.isMap,
    required List<ServerType> typeArguments,
    required this.recordProps,
    required this.isRecord,
  }) : _typeArguments = List.unmodifiable(typeArguments);

  factory ServerType.fromMeta(MetaType type) {
    return ServerType(
      name: type.name,
      hasFromJsonConstructor: type.hasFromJsonConstructor,
      importPath: ServerImports([
        if (type.importPath case final String path) path,
      ]),
      isVoid: type.isVoid,
      reflect: switch (type.element) {
        final Element element => ServerReflect.fromElement(element),
        _ => null,
      },
      isFuture: type.isFuture,
      isStream: type.isStream,
      iterableType: type.iterableType,
      isNullable: type.isNullable,
      isPrimitive: type.isPrimitive,
      isStringContent: switch (type.element) {
        ClassElement(:final name, :final allSupertypes) =>
          name == (StringContent).name ||
              allSupertypes.any(
                (e) => e.getDisplayString() == (StringContent).name,
              ),
        _ => false,
      },
      hasToJsonMember: type.element?.hasToJsonMember ?? false,
      isMap: type.isMap,
      typeArguments: type.typeArguments.map(ServerType.fromMeta).toList(),
      recordProps: type.recordProps?.map(ServerRecordProp.fromMeta).toList(),
      isRecord: type.isRecord,
    );
  }

  factory ServerType.fromType(DartType type) {
    return ServerType.fromMeta(MetaType.fromType(type));
  }

  final String name;
  final bool hasFromJsonConstructor;
  final ServerImports? importPath;
  final bool isVoid;
  final ServerReflect? reflect;
  final bool isFuture;
  final bool isStream;
  final IterableType? iterableType;
  final bool isNullable;
  final bool isPrimitive;
  final bool isStringContent;
  final bool hasToJsonMember;
  final bool isRecord;
  final bool isMap;
  final List<ServerType> _typeArguments;
  final List<ServerRecordProp>? recordProps;

  List<ServerType> get typeArguments => List.unmodifiable([
        for (final arg in _typeArguments) arg.._parent = this,
      ]);

  ServerType? _parent;
  ServerType? get parent => _parent;

  ServerType get root {
    if (parent == null) return this;

    var current = parent;
    while (true) {
      if (current == null) return this;

      if (current.parent == null) return current;

      current = current.parent;
    }
  }

  bool get isBytes {
    bool isBytes(String name) {
      return switch (name) {
        'List<int>' || 'List<int>?' => true,
        'List<List<int>>' || 'List<List<int>>?' => true,
        _ => false,
      };
    }

    final root = this.root;

    if (root.name == name && isBytes(name)) {
      return true;
    }

    bool iterate(ServerType type) {
      if (isBytes(type.name)) {
        return true;
      }

      return type.typeArguments.any(iterate);
    }

    return iterate(root);
  }

  @override
  List<ExtractImport?> get extractors => [
        ...typeArguments,
        ...?recordProps,
      ];

  @override
  List<ServerImports?> get imports => [importPath];
}
