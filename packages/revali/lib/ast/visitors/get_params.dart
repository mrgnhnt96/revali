import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';

Iterable<MetaParam> getParams(FunctionTypedElement element) {
  final params = <MetaParam>[];

  for (final param in element.parameters) {
    params.add(
      MetaParam(
        name: param.name,
        type: MetaType.fromType(param.type),
        literalValue: null,
        isRequired: param.isRequired,
        isNamed: param.isNamed,
        defaultValue: param.defaultValueCode,
        annotationsFor: ({
          required List<OnMatch> onMatch,
          NonMatch? onNonMatch,
        }) =>
            getAnnotations(
          element: param,
          onMatch: onMatch,
          onNonMatch: onNonMatch,
        ),
      ),
    );
  }

  return params;
}
