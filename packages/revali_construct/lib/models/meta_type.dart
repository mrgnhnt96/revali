import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_construct/models/meta_record_prop.dart';
import 'package:revali_construct/utils/dart_type_extensions.dart';
import 'package:revali_construct/utils/element_extensions.dart';

class MetaType {
  const MetaType({
    required this.name,
    required this.hasFromJsonConstructor,
    required this.importPath,
    required this.isNullable,
    required this.element,
    required this.iterableType,
    required this.isRecord,
    required this.isStream,
    required this.isFuture,
    required this.typeArguments,
    required this.recordProps,
    required this.isVoid,
    required this.isPrimitive,
    required this.isDynamic,
    required this.isMap,
    required this.hasToJsonMember,
  });

  factory MetaType.fromType(DartType type) {
    return MetaType(
      name: type.getDisplayString(),
      isVoid: type is VoidType,
      hasFromJsonConstructor: type.element?.hasFromJsonConstructor ?? false,
      hasToJsonMember: type.element?.hasToJsonMember ?? false,
      importPath: type.element?.importPath,
      element: type.element,
      isNullable: (type.nullabilitySuffix != NullabilitySuffix.none) ^
          (type is DynamicType),
      iterableType: switch (type) {
        final InterfaceType type => IterableType.fromType(type),
        _ => null,
      },
      isRecord: type is RecordType,
      isStream: type.isStream,
      isFuture: type.isFuture,
      isDynamic: type is DynamicType,
      typeArguments: switch (type) {
        InterfaceType(typeArguments: final args) when args.isNotEmpty =>
          args.map(MetaType.fromType).toList(),
        _ => [],
      },
      recordProps: switch (type) {
        final RecordType recordType =>
          MetaRecordProp.fromRecordType(recordType).toList(),
        _ => null,
      },
      isPrimitive: type.isPrimitive,
      isMap: type.isDartCoreMap,
    );
  }

  final String name;
  final bool hasFromJsonConstructor;
  final bool hasToJsonMember;
  final String? importPath;
  final bool isNullable;
  final IterableType? iterableType;
  final bool isRecord;
  final bool isStream;
  final bool isFuture;
  final bool isVoid;
  final bool isPrimitive;
  final bool isMap;
  final bool isDynamic;
  final List<MetaType> typeArguments;
  final Element? element;
  final List<MetaRecordProp>? recordProps;
}
