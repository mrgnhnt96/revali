// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_imports.dart';
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
    required this.isIterableNullable,
    required this.isPrimitive,
    required this.isStringContent,
    required this.hasToJsonMember,
    required this.isMap,
  });

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
      isIterableNullable: false,
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
  final bool isIterableNullable;
  final bool isPrimitive;
  final bool isStringContent;
  final bool hasToJsonMember;
  final bool isMap;

  @override
  List<ExtractImport?> get extractors => [];

  @override
  List<ServerImports?> get imports => [importPath];
}
