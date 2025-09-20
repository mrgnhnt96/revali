// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/element/element2.dart';
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
    required this.parameterName,
  });

  factory AnnotationArgument.fromExpression(Expression expression) {
    final source = expression.toSource();
    final type = expression.staticType;
    final element = type?.element;

    if (element == null || type == null) {
      throw ArgumentError(
        'The argument expression has not been resolved yet...',
      );
    }

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

    String parameterName;
    bool isRequired;

    if (expression.parent case Expression(
      correspondingParameter: final param?,
    )) {
      parameterName =
          param.name3 ?? (throw Exception('Parameter name is null'));
      isRequired = param.isRequiredNamed;
    } else if (expression case Expression(
      correspondingParameter: final param?,
    )) {
      parameterName =
          param.name3 ?? (throw Exception('Parameter name is null'));
      isRequired = param.isRequiredNamed;
    } else if (expression.parent case NamedExpression(
      name: Label(:final label),
    )) {
      parameterName = label.name;
      isRequired = false;
    } else {
      throw ArgumentError('Invalid expression');
    }

    return AnnotationArgument(
      parameterName: parameterName,
      type: switch (expression.correspondingParameter?.type ??
          expression.staticType) {
        final e? => ServerType.fromType(e),
        _ => throw Exception('Expression has not been resolved yet...'),
      },
      isRequired: isRequired,
      source: source,
      element: element,
      isInjectable: isInjectable,
    );
  }

  final String parameterName;
  final ServerType type;
  final bool isRequired;
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
