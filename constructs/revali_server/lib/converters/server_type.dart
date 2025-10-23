// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_from_json.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_to_json.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerType with ExtractImport {
  ServerType({
    required this.name,
    this.fromJson,
    this.toJson,
    this.importPath,
    bool isVoid = false,
    this.reflect,
    this.isFuture = false,
    this.isStream = false,
    this.iterableType,
    this.isNullable = false,
    this.isPrimitive = false,
    this.isStringContent = false,
    this.hasToJsonMember = false,
    this.isMap = false,
    this.isDynamic = false,
    List<ServerType> typeArguments = const [],
    this.recordProps,
    this.isRecord = false,
    this.isEnum = false,
  }) : _typeArguments = List.unmodifiable(typeArguments),
       _isVoid = isVoid;

  ServerType._({
    required this.name,
    required this.fromJson,
    required this.toJson,
    required this.importPath,
    required bool isVoid,
    required this.reflect,
    required this.isFuture,
    required this.isStream,
    required this.iterableType,
    required this.isNullable,
    required this.isPrimitive,
    required this.isStringContent,
    required this.hasToJsonMember,
    required this.isMap,
    required this.isDynamic,
    required List<ServerType> typeArguments,
    required this.recordProps,
    required this.isRecord,
    required this.isEnum,
  }) : _typeArguments = List.unmodifiable(typeArguments),
       _isVoid = isVoid;

  factory ServerType.fromMeta(MetaType type) {
    return ServerType._(
      name: type.name,
      fromJson: ServerFromJson.fromMeta(type.fromJson),
      toJson: ServerToJson.fromMeta(type.toJson),
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
      isDynamic: type.isDynamic,
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
      isEnum: type.isEnum,
    );
  }

  factory ServerType.fromType(DartType type) {
    return ServerType.fromMeta(MetaType.fromType(type));
  }

  final String name;
  final ServerFromJson? fromJson;
  final ServerToJson? toJson;
  final ServerImports? importPath;
  final ServerReflect? reflect;
  final bool isFuture;
  final bool isStream;
  final IterableType? iterableType;
  final bool isNullable;
  final bool isPrimitive;
  final bool isStringContent;
  final bool isEnum;
  final bool hasToJsonMember;
  final bool isRecord;
  final bool isMap;
  final bool isDynamic;
  final List<ServerType> _typeArguments;
  final List<ServerRecordProp>? recordProps;

  bool get hasFromJson => fromJson != null;

  bool get isIterable => iterableType != null;

  final bool _isVoid;
  bool get isVoid {
    if (_isVoid) {
      return true;
    }

    return typeArguments.any((e) => e._isVoid);
  }

  ServerRoute? route;

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
    final pattern = RegExp(r'(?:List<){1,2}int(?:>\??){1,2}');
    bool isBytes(String name) {
      return pattern.hasMatch(name);
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
    reflect,
  ];

  @override
  List<ServerImports?> get imports => [importPath];

  String get nonNullName => name.replaceAll(RegExp(r'\?$'), '');

  ServerType get nonAsyncType {
    ServerType extract(ServerType type) {
      if (type case ServerType(isFuture: true)) {
        return extract(type.typeArguments.first);
      }

      return type;
    }

    return extract(this);
  }
}
