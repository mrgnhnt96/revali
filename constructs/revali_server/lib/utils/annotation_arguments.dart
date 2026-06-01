import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/utils/annotation_argument.dart';
import 'package:revali_server/utils/extract_import.dart';

class AnnotationArguments with ExtractImport {
  AnnotationArguments({required this.positional, required this.named});

  factory AnnotationArguments.fromDartObject(ElementAnnotation annotation) {
    final positionalArguments = <AnnotationArgument>[];
    final namedArguments = <String, AnnotationArgument>{};
    final annotationContext = switch (annotation) {
      ElementAnnotationImpl(annotationAst: final ast) => ast.toSource(),
      _ => annotation.element?.displayName,
    };

    if (annotation case ElementAnnotationImpl(
      annotationAst: Annotation(
        arguments: ArgumentList(childEntities: final args),
      ),
    )) {
      final positionalParameters = _positionalParameters(annotation);
      var positionalIndex = 0;

      for (final param in args) {
        if (param case NamedExpression(:final name, :final expression)) {
          namedArguments[name.label.name] = AnnotationArgument.fromExpression(
            expression,
            annotationContext: annotationContext,
            knownNamedParameter: name.label.name,
          );
        } else if (param case final Expression expression) {
          final knownParameter = positionalIndex < positionalParameters.length
              ? positionalParameters[positionalIndex]
              : null;
          positionalIndex++;

          positionalArguments.add(
            AnnotationArgument.fromExpression(
              expression,
              annotationContext: annotationContext,
              knownNamedParameter: knownParameter?.name,
              knownIsRequired: knownParameter?.isRequired,
            ),
          );
        }
      }
    }

    return AnnotationArguments(
      positional: positionalArguments,
      named: namedArguments,
    );
  }
  AnnotationArguments.none() : this(positional: [], named: {});

  Map<String, AnnotationArgument> get all {
    return {...named, for (final e in positional) e.parameterName: e};
  }

  final List<AnnotationArgument> positional;
  final Map<String, AnnotationArgument> named;

  bool get hasNamed => named.isNotEmpty;
  bool get hasPositional => positional.isNotEmpty;
  bool get hasArguments => hasNamed || hasPositional;
  bool get isEmpty => !hasArguments;

  @override
  List<ExtractImport?> get extractors => [...positional, ...named.values];

  @override
  List<ServerImports?> get imports => [];
}

typedef _PositionalParameter = ({String name, bool isRequired});

List<_PositionalParameter> _positionalParameters(ElementAnnotation annotation) {
  final element = annotation.element;
  if (element is! ConstructorElement) {
    return const [];
  }

  return [
    for (final parameter in element.formalParameters)
      if (parameter.isPositional)
        (name: parameter.name ?? '', isRequired: parameter.isRequired),
  ];
}
