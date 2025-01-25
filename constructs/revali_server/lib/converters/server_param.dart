import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerParam with ExtractImport {
  ServerParam({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.importPath,
    required this.annotations,
    required this.typeImport,
  });

  factory ServerParam.fromMeta(MetaParam param) {
    final importPath = ServerImports.fromElement(param.typeElement);
    final paramAnnotations = ServerParamAnnotations.fromMeta(param);
    final type = ServerType.fromMeta(param.type);

    return ServerParam(
      name: param.name,
      type: type,
      isNullable: param.nullable,
      isRequired: param.isRequired,
      isNamed: param.isNamed,
      defaultValue: param.defaultValue,
      hasDefaultValue: param.hasDefaultValue,
      importPath: importPath,
      annotations: paramAnnotations,
      typeImport: ServerImports([
        if (param.typeImport case final String path) path,
      ]),
    );
  }

  factory ServerParam.fromElement(ParameterElement element) {
    final importPath = ServerImports.fromElement(element);

    final paramAnnotations = ServerParamAnnotations.fromElement(element);
    final typeImport = ServerImports.fromElement(element.type.element);

    return ServerParam(
      name: element.name,
      type: ServerType.fromElement(element),
      typeImport: typeImport,
      isNullable: element.type.nullabilitySuffix == NullabilitySuffix.question,
      isRequired: element.isRequiredNamed,
      isNamed: element.isNamed,
      defaultValue: element.defaultValueCode,
      hasDefaultValue: element.hasDefaultValue,
      importPath: importPath,
      annotations: paramAnnotations,
    );
  }

  final String name;
  final ServerType type;
  final bool isNullable;
  final bool isRequired;
  final bool isNamed;
  final ServerImports? typeImport;
  final String? defaultValue;
  final bool hasDefaultValue;
  final ServerImports? importPath;
  final ServerParamAnnotations annotations;

  @override
  List<ExtractImport?> get extractors => [annotations];

  @override
  List<ServerImports?> get imports => [importPath, typeImport];
}
