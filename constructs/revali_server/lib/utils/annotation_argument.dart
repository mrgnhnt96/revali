// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class AnnotationArgument with ExtractImport {
  AnnotationArgument({
    required this.source,
    required this.element,
    required this.isInjectable,
    required this.type,
    required this.isRequired,
    required this.isNullable,
    required this.parameterName,
  });

  factory AnnotationArgument.fromExpression(Expression expression) {
    final source = expression.toSource();
    final element = expression.staticType?.element;

    var isInjectable = false;
    final parents = switch (element) {
      ClassElement(:final allSupertypes) => [...allSupertypes],
      _ => <InterfaceType>[],
    };
    while (parents.isNotEmpty) {
      final parent = parents.removeLast();
      if (parent is ClassElement) continue;

      if (parent.getDisplayString() == (Inject).name) {
        isInjectable = true;
        break;
      }
    }

    String typeName;

    String parameterName;
    bool isRequired;
    bool isNullable;

    if (expression.parent
        case Expression(correspondingParameter: final param?)) {
      parameterName = param.name;
      typeName = param.type.getDisplayString();
      isRequired = param.isRequiredNamed;
      isNullable = param.type.nullabilitySuffix == NullabilitySuffix.question;
    } else if (expression
        case Expression(staticParameterElement: final param?)) {
      parameterName = param.name;
      typeName = param.type.getDisplayString();
      isRequired = param.isRequiredNamed;
      isNullable = param.type.nullabilitySuffix == NullabilitySuffix.question;
    } else {
      throw ArgumentError('Invalid expression');
    }

    return AnnotationArgument(
      parameterName: parameterName,
      type: ServerType(
        name: typeName,
        hasFromJsonConstructor: false,
        importPath: ServerImports.fromElements([element]),
      ),
      isRequired: isRequired,
      isNullable: isNullable,
      source: source,
      element: element,
      isInjectable: isInjectable,
    );
  }

  final String parameterName;
  final ServerType type;
  final bool isRequired;
  final bool isNullable;
  final String source;
  final Element? element;

  /// Whether the argument should be injected from DI
  ///
  /// The class should extend [Inject]
  final bool isInjectable;

  @override
  List<ExtractImport?> get extractors => [type];

  @override
  List<ServerImports?> get imports => [];
}
