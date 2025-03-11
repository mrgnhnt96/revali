import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/utils/annotation_argument.dart';
import 'package:revali_server/utils/extract_import.dart';

class AnnotationArguments with ExtractImport {
  AnnotationArguments({
    required this.positional,
    required this.named,
  });

  factory AnnotationArguments.fromDartObject(
    ElementAnnotation annotation,
  ) {
    final positionalArguments = <AnnotationArgument>[];
    final namedArguments = <String, AnnotationArgument>{};

    if (annotation
        case ElementAnnotationImpl(
          annotationAst: Annotation(
            arguments: ArgumentList(childEntities: final args)
          )
        )) {
      for (final param in args) {
        if (param case NamedExpression(:final name, :final expression)) {
          namedArguments[name.label.name] =
              AnnotationArgument.fromExpression(expression);
        } else if (param case final Expression expression) {
          positionalArguments
              .add(AnnotationArgument.fromExpression(expression));
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
    return {
      ...named,
      for (final e in positional) e.parameterName: e,
    };
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
