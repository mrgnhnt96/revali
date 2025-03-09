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
  });

  factory ServerParam.fromMeta(MetaParam param) {
    final importPath = ServerImports.fromElement(param.type.element);
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
    );
  }

  factory ServerParam.fromElement(ParameterElement element) {
    final importPath = ServerImports.fromElement(element);

    final paramAnnotations = ServerParamAnnotations.fromElement(element);

    return ServerParam(
      name: element.name,
      type: ServerType.fromElement(element),
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
  final String? defaultValue;
  final bool hasDefaultValue;
  final ServerImports? importPath;
  final ServerParamAnnotations annotations;
  String? _literalValue;
  String? get literalValue => _literalValue;
  set literalValue(String? value) {
    assert(_literalValue == null, 'Literal value already set');

    _literalValue = value;
  }

  @override
  List<ExtractImport?> get extractors => [annotations, type];

  @override
  List<ServerImports?> get imports => [importPath];

  @Deprecated('use type.importPath')
  ServerImports? get typeImport => type.importPath;

  bool get hasLiteralValue => literalValue != null;
}
