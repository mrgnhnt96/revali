import 'package:analyzer/dart/element/element2.dart';
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
    this.isRequired = false,
    this.isNamed = false,
    this.defaultValue,
    this.hasDefaultValue = false,
    this.importPath,
    ServerParamAnnotations? annotations,
    AnnotationArgument? argument,
  }) : _argument = argument,
       annotations = annotations ?? ServerParamAnnotations.none();

  ServerParam._({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.importPath,
    required this.annotations,
    required AnnotationArgument? argument,
  }) : _argument = argument;

  factory ServerParam.fromMeta(MetaParam param) {
    final importPath = ServerImports.fromElement(param.type.element);
    final paramAnnotations = ServerParamAnnotations.fromMeta(param);
    final type = ServerType.fromMeta(param.type);

    return ServerParam._(
      name: param.name,
      type: type,
      isRequired: param.isRequired,
      isNamed: param.isNamed,
      defaultValue: param.defaultValue,
      hasDefaultValue: param.hasDefaultValue,
      importPath: importPath,
      annotations: paramAnnotations,
      argument: null,
    );
  }

  factory ServerParam.fromElement(FormalParameterElement element) {
    final importPath = ServerImports.fromElement(element);

    final paramAnnotations = ServerParamAnnotations.fromElement(element);

    final name = element.name3;
    if (name == null) {
      throw Exception('Parameter name is null');
    }

    return ServerParam(
      name: name,
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

  ServerParam copyWith({
    bool? isNamed,
    bool? isRequired,
    AnnotationArgument? argument,
  }) {
    return ServerParam._(
      name: name,
      type: type,
      isRequired: isRequired ?? this.isRequired,
      isNamed: isNamed ?? this.isNamed,
      defaultValue: defaultValue,
      hasDefaultValue: hasDefaultValue,
      importPath: importPath,
      annotations: annotations,
      argument: argument ?? this.argument,
    );
  }

  @override
  List<ExtractImport?> get extractors => [annotations, type];

  @override
  List<ServerImports?> get imports => [importPath];

  @Deprecated('use type.importPath')
  ServerImports? get typeImport => type.importPath;

  bool get hasArgument => argument != null;
}
