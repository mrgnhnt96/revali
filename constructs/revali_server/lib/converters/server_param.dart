import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/utils/annotation_argument.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerParam with ExtractImport {
  ServerParam({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.importPath,
    required this.annotations,
    AnnotationArgument? argument,
  }) : _argument = argument;

  factory ServerParam.fromMeta(MetaParam param) {
    final importPath = ServerImports.fromElement(param.type.element);
    final paramAnnotations = ServerParamAnnotations.fromMeta(param);
    final type = ServerType.fromMeta(param.type);

    return ServerParam(
      name: param.name,
      type: type,
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
      type: ServerType.fromType(element.type),
      isRequired: element.isRequiredNamed || element.isRequiredPositional,
      isNamed: element.isNamed,
      defaultValue: element.defaultValueCode,
      hasDefaultValue: element.hasDefaultValue,
      importPath: importPath,
      annotations: paramAnnotations,
    );
  }

  final String name;
  final ServerType type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final bool hasDefaultValue;
  final ServerImports? importPath;
  final ServerParamAnnotations annotations;
  AnnotationArgument? _argument;
  AnnotationArgument? get argument => _argument;
  set argument(AnnotationArgument? value) {
    assert(_argument == null, 'Literal value already set');

    _argument = value;
  }

  @override
  List<ExtractImport?> get extractors => [annotations, type];

  @override
  List<ServerImports?> get imports => [importPath];

  @Deprecated('use type.importPath')
  ServerImports? get typeImport => type.importPath;

  bool get hasArgument => argument != null;
}
