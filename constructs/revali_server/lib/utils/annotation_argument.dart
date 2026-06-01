// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/dart_object_to_source.dart';
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

  factory AnnotationArgument.fromExpression(
    Expression expression, {
    String? annotationContext,
    String? knownNamedParameter,
    bool? knownIsRequired,
  }) {
    final source = expression.toSource();
    final type = expression.staticType;
    final element = type?.element;

    if (element == null || type == null) {
      throw ArgumentError(
        'The argument expression has not been resolved yet '
        '(${_describeExpression(expression)}'
        '${_annotationSuffix(annotationContext)})',
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

    final resolved = _resolveParameterName(
      expression,
      knownNamedParameter: knownNamedParameter,
      knownIsRequired: knownIsRequired,
    );
    if (resolved == null) {
      throw ArgumentError(
        'Could not determine the parameter name for an annotation argument '
        '(${_describeExpression(expression)}'
        '${_annotationSuffix(annotationContext)}). '
        'Ancestor chain: ${_ancestorChain(expression)}',
      );
    }

    final (name: parameterName, isRequired: isRequired) = resolved;

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

  /// Creates an [AnnotationArgument] from a field value read from a const
  /// instance via [DartObject.getField]. Used for initializer list values
  /// (fields assigned after `:` in constructors like `const Auth.admin() :
  /// requireAdmin = true`).
  factory AnnotationArgument.fromFieldValue(
    String fieldName,
    DartObject value,
    FieldElement fieldElement,
  ) {
    return AnnotationArgument(
      parameterName: fieldName,
      type: ServerType.fromType(fieldElement.type),
      isRequired: true,
      source: dartObjectToSource(value),
      element: fieldElement,
      isInjectable: false,
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

typedef _ResolvedParameter = ({String name, bool isRequired});

_ResolvedParameter? _resolveParameterName(
  Expression expression, {
  String? knownNamedParameter,
  bool? knownIsRequired,
}) {
  if (knownNamedParameter case final name?) {
    return (name: name, isRequired: knownIsRequired ?? false);
  }

  AstNode? node = expression;
  while (node != null) {
    if (node case Expression(correspondingParameter: final param?)) {
      return (
        name: param.name ?? (throw Exception('Parameter name is null')),
        isRequired: param.isRequiredNamed,
      );
    }
    if (node case NamedExpression(name: Label(:final label))) {
      return (name: label.name, isRequired: false);
    }
    node = node.parent;
  }

  return null;
}

String _describeExpression(Expression expression) {
  final location = _expressionLocation(expression);
  final locationSuffix = location == null ? '' : ' at $location';
  return '`${expression.toSource()}` '
      '(${expression.runtimeType})$locationSuffix';
}

String? _expressionLocation(Expression expression) {
  try {
    final root = expression.root;
    if (root is! CompilationUnit) {
      return null;
    }

    final location = root.lineInfo.getLocation(expression.offset);
    return '${location.lineNumber}:${location.columnNumber}';
  } on Object {
    return null;
  }
}

String _ancestorChain(Expression expression) {
  final parts = <String>[];
  AstNode? node = expression;

  while (node != null) {
    parts.add('${node.runtimeType}(`${node.toSource()}`)');
    node = node.parent;
  }

  return parts.join(' → ');
}

String _annotationSuffix(String? annotationContext) {
  if (annotationContext == null) {
    return '';
  }

  return ' in $annotationContext';
}
